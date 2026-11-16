import Foundation
import SwiftUI

// MARK: - Enums

public enum ExamStatus: String, Codable, CaseIterable, Identifiable {
    case daSostenere = "Da sostenere"
    case pianificato = "Pianificato"
    case superato = "Superato"
    case verbalizzato = "Verbalizzato"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .daSostenere: return "hourglass"
        case .pianificato: return "calendar.badge.clock"
        case .superato: return "checkmark.circle.fill"
        case .verbalizzato: return "rosette"
        }
    }
    
    public var color: Color {
        switch self {
        case .daSostenere: return .orange
        case .pianificato: return .blue
        case .superato: return .green
        case .verbalizzato: return .purple
        }
    }
}

public enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case bassa = "Bassa"
    case media = "Media"
    case alta = "Alta"
    case urgente = "Urgente"
    
    public var id: String { rawValue }
    
    public var color: Color {
        switch self {
        case .bassa: return .gray
        case .media: return .blue
        case .alta: return .orange
        case .urgente: return .red
        }
    }
}

public enum TaskCategory: String, Codable, CaseIterable, Identifiable {
    case studio = "Studio & Ripasso"
    case scadenzaTasse = "Tasse & Burocrazia"
    case progetto = "Progetto / Laboratorio"
    case iscrizioneAppello = "Iscrizione Esame"
    case personale = "Personale"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .studio: return "book.fill"
        case .scadenzaTasse: return "banknote.fill"
        case .progetto: return "laptopcomputer"
        case .iscrizioneAppello: return "pencil.and.list.clipboard"
        case .personale: return "person.crop.circle"
        }
    }
}

public enum TransportType: String, Codable, CaseIterable, Identifiable {
    case treno = "Treno"
    case metro = "Metro"
    case autobus = "Autobus"
    case auto = "Automobile"
    case bici = "Bici / Piedi"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .treno: return "tram.fill"
        case .metro: return "tram.tunnel.fill"
        case .autobus: return "bus.fill"
        case .auto: return "car.fill"
        case .bici: return "bicycle"
        }
    }
    
    public var defaultBufferMinutes: Int {
        switch self {
        case .treno: return 15
        case .metro: return 10
        case .autobus: return 12
        case .auto: return 20
        case .bici: return 5
        }
    }
}

// MARK: - Core Entities

public struct Course: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var code: String
    public var name: String
    public var cfu: Int
    public var professor: String
    public var professorEmail: String
    public var officeHours: String
    public var colorHex: String
    public var semester: String
    public var classroomDefault: String
    public var onlineLink: String
    public var attendanceRequired: Bool
    public var totalLessonsAttended: Int
    
    public init(
        id: UUID = UUID(),
        code: String = "",
        name: String,
        cfu: Int = 6,
        professor: String = "",
        professorEmail: String = "",
        officeHours: String = "",
        colorHex: String = "#0A84FF",
        semester: String = "1° Semestre",
        classroomDefault: String = "",
        onlineLink: String = "",
        attendanceRequired: Bool = false,
        totalLessonsAttended: Int = 0
    ) {
        self.id = id
        self.code = code
        self.name = name
        self.cfu = cfu
        self.professor = professor
        self.professorEmail = professorEmail
        self.officeHours = officeHours
        self.colorHex = colorHex
        self.semester = semester
        self.classroomDefault = classroomDefault
        self.onlineLink = onlineLink
        self.attendanceRequired = attendanceRequired
        self.totalLessonsAttended = totalLessonsAttended
    }
    
    public var color: Color {
        Color(hex: colorHex)
    }
}

