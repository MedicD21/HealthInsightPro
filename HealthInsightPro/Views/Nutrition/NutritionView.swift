import SwiftUI

struct NutritionView: View {
    @StateObject private var vm = NutritionViewModel()
    @EnvironmentObject var authService: AuthService
    @State private var showFoodSearch = false
    @State private var showBarcodeScanner = false
    @State private var showRecipes = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Date picker header
                        NutritionDateHeader(selectedDate: $vm.selectedDate) {
                            Task { await vm.changeDate(to: vm.selectedDate) }
                        }

                        // Calorie overview
                        NutritionCalorieCard(vm: vm)

                        // Macros detail
                        NutritionMacrosCard(vm: vm)

                        // Log buttons
                        NutritionLogButtons(
                            onSearch: { showFoodSearch = true },
                            onBarcode: { showBarcodeScanner = true },
                            onRecipes: { showRecipes = true }
                        )

                        // Meals by type
                        ForEach(vm.mealsByType, id: \.0) { mealType, meals in
                            MealTypeSection(mealType: mealType, meals: meals, vm: vm)
                        }

                        // Empty state
                        if vm.mealEntries.isEmpty {
                            EmptyStateView(
                                icon: "fork.knife",
                                title: "No meals logged yet",
                                message: "Start tracking your nutrition by logging your first meal.",
                                buttonTitle: "Log a Meal",
                                action: { showFoodSearch = true }
                            )
                            .padding(.top, 40)
                        }
                    }
                    .padding(.horizontal, Constants.Layout.padding)
                    .padding(.bottom, 100)
                }
                .refreshable { await vm.fetchMeals() }
            }
            .navigationTitle("Nutrition")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showFoodSearch) {
                FoodSearchView(vm: vm, selectedMealType: vm.selectedMealType)
            }
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScannerView(vm: vm, selectedMealType: vm.selectedMealType)
            }
        }
        .task {
            if let uid = authService.currentUser?.id {
                await vm.load(userId: uid)
            }
        }
    }
}

// MARK: - Date Header
struct NutritionDateHeader: View {
    @Binding var selectedDate: Date
    var onChange: () -> Void

