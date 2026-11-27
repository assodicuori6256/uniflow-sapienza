import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

@main
public struct UniFlowApp: App {
    @StateObject private var store = DataStore()
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(store)
                .navigationTitle("UniFlow")
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .commands {
            SidebarCommands()
            
            CommandGroup(after: .newItem) {
                Button("Nuova Nota") {
                    store.selectedNavigationItem = .notes
                }
                .keyboardShortcut("n", modifiers: [.command])
                
                Button("Nuova Scadenza") {
                    store.selectedNavigationItem = .tasks
                }
                .keyboardShortcut("t", modifiers: [.command])
            }
            
            CommandMenu("Navigazione") {
                Button("Dashboard") {
                    store.selectedNavigationItem = .dashboard
                }
                .keyboardShortcut("1", modifiers: [.command])
                
                Button("Orario & Lezioni") {
                    store.selectedNavigationItem = .timetable
                }
                .keyboardShortcut("2", modifiers: [.command])
                
                Button("Libretto Esami") {
                    store.selectedNavigationItem = .exams
                }
                .keyboardShortcut("3", modifiers: [.command])
                
                Button("Appunti") {
                    store.selectedNavigationItem = .notes
                }
                .keyboardShortcut("4", modifiers: [.command])
                
                Button("Scadenze") {
                    store.selectedNavigationItem = .tasks
                }
                .keyboardShortcut("5", modifiers: [.command])
                
                Button("Trasporti") {
                    store.selectedNavigationItem = .commute
                }
                .keyboardShortcut("6", modifiers: [.command])
                
                Button("Pausa & Studio") {
                    store.selectedNavigationItem = .pomodoro
                }
                .keyboardShortcut("7", modifiers: [.command])
            }
        }
        #endif
    }
}
