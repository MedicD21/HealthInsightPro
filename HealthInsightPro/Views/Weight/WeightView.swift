import SwiftUI

struct WeightView: View {
    @StateObject private var vm = WeightViewModel()
    @EnvironmentObject var authService: AuthService

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Current weight hero
                        WeightHeroCard(vm: vm)
                        // Progress to goal
                        if let progress = vm.progressToGoal, let target = vm.targetWeight {
                            WeightGoalCard(vm: vm, progress: progress, target: target)
                        }
                        // Chart
                        WeightChartCard(vm: vm)
                        // Log
                        WeightLogCard(vm: vm)
                    }
                    .padding(.horizontal, Constants.Layout.padding)
                    .padding(.bottom, 100)
                }
                .refreshable { await vm.load(userId: authService.currentUser!.id) }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingAddButton(gradient: AppTheme.gradientPrimary) {
                            vm.showLogWeight = true
                        }
                        .padding(.trailing, 24).padding(.bottom, 90)
                    }
                }
            }
            .navigationTitle("Weight")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $vm.showLogWeight) {
                LogWeightSheet(vm: vm)
            }
        }
        .task {
            if let uid = authService.currentUser?.id {
                await vm.load(userId: uid)
            }
        }
    }
}

// MARK: - Hero
struct WeightHeroCard: View {
    @ObservedObject var vm: WeightViewModel