    var body: some View {
        HStack {
            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                onChange()
            } label: {
                Image(systemName: "chevron.left").foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            Text(Calendar.current.isDateInToday(selectedDate) ? "Today" : selectedDate.shortDate)
                .font(AppFont.headline(.semibold))
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            Button {
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                if tomorrow <= Date() {
                    selectedDate = tomorrow
                    onChange()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(Calendar.current.isDateInToday(selectedDate) ? AppTheme.textTertiary : AppTheme.textSecondary)
            }
            .disabled(Calendar.current.isDateInToday(selectedDate))
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Calorie Card
struct NutritionCalorieCard: View {
    @ObservedObject var vm: NutritionViewModel

    var summary: NutritionDaySummary? { vm.daySummary }

    var body: some View {
        HStack(spacing: 20) {
            // Calorie ring
            ZStack {
                RingProgressView(
                    progress: summary?.calorieProgress ?? 0,
                    lineWidth: 12, size: 100,
                    gradient: AppTheme.gradientOrange,
                    backgroundColor: Color.white.opacity(0.06)
                )
                VStack(spacing: 0) {
                    Text("\(Int(summary?.totalMacros.calories ?? 0))")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("kcal")
                        .font(AppFont.caption())
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Goal")
                        .font(AppFont.caption())
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text("\(Int(summary?.calorieGoal ?? 0)) kcal")
                        .font(AppFont.subheadline(.semibold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                HStack {
                    Text("Consumed")
                        .font(AppFont.caption())
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text("\(Int(summary?.totalMacros.calories ?? 0)) kcal")
                        .font(AppFont.subheadline(.semibold))
                        .foregroundColor(AppTheme.accentOrange)
                }
                HStack {
                    Text("Remaining")
                        .font(AppFont.caption())
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text("\(Int(max(0, summary?.caloriesRemaining ?? 0))) kcal")
                        .font(AppFont.subheadline(.semibold))
                        .foregroundColor(AppTheme.accentGreen)
                }
            }
        }
        .padding(Constants.Layout.padding)
        .cardStyle()
    }
}

// MARK: - Macros Card
struct NutritionMacrosCard: View {
    @ObservedObject var vm: NutritionViewModel

    var macros: Macros { vm.totalMacros }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Macros").font(AppFont.headline(.bold)).foregroundColor(AppTheme.textPrimary)
                Spacer()
                PillTag(text: "Per day", color: AppTheme.accent)
            }
            Divider().background(AppTheme.borderSubtle)

            HStack(spacing: 0) {
                MacroDonut(value: macros.protein, color: AppTheme.accentBlue,   label: "Protein")
                MacroDonut(value: macros.carbs,   color: AppTheme.accentOrange, label: "Carbs")
                MacroDonut(value: macros.fat,     color: AppTheme.accentYellow, label: "Fat")
            }

            Divider().background(AppTheme.borderSubtle)

            // Detailed bars
            if let summary = vm.daySummary {
                VStack(spacing: 8) {
                    MacroRow(label: "Protein", consumed: macros.protein, goal: summary.proteinGoal, color: AppTheme.accentBlue)
                    MacroRow(label: "Carbs",   consumed: macros.carbs,   goal: summary.carbGoal,    color: AppTheme.accentOrange)
                    MacroRow(label: "Fat",     consumed: macros.fat,     goal: summary.fatGoal,     color: AppTheme.accentYellow)
                    MacroRow(label: "Fiber",   consumed: macros.fiber,   goal: 30, color: AppTheme.accentGreen)
                }
            }

            // Micros row
            HStack {
                MicroStat(label: "Sodium",  value: "\(Int(macros.sodium))mg")
                Divider().frame(height: 30)
                MicroStat(label: "Sugar",   value: "\(Int(macros.sugar))g")
                Divider().frame(height: 30)
                MicroStat(label: "Cholest.", value: "\(Int(macros.cholesterol))mg")
                Divider().frame(height: 30)
                MicroStat(label: "Potassium", value: "\(Int(macros.potassium))mg")
            }
            .padding(.top, 4)
        }
        .padding(Constants.Layout.padding)
        .cardStyle()
    }
}

struct MacroDonut: View {
    var value: Double
    var color: Color
    var label: String

    var body: some View {
        VStack(spacing: 6) {
            Text("\(Int(value))g")
                .font(AppFont.headline(.bold))
                .foregroundColor(color)
            Text(label)
                .font(AppFont.caption())
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MicroStat: View {
    var label: String; var value: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(AppFont.subheadline(.semibold)).foregroundColor(AppTheme.textPrimary)
            Text(label).font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Log Buttons
struct NutritionLogButtons: View {
    var onSearch: () -> Void
    var onBarcode: () -> Void
    var onRecipes: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            LogButton(title: "Search", icon: "magnifyingglass", color: AppTheme.accentGreen, action: onSearch)
            LogButton(title: "Barcode", icon: "barcode.viewfinder", color: AppTheme.accentBlue, action: onBarcode)
            LogButton(title: "Recipes", icon: "book.fill", color: AppTheme.accentPurple, action: onRecipes)
        }
    }
}

struct LogButton: View {
    var title: String; var icon: String; var color: Color; var action: () -> Void
    var body: some View {
        Button(action: { HapticFeedback.light(); action() }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(AppFont.caption(.semibold))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity).frame(height: 64)
            .background(color.opacity(0.1))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Meal Type Section
struct MealTypeSection: View {
    var mealType: MealType
    var meals: [MealEntry]
    @ObservedObject var vm: NutritionViewModel

    var totalCalories: Double { meals.reduce(0) { $0 + $1.totalMacros.calories } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: mealType.icon)
                    .foregroundColor(AppTheme.accentGreen)
                Text(mealType.displayName)
                    .font(AppFont.headline(.bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("\(Int(totalCalories)) kcal")
                    .font(AppFont.subheadline(.semibold))
                    .foregroundColor(AppTheme.textSecondary)
            }

            VStack(spacing: 0) {
                ForEach(meals) { meal in
                    ForEach(meal.items) { item in
                        MealItemRow(item: item)
                        Divider().background(AppTheme.borderSubtle)
                    }
                }
            }
            .cardStyle()
        }
    }
}

struct MealItemRow: View {
    var item: MealEntryItem
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.foodItem.name)
                    .font(AppFont.subheadline(.semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text("\(item.servings.formatted1) serving · \(item.foodItem.brand ?? "")")
                    .font(AppFont.caption())
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(item.totalMacros.calories))")
                    .font(AppFont.subheadline(.bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text("kcal")
                    .font(AppFont.caption())
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, Constants.Layout.padding)
        .padding(.vertical, 10)
    }
}

// MARK: - Food Search View (powered by Open Food Facts)
struct FoodSearchView: View {
    @ObservedObject var vm: NutritionViewModel
    var selectedMealType: MealType
    @Environment(\.dismiss) var dismiss
    @State private var localQuery = ""
    @State private var selectedItem: FoodItem? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                VStack(spacing: 0) {

                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.textSecondary)
                        TextField("Search foods, brands, barcodes...", text: $localQuery)
                            .foregroundColor(AppTheme.textPrimary)
                            .tint(AppTheme.accentGreen)
                            .autocorrectionDisabled()
                            .onChange(of: localQuery) { vm.searchFood(query: $0) }
                        if vm.isSearching {
                            ProgressView().scaleEffect(0.75).tint(AppTheme.accentGreen)
                        } else if !localQuery.isEmpty {
                            Button { localQuery = ""; vm.searchFood(query: "") } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                        }
                    }
                    .padding(12)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.accentGreen.opacity(0.3), lineWidth: 1))
                    .padding(.horizontal).padding(.top, 12).padding(.bottom, 8)

                    // Source credit
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.caption2)
                            .foregroundColor(AppTheme.textTertiary)
                        Text("Powered by Open Food Facts · \(vm.searchResults.count) results")
                            .font(AppFont.caption())
                            .foregroundColor(AppTheme.textTertiary)
                        Spacer()
                    }
                    .padding(.horizontal).padding(.bottom, 6)

                    // States
                    if localQuery.isEmpty {
                        FoodSearchPlaceholder()
                    } else if !vm.isSearching && vm.searchResults.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No results for \"\(localQuery)\"",
                            message: "Try a different spelling or use the barcode scanner for packaged products."
                        )
                        .padding(.top, 40)
                    } else {
                        List(vm.searchResults) { item in
                            FoodItemRow(item: item) {
                                selectedItem = item
                                HapticFeedback.light()
                            }
                            .listRowBackground(AppTheme.cardBackground)
                            .listRowSeparatorTint(AppTheme.borderSubtle)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(AppTheme.accent)
                }
            }
            .sheet(item: $selectedItem) { item in
                AddServingSheet(item: item, mealType: selectedMealType, vm: vm) {
                    dismiss()
                }
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.dark)
    }
}

