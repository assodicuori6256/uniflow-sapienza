import SwiftUI

public struct MainView: View {
    @EnvironmentObject private var store: DataStore
    
    public init() {}
    
    public var body: some View {
        Group {
            if !store.settings.hasCompletedOnboarding {
                OnboardingView()
            } else {
                NavigationSplitView {
                    sidebarContent
                } detail: {
                    detailContent
                }
            }
        }
        .frame(minWidth: 950, minHeight: 620)
    }
    
    // MARK: - Sidebar
    
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            // App Branding Header
            HStack(spacing: 12) {
                ZStack {
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 36, height: 36)
                    .cornerRadius(9)
                    
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("UniFlow")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text("Ecosistema Universitario")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)
            
            Divider()
            
            // Navigation List
            List(selection: $store.selectedNavigationItem) {
                Section("Accademico") {
                    ForEach([
                        NavigationCategory.dashboard,
                        NavigationCategory.timetable,
                        NavigationCategory.exams,
                        NavigationCategory.notes
                    ]) { item in
                        NavigationLink(value: item) {
                            Label(item.rawValue, systemImage: item.iconName)
                        }
                    }
                }
                
                Section("Organizzazione") {
                    ForEach([
                        NavigationCategory.tasks,
                        NavigationCategory.commute,
                        NavigationCategory.pomodoro
                    ]) { item in
                        NavigationLink(value: item) {
                            Label(item.rawValue, systemImage: item.iconName)
                        }
                    }
                }
                
                Section("Sistema") {
                    NavigationLink(value: NavigationCategory.settings) {
                        Label(NavigationCategory.settings.rawValue, systemImage: NavigationCategory.settings.iconName)
                    }
                }
            }
            .listStyle(.sidebar)
            
            // Bottom Quick Status (CFU Mini summary)
            VStack(alignment: .leading, spacing: 6) {
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Carriera: \(store.totalPassedCFU)/\(store.settings.totalDegreeCFU) CFU")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Media: \(store.weightedGPA > 0 ? String(format: "%.2f", store.weightedGPA) : "—")")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(Int(store.cfuProgressPercentage * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .frame(minWidth: 220, maxWidth: 260)
    }
    
    // MARK: - Detail Content
    
    @ViewBuilder
    private var detailContent: some View {
        switch store.selectedNavigationItem {
        case .dashboard, .none:
            DashboardView()
        case .timetable:
            TimetableView()
        case .exams:
            ExamsView()
        case .notes:
            NotesView()
        case .tasks:
            TasksView()
        case .commute:
            CommuteView()
        case .pomodoro:
            PomodoroView()
        case .settings:
            SettingsView()
        }
    }
}
