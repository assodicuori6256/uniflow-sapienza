import SwiftUI

public enum NavigationCategory: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case timetable = "Orario & Lezioni"
    case exams = "Libretto Esami"
    case notes = "Appunti & Risorse"
    case tasks = "Scadenze & Task"
    case commute = "Trasporti & Pendolari"
    case pomodoro = "Pausa & Studio"
    case settings = "Impostazioni"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .timetable: return "calendar.badge.clock"
        case .exams: return "graduationcap.fill"
        case .notes: return "note.text"
        case .tasks: return "checklist"
        case .commute: return "tram.fill"
        case .pomodoro: return "cup.and.saucer.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
