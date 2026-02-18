import SwiftUI

struct JournalView: View {
    @StateObject private var vm = JournalViewModel()
    @EnvironmentObject var authService: AuthService

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Mood selector
                        MoodSection(vm: vm)
                        // Energy & Stress sliders
                        EnergyStressSection(vm: vm)
                        // Habits
                        HabitsSection(vm: vm)
                        // Notes
                        NotesSection(vm: vm)
                        // Gratitude
                        GratitudeSection(vm: vm)
                        // Save button
                        Button {
                            Task { await vm.saveEntry() }
                        } label: {
                            HStack {
                                if vm.isSaving { ProgressView().tint(.white) }
                                else { Image(systemName: "checkmark.circle.fill") }
                                Text(vm.isSaving ? "Saving..." : "Save Journal Entry")
                            }
                            .font(AppFont.headline())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(AppTheme.gradientPrimary).cornerRadius(16)
                        }
                        .disabled(vm.isSaving)

                        // Recent entries
                        RecentJournalSection(vm: vm)
                    }
                    .padding(.horizontal, Constants.Layout.padding)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task {
            if let uid = authService.currentUser?.id { await vm.load(userId: uid) }
        }
    }
}

// MARK: - Mood
struct MoodSection: View {
    @ObservedObject var vm: JournalViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How are you feeling today?")
                .font(AppFont.headline(.bold)).foregroundColor(AppTheme.textPrimary)

            HStack(spacing: 8) {
                ForEach(MoodLevel.allCases, id: \.self) { mood in
                    Button {
                        HapticFeedback.selection()
                        vm.selectedMood = mood
                    } label: {
                        VStack(spacing: 4) {
                            Text(mood.emoji).font(.title2)
                            Text(mood.displayName)
                                .font(AppFont.caption())
                                .foregroundColor(vm.selectedMood == mood ? Color(hex: mood.color) : AppTheme.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(vm.selectedMood == mood ? Color(hex: mood.color).opacity(0.15) : AppTheme.cardBackground)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(vm.selectedMood == mood ? Color(hex: mood.color) : AppTheme.borderSubtle, lineWidth: vm.selectedMood == mood ? 1.5 : 1))
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.2), value: vm.selectedMood)
                }
            }
        }
        .padding(Constants.Layout.padding)
        .cardStyle()
    }
}

// MARK: - Energy & Stress
struct EnergyStressSection: View {
    @ObservedObject var vm: JournalViewModel

    var body: some View {
        VStack(spacing: 16) {
            JournalSlider(label: "Energy Level",
                          value: $vm.energyLevel,
                          range: 1...10, color: AppTheme.accentYellow,
                          icon: "bolt.fill",
                          lowLabel: "Exhausted", highLabel: "Energized")
            JournalSlider(label: "Stress Level",
                          value: $vm.stressLevel,
                          range: 1...10, color: AppTheme.accentPink,
                          icon: "brain.head.profile",
                          lowLabel: "Calm", highLabel: "Stressed")
        }
        .padding(Constants.Layout.padding)
        .cardStyle()
    }
}

struct JournalSlider: View {
    var label: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var color: Color
    var icon: String
    var lowLabel: String
    var highLabel: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon).font(.caption).foregroundColor(color)
                Text(label).font(AppFont.subheadline(.semibold)).foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("\(Int(value))/10").font(AppFont.subheadline(.bold)).foregroundColor(color)
            }
            Slider(value: $value, in: range, step: 1).tint(color)
            HStack {
                Text(lowLabel).font(AppFont.caption()).foregroundColor(AppTheme.textTertiary)
                Spacer()
                Text(highLabel).font(AppFont.caption()).foregroundColor(AppTheme.textTertiary)
            }
        }
    }
}