// MARK: - Search Placeholder
struct FoodSearchPlaceholder: View {
    let suggestions = ["Chicken breast", "Greek yogurt", "Brown rice", "Almonds", "Banana", "Oats"]

    var body: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 20)
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.accentGreen.opacity(0.4))
            Text("Search millions of foods")
                .font(AppFont.headline(.semibold))
                .foregroundColor(AppTheme.textSecondary)
            Text("Powered by Open Food Facts database")
                .font(AppFont.caption())
                .foregroundColor(AppTheme.textTertiary)

            // Quick suggestions
            VStack(alignment: .leading, spacing: 8) {
                Text("Try searching for:")
                    .font(AppFont.caption(.semibold))
                    .foregroundColor(AppTheme.textTertiary)
                    .padding(.horizontal)
                FlowLayout(items: suggestions) { suggestion in
                    PillTag(text: suggestion, color: AppTheme.accentGreen)
                }
                .padding(.horizontal)
            }
            Spacer()
        }
    }
}

// Simple horizontal-wrapping layout for tag pills
struct FlowLayout<T: Hashable, V: View>: View {
    let items: [T]
    let content: (T) -> V

    var body: some View {
        var width: CGFloat = 0
        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(items, id: \.self) { item in
                    content(item)
                        .alignmentGuide(.leading) { d in
                            if width + d.width > geo.size.width { width = 0 }
                            let result = width
                            width += d.width + 8
                            return -result
                        }
                        .alignmentGuide(.top) { _ in 0 }
                }
            }
        }
        .frame(height: 60)
    }
}

// MARK: - Food Item Row
struct FoodItemRow: View {
    var item: FoodItem
    var onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Source indicator dot
            Circle()
                .fill(item.isCustom ? AppTheme.accentPurple : AppTheme.accentGreen)
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(AppFont.subheadline(.semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    if let brand = item.brand {
                        Text(brand)
                            .font(AppFont.caption())
                            .foregroundColor(AppTheme.textSecondary)
                        Text("·").foregroundColor(AppTheme.textTertiary)
                    }
                    Text(item.servingDescription ?? "\(Int(item.servingSize))\(item.servingUnit)")
                        .font(AppFont.caption())
                        .foregroundColor(AppTheme.textTertiary)
                }
                // Macro pills
                HStack(spacing: 6) {
                    MacroPill(value: item.macrosPerServing.calories, unit: "kcal", color: AppTheme.accentOrange)
                    MacroPill(value: item.macrosPerServing.protein,  unit: "P",    color: AppTheme.accentBlue)
                    MacroPill(value: item.macrosPerServing.carbs,    unit: "C",    color: AppTheme.accentGreen)
                    MacroPill(value: item.macrosPerServing.fat,      unit: "F",    color: AppTheme.accentYellow)
                }
            }
            Spacer()
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(AppTheme.accentGreen)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .padding(.vertical, 6)
    }
}

