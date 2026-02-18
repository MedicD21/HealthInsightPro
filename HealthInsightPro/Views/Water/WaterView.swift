import SwiftUI

struct WaterView: View {
    @StateObject private var vm = WaterViewModel()
    @EnvironmentObject var authService: AuthService

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Hero
                        WaterHeroCard(vm: vm)
                        // Quick add buttons
                        WaterQuickAddSection(vm: vm)
                        // Today's log
                        WaterLogSection(vm: vm)
                    }
                    .padding(.horizontal, Constants.Layout.padding)
                    .padding(.bottom, 100)
                }
                .refreshable { await vm.fetchToday() }
            }
            .navigationTitle("Hydration")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task {
            if let uid = authService.currentUser?.id {
                await vm.load(userId: uid)
            }
        }
    }
}

// MARK: - Hero Card
struct WaterHeroCard: View {
    @ObservedObject var vm: WaterViewModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.borderSubtle, lineWidth: 1))

            VStack(spacing: 16) {
                // Big ring
                ZStack {
                    RingProgressView(
                        progress: vm.progress,
                        lineWidth: 18, size: 160,
                        gradient: AppTheme.gradientBlue,
                        backgroundColor: Color.white.opacity(0.06)
                    )
                    VStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(AppTheme.gradientBlue)
                        Text("\(Int(ImperialUnits.mlToFluidOunces(vm.totalMl)))")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("of \(Int(ImperialUnits.mlToFluidOunces(vm.goal))) fl oz")
                            .font(AppFont.caption())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text("\(vm.progressPercent)%")
                            .font(AppFont.title3(.bold))
                            .foregroundColor(AppTheme.accentBlue)
                        Text("Complete")
                            .font(AppFont.caption())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    VStack(spacing: 4) {
                        Text("\(Int(ImperialUnits.mlToFluidOunces(vm.remainingMl))) fl oz")
                            .font(AppFont.title3(.bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Remaining")
                            .font(AppFont.caption())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    VStack(spacing: 4) {
                        Text("\(vm.waterEntries.count)")
                            .font(AppFont.title3(.bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Logged")
                            .font(AppFont.caption())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Quick Add
struct WaterQuickAddSection: View {
    @ObservedObject var vm: WaterViewModel

    let containers: [WaterContainerType] = [.glass, .bottle, .largeBottle, .xlBottle]

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Quick Add")
            HStack(spacing: 10) {
                ForEach(containers, id: \.self) { container in
                    Button {
                        Task { await vm.addWater(container.ml, container: container) }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 22))
                                .foregroundColor(AppTheme.accentBlue)
                            Text(container.displayName)
                                .font(AppFont.caption(.semibold))
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                            Text("\(Int(ImperialUnits.mlToFluidOunces(container.ml))) fl oz")
                                .font(AppFont.caption())
                                .foregroundColor(AppTheme.accentBlue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.accentBlue.opacity(0.1))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.accentBlue.opacity(0.2), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Log Section
struct WaterLogSection: View {
    @ObservedObject var vm: WaterViewModel

    var body: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Today's Log")
            if vm.waterEntries.isEmpty {
                Text("No water logged yet. Stay hydrated!")
                    .font(AppFont.subheadline())
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .cardStyle()
            } else {
                VStack(spacing: 0) {
                    ForEach(vm.waterEntries.reversed()) { entry in
                        WaterEntryRow(entry: entry) {
                            Task { await vm.deleteEntry(entry) }
                        }
                        Divider().background(AppTheme.borderSubtle)
                    }
                }
                .cardStyle()
            }
        }
    }
}

struct WaterEntryRow: View {
    var entry: WaterEntry
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(AppTheme.accentBlue.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: "drop.fill").font(.system(size: 18)).foregroundColor(AppTheme.accentBlue)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.containerType?.displayName ?? "Water")
                    .font(AppFont.subheadline(.semibold)).foregroundColor(AppTheme.textPrimary)
                Text(entry.loggedAt.timeString)
                    .font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            Text("\(Int(ImperialUnits.mlToFluidOunces(entry.amountMl))) fl oz")
                .font(AppFont.subheadline(.bold)).foregroundColor(AppTheme.accentBlue)
            Button(action: onDelete) {
                Image(systemName: "trash").font(.caption).foregroundColor(AppTheme.textTertiary)
            }
            .padding(.leading, 8)
        }
        .padding(.horizontal, Constants.Layout.padding)
        .padding(.vertical, 10)
    }
}