    var body: some View {
        HStack(spacing: 24) {
            // Current
            VStack(spacing: 6) {
                Text("Current")
                    .font(AppFont.caption(.semibold)).foregroundColor(AppTheme.textSecondary)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(vm.latestWeight.map { String(format: "%.1f", $0) } ?? "--")
                        .font(AppFont.bigNumber()).foregroundColor(AppTheme.textPrimary)
                    Text("kg")
                        .font(AppFont.callout()).foregroundColor(AppTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)

            Divider().background(AppTheme.borderSubtle).frame(height: 60)

            // Change
            VStack(spacing: 6) {
                Text("Change")
                    .font(AppFont.caption(.semibold)).foregroundColor(AppTheme.textSecondary)
                if let change = vm.weightChange {
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Image(systemName: change < 0 ? "arrow.down" : "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(change < 0 ? AppTheme.accentGreen : AppTheme.accentPink)
                        Text(String(format: "%.1f", abs(change)))
                            .font(AppFont.title1(.bold))
                            .foregroundColor(change < 0 ? AppTheme.accentGreen : AppTheme.accentPink)
                        Text("kg").font(AppFont.callout()).foregroundColor(AppTheme.textSecondary)
                    }
                } else {
                    Text("--").font(AppFont.title1(.bold)).foregroundColor(AppTheme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)

            Divider().background(AppTheme.borderSubtle).frame(height: 60)

            // Target
            VStack(spacing: 6) {
                Text("Target")
                    .font(AppFont.caption(.semibold)).foregroundColor(AppTheme.textSecondary)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(vm.targetWeight.map { String(format: "%.1f", $0) } ?? "--")
                        .font(AppFont.title1(.bold)).foregroundColor(AppTheme.accent)
                    Text("kg").font(AppFont.callout()).foregroundColor(AppTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(Constants.Layout.padding)
        .cardStyle()
    }
}

// MARK: - Goal Card
struct WeightGoalCard: View {
    @ObservedObject var vm: WeightViewModel
    var progress: Double
    var target: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Goal Progress")
            LinearProgressBar(progress: progress, color: AppTheme.accentGreen, height: 12,
                              showLabel: true, label: "Progress to goal")
            HStack {
                if let start = vm.startWeight {
                    Text("Start: \(String(format: "%.1f kg", start))")
                        .font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                Text("Target: \(String(format: "%.1f kg", target))")
                    .font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(Constants.Layout.padding)
        .cardStyle()
    }
}

// MARK: - Chart Card
struct WeightChartCard: View {
    @ObservedObject var vm: WeightViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Weight History")
            if vm.chartData.isEmpty {
                Text("Log your weight to see trends")
                    .font(AppFont.subheadline()).foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity).padding()
            } else {
                // Mini chart
                let weights = vm.chartData.map { $0.1 }
                let minW = (weights.min() ?? 60) - 1
                let maxW = (weights.max() ?? 80) + 1
                let range = maxW - minW

                GeometryReader { geo in
                    ZStack(alignment: .bottomLeading) {
                        // Grid lines
                        VStack(spacing: 0) {
                            ForEach(0..<4) { _ in
                                Divider().background(AppTheme.borderSubtle.opacity(0.5))
                                Spacer()
                            }
                        }

                        // Weight line
                        Path { path in
                            guard !weights.isEmpty else { return }
                            let w = geo.size.width / CGFloat(max(1, weights.count - 1))
                            for (i, weight) in weights.enumerated() {
                                let x = CGFloat(i) * w
                                let y = geo.size.height * (1 - CGFloat((weight - minW) / range))
                                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                else { path.addLine(to: CGPoint(x: x, y: y)) }
                            }
                        }
                        .stroke(AppTheme.gradientPrimary, lineWidth: 2.5)

                        // Points
                        ForEach(Array(weights.enumerated()), id: \.offset) { i, weight in
                            let x = CGFloat(i) * geo.size.width / CGFloat(max(1, weights.count - 1))
                            let y = geo.size.height * (1 - CGFloat((weight - minW) / range))
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 6, height: 6)
                                .position(x: x, y: y)
                        }
                    }
                }
                .frame(height: 120)
                .padding(.horizontal, 4)
            }
        }
        .padding(Constants.Layout.padding)
        .cardStyle()
    }
}

// MARK: - Log Section
struct WeightLogCard: View {
    @ObservedObject var vm: WeightViewModel

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Log History")
            if vm.weightEntries.isEmpty {
                Text("No weight entries yet")
                    .font(AppFont.subheadline()).foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity).padding()
                    .cardStyle()
            } else {
                VStack(spacing: 0) {
                    ForEach(vm.weightEntries.prefix(10)) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.loggedAt.shortDate)
                                    .font(AppFont.subheadline(.semibold)).foregroundColor(AppTheme.textPrimary)
                                if let bf = entry.bodyFatPercent {
                                    Text("Body fat: \(String(format: "%.1f%%", bf))")
                                        .font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
                                }
                            }
                            Spacer()
                            Text(String(format: "%.1f kg", entry.weightKg))
                                .font(AppFont.headline(.bold)).foregroundColor(AppTheme.textPrimary)
                        }
                        .padding(.horizontal, Constants.Layout.padding)
                        .padding(.vertical, 10)
                        Divider().background(AppTheme.borderSubtle)
                    }
                }
                .cardStyle()
            }
        }
    }
}

// MARK: - Log Sheet
struct LogWeightSheet: View {
    @ObservedObject var vm: WeightViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        // Weight input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weight (kg)").font(AppFont.subheadline(.semibold)).foregroundColor(AppTheme.textSecondary)
                            TextField("e.g. 70.5", text: $vm.newWeightInput)
                                .keyboardType(.decimalPad)
                                .font(AppFont.title2(.bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(14)
                                .background(AppTheme.cardBackground)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.accent, lineWidth: 1))
                        }

                        // Body fat input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Body Fat % (optional)").font(AppFont.subheadline(.semibold)).foregroundColor(AppTheme.textSecondary)
                            TextField("e.g. 18.5", text: $vm.newBodyFat)
                                .keyboardType(.decimalPad)
                                .font(AppFont.title2())
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(14)
                                .background(AppTheme.cardBackground)
                                .cornerRadius(12)
                        }

                        if let err = vm.errorMessage {
                            Text(err).font(AppFont.caption()).foregroundColor(AppTheme.error)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    Button {
                        Task { await vm.logWeight() }
                    } label: {
                        Text("Save Weight").font(AppFont.headline()).foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(AppTheme.gradientPrimary).cornerRadius(16)
                    }
                    .padding(.horizontal).padding(.bottom, 30)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(AppTheme.accent)
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }
}
