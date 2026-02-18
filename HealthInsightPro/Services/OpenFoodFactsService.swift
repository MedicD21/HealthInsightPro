import Foundation

// MARK: - Open Food Facts API Service
// Docs: https://world.openfoodfacts.org/data
// Free, no auth required. Millions of products via barcode & text search.

final class OpenFoodFactsService {
    static let shared = OpenFoodFactsService()
    private init() {}

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        // OFF requires a descriptive User-Agent
        config.httpAdditionalHeaders = [
            "User-Agent": "HealthInsightPro/1.0 (iOS; contact@healthinsightpro.app)"
        ]
        return URLSession(configuration: config)
    }()

    private let baseURL = "https://world.openfoodfacts.org"
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .useDefaultKeys
        return d
    }()

    // MARK: - Text Search
    /// Search by product name. Returns mapped FoodItem array.
    func searchProducts(query: String, page: Int = 1, pageSize: Int = 25) async -> [FoodItem] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        var comps = URLComponents(string: "\(baseURL)/cgi/search.pl")!
        comps.queryItems = [
            .init(name: "search_terms",   value: query),
            .init(name: "search_simple",  value: "1"),
            .init(name: "action",         value: "process"),
            .init(name: "json",           value: "1"),
            .init(name: "page",           value: "\(page)"),
            .init(name: "page_size",      value: "\(pageSize)"),
            // Only fetch the fields we need (faster response)
            .init(name: "fields", value: "code,product_name,brands,serving_size,nutriments,image_front_thumb_url,quantity")
        ]
        guard let url = comps.url else { return [] }
        do {
            let (data, _) = try await session.data(from: url)
            let response = try decoder.decode(OFFSearchResponse.self, from: data)
            return response.products.compactMap { mapProduct($0) }
        } catch {
            print("[OFF] Search error: \(error)")
            return []
        }
    }

    // MARK: - Barcode Lookup
    /// Look up a single product by barcode (EAN-13, UPC-A, etc.)
    func lookupBarcode(_ barcode: String) async -> FoodItem? {
        let url = URL(string: "\(baseURL)/api/v2/product/\(barcode)?fields=code,product_name,brands,serving_size,nutriments,image_front_thumb_url,quantity")!
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let result = try decoder.decode(OFFProductResponse.self, from: data)
            guard result.status == 1, let product = result.product else { return nil }
            return mapProduct(product)
        } catch {
            print("[OFF] Barcode lookup error: \(error)")
            return nil
        }
    }

    // MARK: - Mapping OFF → FoodItem
    private func mapProduct(_ p: OFFProduct) -> FoodItem? {
        guard let name = p.product_name, !name.isEmpty else { return nil }
        let n = p.nutriments ?? OFFNutriments()

        // OFF stores nutrients per 100g. Determine serving size from serving_size, then quantity.
        let servingText = p.serving_size ?? p.quantity
        let parsedServing = parseServingAmount(servingText)
        let servingAmount = parsedServing?.amount ?? 100.0
        let scale = servingAmount / 100.0

        // Build macros (nutriments are per 100g in OFF)
        let macros = Macros(
            calories:     (n.energyKcal100g ?? n.energyKcalServing.map { $0 / scale } ?? 0) * scale,
            protein:      (n.proteins100g ?? 0) * scale,
            carbs:        (n.carbohydrates100g ?? 0) * scale,
            fat:          (n.fat100g ?? 0) * scale,
            fiber:        (n.fiber100g ?? 0) * scale,
            sugar:        (n.sugars100g ?? 0) * scale,
            sodium:       (n.sodium100g ?? 0) * scale * 1000,  // convert g → mg
            cholesterol:  (n.cholesterol100g ?? 0) * scale * 1000,
            saturatedFat: (n.saturatedFat100g ?? 0) * scale,
            transFat:     (n.transFat100g ?? 0) * scale,
            potassium:    (n.potassium100g ?? 0) * scale * 1000
        )

        return FoodItem(
            id: UUID(),
            name: name,
            brand: p.brands?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces),
            barcode: p.code,
            servingSize: servingAmount,
            servingUnit: parsedServing?.unit ?? servingUnit(from: servingText),
            servingDescription: servingText ?? "\(Int(servingAmount))g",
            macrosPerServing: macros,
            isCustom: false,
            userId: nil
        )
    }

    /// Extracts serving amount from OFF string like "30 g", "1 cup (240ml)", "2 oz"
    /// Returns serving amount in `g` or `ml` and normalized unit label.
    private func parseServingAmount(_ servingSize: String?) -> (amount: Double, unit: String)? {
        guard let servingSize else { return nil }

        let pattern = #"(\d+(?:[.,]\d+)?)\s*(kg|g|mg|ml|l|oz|fl\s*oz|lb|lbs|cup|tbsp|tsp)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: servingSize, range: NSRange(servingSize.startIndex..., in: servingSize)),
              let valueRange = Range(match.range(at: 1), in: servingSize),
              let unitRange = Range(match.range(at: 2), in: servingSize)
        else {
            return nil
        }

        let rawValue = servingSize[valueRange].replacingOccurrences(of: ",", with: ".")
        guard let value = Double(rawValue), value > 0 else { return nil }

        let unitToken = servingSize[unitRange].lowercased().replacingOccurrences(of: " ", with: "")
        switch unitToken {
        case "kg":
            return (value * 1000.0, "g")
        case "g":
            return (value, "g")
        case "mg":
            return (value / 1000.0, "g")
        case "ml":
            return (value, "ml")
        case "l":
            return (value * 1000.0, "ml")
        case "oz", "floz":
            return (value * 29.5735, "ml")
        case "lb", "lbs":
            return (value * 453.592, "g")
        case "cup":
            return (value * 240.0, "ml")
        case "tbsp":
            return (value * 15.0, "ml")
        case "tsp":
            return (value * 5.0, "ml")
        default:
            return nil
        }
    }

    private func servingUnit(from servingSize: String?) -> String {
        guard let s = servingSize?.lowercased() else { return "g" }
        if s.contains("ml") || s.contains("l") { return "ml" }
        if s.contains("oz") { return "oz" }
        if s.contains("cup") { return "cup" }
        return "g"
    }
}