// MARK: - Habits
struct HabitsSection: View {
    @ObservedObject var vm: JournalViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Habits").font(AppFont.headline(.bold)).foregroundColor(AppTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                HabitToggle(label: "Meditated", icon: "brain", color: AppTheme.accent, isOn: $vm.meditated)
                HabitToggle(label: "Exercised", icon: "figure.run", color: AppTheme.accentBlue, isOn: $vm.exercised)
                HabitToggle(label: "Alcohol", icon: "wineglass", color: AppTheme.accentOrange, isOn: $vm.alcoholConsumed)
                HabitToggle(label: "Medication", icon: "pills.fill", color: AppTheme.accentGreen, isOn: $vm.medicationTaken)
            }

            // Sunlight
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "sun.max.fill").font(.caption).foregroundColor(AppTheme.accentYellow)
                    Text("Sunlight Exposure").font(AppFont.subheadline(.semibold)).foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Text("\(Int(vm.sunlightMinutes)) min").font(AppFont.subheadline(.bold)).foregroundColor(AppTheme.accentYellow)
                }
                Slider(value: $vm.sunlightMinutes, in: 0...120, step: 5).tint(AppTheme.accentYellow)
            }
        }
        .padding(Constants.Layout.padding)
        .cardStyle()
    }
}

struct HabitToggle: View {
    var label: String; var icon: String; var color: Color
    @Binding var isOn: Bool

    var body: some View {
        Button { HapticFeedback.selection(); isOn.toggle() } label: {
            HStack(spacing: 8) {
                Image(systemName: isOn ? "\(icon).fill" : icon)
                    .font(.system(size: 16))
                    .foregroundColor(isOn ? color : AppTheme.textTertiary)
                Text(label)
                    .font(AppFont.caption(.semibold))
                    .foregroundColor(isOn ? AppTheme.textPrimary : AppTheme.textSecondary)
                Spacer()
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isOn ? color : AppTheme.textTertiary)
            }
            .padding(12)
            .background(isOn ? color.opacity(0.1) : AppTheme.cardBackground)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isOn ? color : AppTheme.borderSubtle, lineWidth: isOn ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isOn)
    }
}

// MARK: - Notes
struct NotesSection: View {
    @ObservedObject var vm: JournalViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Daily Notes").font(AppFont.headline(.bold)).foregroundColor(AppTheme.textPrimary)
            TextEditor(text: $vm.notes)
                .foregroundColor(AppTheme.textPrimary)
                .font(AppFont.body())
                .frame(minHeight: 80)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(AppTheme.surfaceElevated)
                .cornerRadius(10)
        }
        .padding(Constants.Layout.padding)
        .cardStyle()
    }
}

// MARK: - Gratitude
struct GratitudeSection: View {
    @ObservedObject var vm: JournalViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "heart.fill").foregroundColor(AppTheme.accentPink)
                Text("Gratitude").font(AppFont.headline(.bold)).foregroundColor(AppTheme.textPrimary)
            }
            TextEditor(text: $vm.gratitudeNotes)
                .foregroundColor(AppTheme.textPrimary)
                .font(AppFont.body())
                .frame(minHeight: 60)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(AppTheme.surfaceElevated)
                .cornerRadius(10)
        }
        .padding(Constants.Layout.padding)
        .cardStyle()
    }
}

// MARK: - Recent Entries
struct RecentJournalSection: View {
    @ObservedObject var vm: JournalViewModel

    var body: some View {
        if !vm.recentEntries.isEmpty {
            VStack(spacing: 12) {
                SectionHeader(title: "Recent Entries")
                VStack(spacing: 0) {
                    ForEach(vm.recentEntries.prefix(5)) { entry in
                        JournalEntryRow(entry: entry)
                        Divider().background(AppTheme.borderSubtle)
                    }
                }
                .cardStyle()
            }
        }
    }
}

struct JournalEntryRow: View {
    var entry: JournalEntry

    var body: some View {
        HStack(spacing: 12) {
            Text(entry.mood.emoji).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.date.shortDate).font(AppFont.subheadline(.semibold)).foregroundColor(AppTheme.textPrimary)
                Text("Energy: \(entry.energyLevel)/10 · Stress: \(entry.stressLevel)/10")
                    .font(AppFont.caption()).foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            PillTag(text: entry.mood.displayName, color: Color(hex: entry.mood.color))
        }
        .padding(.horizontal, Constants.Layout.padding)
        .padding(.vertical, 10)
    }
}