public struct Lesson: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var courseId: UUID
    public var dayOfWeek: Int // 1 = Lunedì, 2 = Martedì, ..., 6 = Sabato
    public var startHour: Int
    public var startMinute: Int
    public var endHour: Int
    public var endMinute: Int
    public var room: String
    public var building: String
    public var notes: String
    
    public init(
        id: UUID = UUID(),
        courseId: UUID,
        dayOfWeek: Int,
        startHour: Int,
        startMinute: Int = 0,
        endHour: Int,
        endMinute: Int = 0,
        room: String = "",
        building: String = "",
        notes: String = ""
    ) {
        self.id = id
        self.courseId = courseId
        self.dayOfWeek = dayOfWeek
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.room = room
        self.building = building
        self.notes = notes
    }
    
    public var dayName: String {
        switch dayOfWeek {
        case 1: return "Lunedì"
        case 2: return "Martedì"
        case 3: return "Mercoledì"
        case 4: return "Giovedì"
        case 5: return "Venerdì"
        case 6: return "Sabato"
        default: return "Domenica"
        }
    }
    
    public var timeRangeString: String {
        let start = String(format: "%02d:%02d", startHour, startMinute)
        let end = String(format: "%02d:%02d", endHour, endMinute)
        return "\(start) - \(end)"
    }
    
    public var durationMinutes: Int {
        let startTotal = startHour * 60 + startMinute
        let endTotal = endHour * 60 + endMinute
        return max(0, endTotal - startTotal)
    }
}

public struct Exam: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var courseId: UUID
    public var examDate: Date?
    public var grade: Int? // 18 - 30
    public var isLaude: Bool
    public var cfu: Int
    public var status: ExamStatus
    public var attemptNumber: Int
    public var notes: String
    
    public init(
        id: UUID = UUID(),
        courseId: UUID,
        examDate: Date? = nil,
        grade: Int? = nil,
        isLaude: Bool = false,
        cfu: Int = 6,
        status: ExamStatus = .daSostenere,
        attemptNumber: Int = 1,
        notes: String = ""
    ) {
        self.id = id
        self.courseId = courseId
        self.examDate = examDate
        self.grade = grade
        self.isLaude = isLaude
        self.cfu = cfu
        self.status = status
        self.attemptNumber = attemptNumber
        self.notes = notes
    }
    
    public var gradeDisplay: String {
        guard let grade = grade else { return "—" }
        return isLaude ? "\(grade)L" : "\(grade)"
    }
    
    public var effectivePointsForGPA: Double? {
        guard let grade = grade else { return nil }
        return Double(grade)
    }
}

public struct NoteItem: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var courseId: UUID?
    public var title: String
    public var content: String
    public var tags: [String]
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        courseId: UUID? = nil,
        title: String,
        content: String = "",
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.courseId = courseId
        self.title = title
        self.content = content
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct TaskItem: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var courseId: UUID?
    public var title: String
    public var description: String
    public var dueDate: Date
    public var priority: TaskPriority
    public var category: TaskCategory
    public var isCompleted: Bool
    
    public init(
        id: UUID = UUID(),
        courseId: UUID? = nil,
        title: String,
        description: String = "",
        dueDate: Date = Date().addingTimeInterval(86400 * 3),
        priority: TaskPriority = .media,
        category: TaskCategory = .studio,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.courseId = courseId
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.priority = priority
        self.category = category
        self.isCompleted = isCompleted
    }
    
    public var daysRemaining: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfDue = calendar.startOfDay(for: dueDate)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfDue)
        return components.day ?? 0
    }
    
    public var isOverdue: Bool {
        !isCompleted && daysRemaining < 0
    }
}

public struct CommuteRoute: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var name: String
    public var origin: String
    public var destination: String
    public var transportType: TransportType
    public var typicalDurationMinutes: Int
    public var bufferMinutes: Int
    public var departureTimes: [String] // "07:35", "08:05", etc.
    public var costPerTrip: Double
    public var notes: String
    
    public init(
        id: UUID = UUID(),
        name: String,
        origin: String,
        destination: String,
        transportType: TransportType = .treno,
        typicalDurationMinutes: Int = 35,
        bufferMinutes: Int = 15,
        departureTimes: [String] = ["07:40", "08:10", "08:40"],
        costPerTrip: Double = 2.60,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.origin = origin
        self.destination = destination
        self.transportType = transportType
        self.typicalDurationMinutes = typicalDurationMinutes
        self.bufferMinutes = bufferMinutes
        self.departureTimes = departureTimes
        self.costPerTrip = costPerTrip
        self.notes = notes
    }
    
    public var totalCommuteWindowMinutes: Int {
        typicalDurationMinutes + bufferMinutes
    }
}