struct MacroPill: View {
    var value: Double; var unit: String; var color: Color

    var body: some View {
        Text("\(Int(value))\(unit)")
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(color.opacity(0.12))
            .cornerRadius(4)
    }
}

// MARK: - Add Serving Sheet (serving size picker before adding)
struct AddServingSheet: View {
    var item: FoodItem
    var mealType: MealType
    @ObservedObject var vm: NutritionViewModel
    var onDone: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var servings: Double = 1.0
    @State private var selectedMealType: MealType

    init(item: FoodItem, mealType: MealType, vm: NutritionViewModel, onDone: @escaping () -> Void) {
        self.item = item
        self.mealType = mealType
        self.vm = vm
        self.onDone = onDone
        _selectedMealType = State(initialValue: mealType)
    }

    var scaledMacros: Macros { item.macrosPerServing.scaled(by: servings) }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {

                        // Food name header
                        VStack(spacing: 4) {
                            Text(item.name)
                                .font(AppFont.title3(.bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .multilineTextAlignment(.center)
                            if let brand = item.brand {
                                Text(brand)
                                    .font(AppFont.subheadline())
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            if let barcode = item.barcode {
                                HStack(spacing: 4) {
                                    Image(systemName: "barcode")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textTertiary)
                                    Text(barcode)
                                        .font(AppFont.caption())
                                        .foregroundColor(AppTheme.textTertiary)
                                }
                            }
                        }
                        .padding(.top, 8)

                        // Big calorie ring with live update
                        ZStack {
                            RingProgressView(
                                progress: (scaledMacros.calories / max(1, vm.daySummary?.calorieGoal ?? 2000)),
                                lineWidth: 14, size: 130,
                                gradient: AppTheme.gradientOrange,
                                backgroundColor: Color.white.opacity(0.06)
                            )
                            VStack(spacing: 2) {
                                Text("\(Int(scaledMacros.calories))")
                                    .font(.system(size: 30, weight: .black, design: .rounded))
                                    .foregroundColor(AppTheme.textPrimary)
                                Text("kcal")
                                    .font(AppFont.caption())
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }

                        // Macro breakdown
                        HStack(spacing: 0) {
                            MacroColumn(label: "Protein", value: scaledMacros.protein, unit: "g", color: AppTheme.accentBlue)
                            Divider().background(AppTheme.borderSubtle).frame(height: 44)
                            MacroColumn(label: "Carbs",   value: scaledMacros.carbs,   unit: "g", color: AppTheme.accentOrange)
                            Divider().background(AppTheme.borderSubtle).frame(height: 44)
                            MacroColumn(label: "Fat",     value: scaledMacros.fat,     unit: "g", color: AppTheme.accentYellow)
                            Divider().background(AppTheme.borderSubtle).frame(height: 44)
                            MacroColumn(label: "Fiber",   value: scaledMacros.fiber,   unit: "g", color: AppTheme.accentGreen)
                        }
                        .padding(.vertical, 12)
                        .cardStyle()

                        // Serving size slider
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Serving Size")
                                    .font(AppFont.subheadline(.semibold))
                                    .foregroundColor(AppTheme.textSecondary)
                                Spacer()
                                Text(String(format: "%.1f × %@",
                                     servings,
                                     item.servingDescription ?? "\(Int(item.servingSize))\(item.servingUnit)"))
                                    .font(AppFont.subheadline(.bold))
                                    .foregroundColor(AppTheme.accentGreen)
                            }
                            Slider(value: $servings, in: 0.25...10, step: 0.25)
                                .tint(AppTheme.accentGreen)
                            HStack {
                                ForEach([0.5, 1.0, 1.5, 2.0, 3.0], id: \.self) { preset in
                                    Button("\(preset.formatted1)×") {
                                        withAnimation { servings = preset }
                                        HapticFeedback.selection()
                                    }
                                    .font(AppFont.caption(.semibold))
                                    .foregroundColor(servings == preset ? .white : AppTheme.textSecondary)
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(servings == preset ? AppTheme.accentGreen : AppTheme.cardBackgroundAlt)
                                    .cornerRadius(8)
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding(Constants.Layout.padding)
                        .cardStyle()

                        // Meal type picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Add to Meal")
                                .font(AppFont.subheadline(.semibold))
                                .foregroundColor(AppTheme.textSecondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(MealType.allCases, id: \.self) { mt in
                                        Button {
                                            selectedMealType = mt
                                            HapticFeedback.selection()
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: mt.icon)
                                                    .font(.caption)
                                                Text(mt.displayName)
                                                    .font(AppFont.caption(.semibold))
                                            }
                                            .foregroundColor(selectedMealType == mt ? .white : AppTheme.textSecondary)
                                            .padding(.horizontal, 12).padding(.vertical, 8)
                                            .background(selectedMealType == mt ? AppTheme.accentGreen : AppTheme.cardBackgroundAlt)
                                            .cornerRadius(10)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(Constants.Layout.padding)
                        .cardStyle()

                        // Additional micros
                        VStack(spacing: 8) {
                            HStack {
                                Text("Nutrition Details").font(AppFont.subheadline(.semibold)).foregroundColor(AppTheme.textSecondary)
                                Spacer()
                                Text("per \(servings.formatted1) serving").font(AppFont.caption()).foregroundColor(AppTheme.textTertiary)
                            }
                            Divider().background(AppTheme.borderSubtle)
                            NutritionDetailRow(label: "Sodium",      value: "\(Int(scaledMacros.sodium)) mg")
                            NutritionDetailRow(label: "Sugar",       value: "\(Int(scaledMacros.sugar)) g")
                            NutritionDetailRow(label: "Saturated Fat", value: "\(scaledMacros.saturatedFat.formatted1) g")
                            NutritionDetailRow(label: "Cholesterol", value: "\(Int(scaledMacros.cholesterol)) mg")
                            NutritionDetailRow(label: "Potassium",   value: "\(Int(scaledMacros.potassium)) mg")
                        }
                        .padding(Constants.Layout.padding)
                        .cardStyle()

                        // Add button
                        Button {
                            Task {
                                let entryItem = MealEntryItem(id: UUID(), foodItem: item, servings: servings)
                                let entry = MealEntry(
                                    id: UUID(),
                                    userId: AuthService.shared.currentUser?.id ?? UUID(),
                                    mealType: selectedMealType,
                                    items: [entryItem],
                                    loggedAt: Date()
                                )
                                await vm.addMealEntry(entry)
                                HapticFeedback.success()
                                dismiss()
                                onDone()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add to \(selectedMealType.displayName)")
                            }
                            .font(AppFont.headline())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(AppTheme.gradientGreen)
                            .cornerRadius(16)
                            .shadow(color: AppTheme.accentGreen.opacity(0.4), radius: 12, y: 4)
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, Constants.Layout.padding)
                }
            }
            .navigationTitle("Add to Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(AppTheme.accent)
                }
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.dark)
    }
}

struct MacroColumn: View {
    var label: String; var value: Double; var unit: String; var color: Color
    var body: some View {
        VStack(spacing: 3) {
            Text(value.formatted1).font(AppFont.headline(.bold)).foregroundColor(color)
            Text("\(unit) \(label)").font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct NutritionDetailRow: View {
    var label: String; var value: String
    var body: some View {
        HStack {
            Text(label).font(AppFont.subheadline()).foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(value).font(AppFont.subheadline(.semibold)).foregroundColor(AppTheme.textPrimary)
        }
    }
}

// MARK: - Barcode Scanner View (AVFoundation + OFF lookup)
struct BarcodeScannerView: View {
    @ObservedObject var vm: NutritionViewModel
    var selectedMealType: MealType
    @Environment(\.dismiss) var dismiss

    @State private var scannedBarcode: String? = nil
    @State private var showManualEntry = false
    @State private var manualBarcode = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                // Camera placeholder (AVFoundation camera view would be added here via UIViewRepresentable)
                VStack(spacing: 0) {
                    // Viewfinder area
                    ZStack {
                        Color.black
                        // Scan frame
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.accentGreen, lineWidth: 2.5)
                            .frame(width: 260, height: 160)
                        // Corners
                        ScannerCorners()
                            .frame(width: 260, height: 160)
                        // Scanning animation line
                        ScanLineAnimation()
                            .frame(width: 240, height: 140)

                        if vm.isBarcodeLoading {
                            VStack(spacing: 12) {
                                ProgressView().tint(AppTheme.accentGreen).scaleEffect(1.5)
                                Text("Looking up product...")
                                    .font(AppFont.subheadline())
                                    .foregroundColor(.white)
                            }
                            .frame(width: 260, height: 160)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(16)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)

                    // Instructions
                    VStack(spacing: 8) {
                        Text("Point camera at barcode")
                            .font(AppFont.headline(.semibold))
                            .foregroundColor(.white)
                        Text("Supports EAN-13, UPC-A, QR codes and more.\nLookup powered by Open Food Facts.")
                            .font(AppFont.caption())
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)

                    // Error
                    if let err = vm.barcodeError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(AppTheme.error)
                            Text(err)
                                .font(AppFont.subheadline())
                                .foregroundColor(AppTheme.error)
                        }
                        .padding()
                        .background(AppTheme.error.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.top, 12)
                    }

                    Spacer()

                    // Actions
                    VStack(spacing: 12) {
                        // Manual barcode entry
                        Button {
                            showManualEntry = true
                        } label: {
                            HStack {
                                Image(systemName: "keyboard")
                                Text("Enter Barcode Manually")
                            }
                            .font(AppFont.subheadline(.semibold))
                            .foregroundColor(AppTheme.accentGreen)
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(AppTheme.accentGreen.opacity(0.1))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.accentGreen.opacity(0.3), lineWidth: 1))
                        }

                        // For testing — remove in production
                        #if DEBUG
                        Menu {
                            Button("Nutella (3017620422003)") { performLookup("3017620422003") }
                            Button("Coca-Cola (5449000000996)") { performLookup("5449000000996") }
                            Button("Pringles (038000845260)") { performLookup("038000845260") }
                            Button("Oreo (7622210713780)") { performLookup("7622210713780") }
                        } label: {
                            HStack {
                                Image(systemName: "qrcode")
                                Text("Test with Sample Barcode")
                            }
                            .font(AppFont.subheadline(.semibold))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(14)
                        }
                        #endif
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        vm.clearBarcodeState()
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accent)
                }
            }
            // Show result sheet when product found
            .sheet(item: $vm.barcodeResult) { item in
                AddServingSheet(item: item, mealType: selectedMealType, vm: vm) {
                    vm.clearBarcodeState()
                    dismiss()
                }
            }
            // Manual barcode entry alert
            .alert("Enter Barcode", isPresented: $showManualEntry) {
                TextField("e.g. 3017620422003", text: $manualBarcode)
                    .keyboardType(.numberPad)
                Button("Look Up") {
                    guard !manualBarcode.isEmpty else { return }
                    performLookup(manualBarcode)
                    manualBarcode = ""
                }
                Button("Cancel", role: .cancel) { manualBarcode = "" }
            } message: {
                Text("Enter the numeric barcode printed on the product packaging.")
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear { vm.clearBarcodeState() }
    }