// MARK: - OFF JSON Models
private struct OFFSearchResponse: Decodable {
    let count: Int?
    let products: [OFFProduct]

    enum CodingKeys: String, CodingKey {
        case count, products
    }
}

private struct OFFProductResponse: Decodable {
    let status: Int
    let product: OFFProduct?
}

private struct OFFProduct: Decodable {
    let code: String?
    let product_name: String?
    let brands: String?
    let serving_size: String?
    let quantity: String?
    let image_front_thumb_url: String?
    let nutriments: OFFNutriments?
}

private struct OFFNutriments: Decodable {
    // Per 100g values (most reliable in OFF)
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?
    let fiber100g: Double?
    let sugars100g: Double?
    let sodium100g: Double?
    let cholesterol100g: Double?
    let saturatedFat100g: Double?
    let transFat100g: Double?
    let potassium100g: Double?
    // Per-serving fallback
    let energyKcalServing: Double?

    init() {
        energyKcal100g = nil; proteins100g = nil; carbohydrates100g = nil
        fat100g = nil; fiber100g = nil; sugars100g = nil; sodium100g = nil
        cholesterol100g = nil; saturatedFat100g = nil; transFat100g = nil
        potassium100g = nil; energyKcalServing = nil
    }

    enum CodingKeys: String, CodingKey {
        case energyKcal100g      = "energy-kcal_100g"
        case proteins100g        = "proteins_100g"
        case carbohydrates100g   = "carbohydrates_100g"
        case fat100g             = "fat_100g"
        case fiber100g           = "fiber_100g"
        case sugars100g          = "sugars_100g"
        case sodium100g          = "sodium_100g"
        case cholesterol100g     = "cholesterol_100g"
        case saturatedFat100g    = "saturated-fat_100g"
        case transFat100g        = "trans-fat_100g"
        case potassium100g       = "potassium_100g"
        case energyKcalServing   = "energy-kcal_serving"
    }
}