public struct BusLine: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var lineNumber: String // es. "Linea 93", "Navetta Campus", "Bus 73"
    public var departureStop: String // es. "Stazione Centrale"
    public var arrivalStop: String // es. "Polo Universitario"
    public var direction: String // es. "Direzione Lambrate / Polo Scientifico"
    public var frequencyMinutes: Int // es. ogni 10 min
    public var scheduledTimes: [String] // es. ["07:20", "07:35", "07:50", "08:05", "08:20"]
    public var travelDurationMinutes: Int
    public var bufferMinutes: Int
    public var colorHex: String
    public var notes: String
    
    public init(
        id: UUID = UUID(),
        lineNumber: String,
        departureStop: String,
        arrivalStop: String,
        direction: String = "",
        frequencyMinutes: Int = 10,
        scheduledTimes: [String] = [],
        travelDurationMinutes: Int = 15,
        bufferMinutes: Int = 5,
        colorHex: String = "#FF9500",
        notes: String = ""
    ) {
        self.id = id
        self.lineNumber = lineNumber
        self.departureStop = departureStop
        self.arrivalStop = arrivalStop
        self.direction = direction
        self.frequencyMinutes = frequencyMinutes
        self.scheduledTimes = scheduledTimes
        self.travelDurationMinutes = travelDurationMinutes
        self.bufferMinutes = bufferMinutes
        self.colorHex = colorHex
        self.notes = notes
    }
    
    public var color: Color {
        Color(hex: colorHex)
    }
}

public struct StudySession: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var courseId: UUID?
    public var durationMinutes: Int
    public var date: Date
    public var notes: String
    
    public init(
        id: UUID = UUID(),
        courseId: UUID? = nil,
        durationMinutes: Int = 25,
        date: Date = Date(),
        notes: String = ""
    ) {
        self.id = id
        self.courseId = courseId
        self.durationMinutes = durationMinutes
        self.date = date
        self.notes = notes
    }
}

public struct StudyMotivation: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var text: String
    public var category: String // es. "Farmacia", "Traguardo Laurea", "Relax & Benessere", "Personale"
    public var author: String
    public var isFavorite: Bool
    
    public init(
        id: UUID = UUID(),
        text: String,
        category: String = "Farmacia",
        author: String = "Sapienza Farmacia",
        isFavorite: Bool = false
    ) {
        self.id = id
        self.text = text
        self.category = category
        self.author = author
        self.isFavorite = isFavorite
    }
}

public struct AppSettings: Codable, Equatable {
    public var studentName: String
    public var universityName: String
    public var degreeCourse: String
    public var totalDegreeCFU: Int
    public var laudeBonusPoints: Double
    public var thesisPointsEstimate: Double
    public var dailyStudyGoalHours: Double
    public var hasCompletedOnboarding: Bool
    public var targetGraduationGrade: Int
    public var isCommuter: Bool
    public var primaryTransport: String
    
    public init(
        studentName: String = "Studente Sapienza",
        universityName: String = "Sapienza Università di Roma",
        degreeCourse: String = "Farmacia (Ciclo Unico LM-13)",
        totalDegreeCFU: Int = 300,
        laudeBonusPoints: Double = 0.33,
        thesisPointsEstimate: Double = 6.0,
        dailyStudyGoalHours: Double = 4.5,
        hasCompletedOnboarding: Bool = false,
        targetGraduationGrade: Int = 110,
        isCommuter: Bool = true,
        primaryTransport: String = "Metro B / Tram"
    ) {
        self.studentName = studentName
        self.universityName = universityName
        self.degreeCourse = degreeCourse
        self.totalDegreeCFU = totalDegreeCFU
        self.laudeBonusPoints = laudeBonusPoints
        self.thesisPointsEstimate = thesisPointsEstimate
        self.dailyStudyGoalHours = dailyStudyGoalHours
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.targetGraduationGrade = targetGraduationGrade
        self.isCommuter = isCommuter
        self.primaryTransport = primaryTransport
    }
}

// MARK: - Professor

public struct Professor: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var name: String
    public var email: String
    public var officeHours: String // orario di ricevimento
    public var department: String
    
    public init(id: UUID = UUID(), name: String, email: String = "", officeHours: String = "", department: String = "Farmacia e Medicina") {
        self.id = id
        self.name = name
        self.email = email
        self.officeHours = officeHours
        self.department = department
    }
}

// MARK: - Color Extension for Hex
extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 10, 132, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
