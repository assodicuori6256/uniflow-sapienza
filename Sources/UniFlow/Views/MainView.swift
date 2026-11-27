import SwiftUI

public struct MainView: View {
    @EnvironmentObject private var store: DataStore
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    public init() {}
    
    public var body: some View {
        Group {
            if !store.settings.hasCompletedOnboarding {
                OnboardingView()
            } else {
                #if os(iOS)
                if horizontalSizeClass == .compact {
                    iPhoneLayout
                } else {
                    desktopSplitLayout
                }
                #else
                desktopSplitLayout
                #endif
            }
        }
        #if os(macOS)
        .frame(minWidth: 950, minHeight: 620)
        #endif
    }
    
    // MARK: - Desktop & iPad Split Layout
    
    private var desktopSplitLayout: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailContent
        }
    }
    
    // MARK: - iPhone Compact Layout
    
    #if os(iOS)
    private var iPhoneLayout: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2.fill")
            }
            
            NavigationStack {
                TimetableView()
            }
            .tabItem {
                Label("Orario", systemImage: "calendar.badge.clock")
            }
            
            NavigationStack {
                ExamsView()
            }
            .tabItem {
                Label("Libretto", systemImage: "graduationcap.fill")
            }
            
            NavigationStack {
                CommuteView()
            }
            .tabItem {
                Label("Trasporti", systemImage: "tram.fill")
            }
            
            NavigationStack {
                iPhoneMoreView()
            }
            .tabItem {
                Label("Altro", systemImage: "ellipsis.circle.fill")
            }
        }
    }
    #endif
    
    // MARK: - Sidebar (macOS & iPad)
    
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
                    Text("Sapienza Farmacia")
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
                .padding(.vertical, 6)
                
                // Developer Footer
                Divider()
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Dev: Aldo Cuko")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        if let gh = URL(string: "https://github.com/assodicuori6256/uniflow-sapienza") {
                            Link(destination: gh) {
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.blue)
                            }
                            .help("Apri repository GitHub")
                        }
                        if let mail = URL(string: "mailto:aldo.superiori@gmail.com") {
                            Link(destination: mail) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.blue)
                            }
                            .help("Invia email a Aldo Cuko")
                        }
                    }
                    Text("Sapienza Farmacia • macOS, iOS, iPadOS")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
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

// MARK: - iPhone "Altro" Submenu
#if os(iOS)
public struct iPhoneMoreView: View {
    @EnvironmentObject private var store: DataStore
    
    public init() {}
    
    public var body: some View {
        List {
            Section("Studio & Organizzazione") {
                NavigationLink {
                    NotesView()
                } label: {
                    Label("Appunti & Note", systemImage: "doc.text.fill")
                }
                
                NavigationLink {
                    TasksView()
                } label: {
                    Label("Scadenze & Task", systemImage: "checklist")
                }
                
                NavigationLink {
                    PomodoroView()
                } label: {
                    Label("Pausa & Studio", systemImage: "cup.and.saucer.fill")
                }
            }
            
            Section("Preferenze") {
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Impostazioni & Profilo", systemImage: "gearshape.fill")
                }
            }
            
            Section("Sviluppatore & Info") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Aldo Cuko")
                            .font(.headline)
                        Text("Sviluppatore di UniFlow")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                if let emailURL = URL(string: "mailto:aldo.superiori@gmail.com") {
                    Link(destination: emailURL) {
                        Label("aldo.superiori@gmail.com", systemImage: "envelope.fill")
                    }
                }
                
                if let ghURL = URL(string: "https://github.com/assodicuori6256/uniflow-sapienza") {
                    Link(destination: ghURL) {
                        Label("Repository GitHub", systemImage: "link.circle.fill")
                    }
                }
            }
        }
        .navigationTitle("Altro")
    }
}
#endif