    private func performLookup(_ barcode: String) {
        Task { _ = await vm.lookupBarcode(barcode) }
    }
}

// MARK: - Scanner UI Components
struct ScannerCorners: View {
    var body: some View {
        ZStack {
            // TL
            Path { p in p.move(to: .init(x: 0, y: 20)); p.addLine(to: .zero); p.addLine(to: .init(x: 20, y: 0)) }
                .stroke(AppTheme.accentGreen, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            // TR
            Path { p in p.move(to: .init(x: 240, y: 0)); p.addLine(to: .init(x: 260, y: 0)); p.addLine(to: .init(x: 260, y: 20)) }
                .stroke(AppTheme.accentGreen, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            // BL
            Path { p in p.move(to: .init(x: 0, y: 140)); p.addLine(to: .init(x: 0, y: 160)); p.addLine(to: .init(x: 20, y: 160)) }
                .stroke(AppTheme.accentGreen, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            // BR
            Path { p in p.move(to: .init(x: 240, y: 160)); p.addLine(to: .init(x: 260, y: 160)); p.addLine(to: .init(x: 260, y: 140)) }
                .stroke(AppTheme.accentGreen, style: StrokeStyle(lineWidth: 4, lineCap: .round))
        }
    }
}

struct ScanLineAnimation: View {
    @State private var offset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(colors: [.clear, AppTheme.accentGreen.opacity(0.6), .clear],
                               startPoint: .leading, endPoint: .trailing)
            )
            .frame(height: 2)
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    offset = 130
                }
            }
    }
}
