import Foundation
import SwiftUI
import Combine

public struct UniFlowArchive: Codable {
    public var version: Int = 1
    public var exportedAt: Date = Date()
    public var settings: AppSettings
    public var courses: [Course]
    public var lessons: [Lesson]
    public var exams: [Exam]
    public var notes: [NoteItem]
    public var tasks: [TaskItem]
    public var commuteRoutes: [CommuteRoute]
    public var busLines: [BusLine] = []
    public var studySessions: [StudySession]
    public var motivations: [StudyMotivation] = []
    public var professors: [Professor] = []
}

@MainActor
public class DataStore: ObservableObject {
    @Published public var settings: AppSettings = AppSettings()
    @Published public var courses: [Course] = []
    @Published public var lessons: [Lesson] = []
    @Published public var exams: [Exam] = []
    @Published public var notes: [NoteItem] = []
    @Published public var tasks: [TaskItem] = []
    @Published public var commuteRoutes: [CommuteRoute] = []
    @Published public var busLines: [BusLine] = []
    @Published public var studySessions: [StudySession] = []
    @Published public var motivations: [StudyMotivation] = []
    @Published public var professors: [Professor] = []
    
    @Published public var selectedNavigationItem: NavigationCategory? = .dashboard
    
    private let fileManager = FileManager.default
    private var dataURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("UniFlow", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("uniflow_data.json")
    }
    
    public init() {
        loadData()
    }
    
    // MARK: - Computed Academic Statistics
    
    public var passedExams: [Exam] {
        exams.filter { ($0.status == .superato || $0.status == .verbalizzato) && $0.grade != nil }
    }
    
    public var totalPassedCFU: Int {
        passedExams.reduce(0) { $0 + $1.cfu }
    }
    
    public var remainingCFU: Int {
        max(0, settings.totalDegreeCFU - totalPassedCFU)
    }
    
    public var cfuProgressPercentage: Double {
        guard settings.totalDegreeCFU > 0 else { return 0 }
        return min(1.0, Double(totalPassedCFU) / Double(settings.totalDegreeCFU))
    }
    
    public var weightedGPA: Double {
        let passed = passedExams
        let totalWeight = passed.reduce(0) { $0 + $1.cfu }
        guard totalWeight > 0 else { return 0.0 }
        let totalWeightedScore = passed.reduce(0.0) { sum, exam in
            let gradeVal = Double(exam.grade ?? 0)
            return sum + (gradeVal * Double(exam.cfu))
        }
        return totalWeightedScore / Double(totalWeight)
    }
    
    public var arithmeticGPA: Double {
        let passed = passedExams
        guard !passed.isEmpty else { return 0.0 }
        let sum = passed.reduce(0.0) { $0 + Double($1.grade ?? 0) }
        return sum / Double(passed.count)
    }
    
    public var laudeCount: Int {
        passedExams.filter { $0.isLaude }.count
    }
    
    public var graduationBaseScore: Double {
        guard weightedGPA > 0 else { return 0.0 }
        // Standard Italian graduation base: (Media Ponderata * 11) / 3
        return (weightedGPA * 11.0) / 3.0
    }
    
    public var projectedGraduationScore: Double {
        guard graduationBaseScore > 0 else { return 0.0 }
        let bonusLaude = Double(laudeCount) * settings.laudeBonusPoints
        let total = graduationBaseScore + settings.thesisPointsEstimate + bonusLaude
        return min(110.0, total)
    }
    
    // MARK: - Lesson & Schedule Queries
    
    public func course(for id: UUID?) -> Course? {
        guard let id = id else { return nil }
        return courses.first(where: { $0.id == id })
    }
    
    public func lessons(forDay day: Int) -> [(lesson: Lesson, course: Course)] {
        lessons
            .filter { $0.dayOfWeek == day }
            .sorted { ($0.startHour * 60 + $0.startMinute) < ($1.startHour * 60 + $1.startMinute) }
            .compactMap { lesson in
                guard let course = course(for: lesson.courseId) else { return nil }
                return (lesson, course)
            }
    }
    
    public var todayLessons: [(lesson: Lesson, course: Course)] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        // In Gregorian: 1 = Sun, 2 = Mon, 3 = Tue, 4 = Wed, 5 = Thu, 6 = Fri, 7 = Sat
        // We map to: 1 = Lun, 2 = Mar, ..., 6 = Sab, 7 = Dom
        let italianDay: Int
        switch weekday {
        case 1: italianDay = 7 // Sunday
        case 2: italianDay = 1 // Monday
        case 3: italianDay = 2 // Tuesday
        case 4: italianDay = 3 // Wednesday
        case 5: italianDay = 4 // Thursday
        case 6: italianDay = 5 // Friday
        case 7: italianDay = 6 // Saturday
        default: italianDay = 1
        }
        return lessons(forDay: italianDay)
    }
    
    public var nextUpcomingLesson: (lesson: Lesson, course: Course)? {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotal = currentHour * 60 + currentMinute
        
        let today = todayLessons
        for item in today {
            let start = item.lesson.startHour * 60 + item.lesson.startMinute
            if start >= currentTotal {
                return item
            }
        }
        return today.first
    }
    
    // MARK: - Task Queries
    
    public var pendingTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted }.sorted { $0.dueDate < $1.dueDate }
    }
    
    public var urgentTasks: [TaskItem] {
        pendingTasks.filter { $0.priority == .alta || $0.priority == .urgente || $0.daysRemaining <= 2 }
    }
    
    public var completedTasksCount: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    // MARK: - CRUD Operations
    
    public func addCourse(_ course: Course) {
        courses.append(course)
        saveData()
    }
    
    public func updateCourse(_ course: Course) {
        if let idx = courses.firstIndex(where: { $0.id == course.id }) {
            courses[idx] = course
            saveData()
        }
    }
    
    public func updateProfessor(forCourseId courseId: UUID, professor: String, email: String = "") {
        if let idx = courses.firstIndex(where: { $0.id == courseId }) {
            courses[idx].professor = professor
            if !email.isEmpty {
                courses[idx].professorEmail = email
            }
            saveData()
        }
    }
    
    public func deleteCourse(at offsets: IndexSet) {
        let idsToDelete = offsets.map { courses[$0].id }
        courses.remove(atOffsets: offsets)
        lessons.removeAll { idsToDelete.contains($0.courseId) }
        exams.removeAll { idsToDelete.contains($0.courseId) }
        saveData()
    }
    
    public func addLesson(_ lesson: Lesson) {
        lessons.append(lesson)
        saveData()
    }
    
    public func updateLesson(_ lesson: Lesson) {
        if let idx = lessons.firstIndex(where: { $0.id == lesson.id }) {
            lessons[idx] = lesson
            saveData()
        }
    }
    
    public func deleteLesson(id: UUID) {
        lessons.removeAll { $0.id == id }
        saveData()
    }
    
    public func addExam(_ exam: Exam) {
        exams.append(exam)
        saveData()
    }
    
    public func updateExam(_ exam: Exam) {
        if let idx = exams.firstIndex(where: { $0.id == exam.id }) {
            exams[idx] = exam
            saveData()
        }
    }
    
    public func deleteExam(id: UUID) {
        exams.removeAll { $0.id == id }
        saveData()
    }
    
    public func addNote(_ note: NoteItem) {
        notes.append(note)
        saveData()
    }
    
    public func updateNote(_ note: NoteItem) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            var updated = note
            updated.updatedAt = Date()
            notes[idx] = updated
            saveData()
        }
    }
    
    public func deleteNote(id: UUID) {
        notes.removeAll { $0.id == id }
        saveData()
    }
    
    public func addTask(_ task: TaskItem) {
        tasks.append(task)
        saveData()
    }
    
    public func toggleTaskCompletion(_ task: TaskItem) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isCompleted.toggle()
            saveData()
        }
    }
    
    public func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        saveData()
    }
    
    public func addCommuteRoute(_ route: CommuteRoute) {
        commuteRoutes.append(route)
        saveData()
    }
    
    public func updateCommuteRoute(_ route: CommuteRoute) {
        if let idx = commuteRoutes.firstIndex(where: { $0.id == route.id }) {
            commuteRoutes[idx] = route
            saveData()
        }
    }
    
    public func deleteCommuteRoute(id: UUID) {
        commuteRoutes.removeAll { $0.id == id }
        saveData()
    }
    
    public func addBusLine(_ line: BusLine) {
        busLines.append(line)
        saveData()
    }
    
    public func updateBusLine(_ line: BusLine) {
        if let idx = busLines.firstIndex(where: { $0.id == line.id }) {
            busLines[idx] = line
            saveData()
        }
    }
    
    public func deleteBusLine(id: UUID) {
        busLines.removeAll { $0.id == id }
        saveData()
    }
    
    public func completeOnboarding(
        studentName: String,
        universityName: String,
        degreeCourse: String,
        totalCFU: Int,
        targetGrade: Int,
        isCommuter: Bool,
        primaryTransport: String,
        dailyHours: Double
    ) {
        settings.studentName = studentName
        settings.universityName = universityName
        settings.degreeCourse = degreeCourse
        settings.totalDegreeCFU = totalCFU
        settings.targetGraduationGrade = targetGrade
        settings.isCommuter = isCommuter
        settings.primaryTransport = primaryTransport
        settings.dailyStudyGoalHours = dailyHours
        settings.hasCompletedOnboarding = true
        saveData()
    }
    
    public func reopenOnboarding() {
        settings.hasCompletedOnboarding = false
        saveData()
    }
    
    public func addMotivation(_ motivation: StudyMotivation) {
        motivations.append(motivation)
        saveData()
    }
    
    public func deleteMotivation(id: UUID) {
        motivations.removeAll { $0.id == id }
        saveData()
    }
    
    public func recordStudySession(courseId: UUID?, minutes: Int, notes: String = "") {
        let session = StudySession(courseId: courseId, durationMinutes: minutes, date: Date(), notes: notes)
        studySessions.append(session)
        saveData()
    }
    
    // MARK: - Persistence & Archive
    
    public func saveData() {
        let archive = UniFlowArchive(
            version: 1,
            exportedAt: Date(),
            settings: settings,
            courses: courses,
            lessons: lessons,
            exams: exams,
            notes: notes,
            tasks: tasks,
            commuteRoutes: commuteRoutes,
            busLines: busLines,
            studySessions: studySessions,
            motivations: motivations
        )
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(archive)
            try data.write(to: dataURL, options: .atomic)
        } catch {
            print("UniFlow: errore nel salvataggio dei dati: \(error)")
        }
    }
    
    public func loadData() {
        guard fileManager.fileExists(atPath: dataURL.path) else {
            loadSampleData()
            saveData()
            return
        }
        do {
            let data = try Data(contentsOf: dataURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let archive = try decoder.decode(UniFlowArchive.self, from: data)
            self.settings = archive.settings
            self.courses = archive.courses
            self.lessons = archive.lessons
            self.exams = archive.exams
            self.notes = archive.notes
            self.tasks = archive.tasks
            self.commuteRoutes = archive.commuteRoutes
            self.busLines = archive.busLines
            self.studySessions = archive.studySessions
            self.motivations = archive.motivations
        } catch {
            print("UniFlow: caricamento fallito, uso dati di default: \(error)")
            loadSampleData()
        }
    }
    
    public func resetToSampleData() {
        loadSampleData()
        saveData()
    }
    
    public func clearAllData() {
        self.settings = AppSettings(hasCompletedOnboarding: false)
        self.courses = []
        self.lessons = []
        self.exams = []
        self.notes = []
        self.tasks = []
        self.commuteRoutes = []
        self.busLines = []
        self.studySessions = []
        self.motivations = []
        saveData()
    }
    
    public func exportArchiveJSON() -> String? {
        let archive = UniFlowArchive(
            version: 1,
            exportedAt: Date(),
            settings: settings,
            courses: courses,
            lessons: lessons,
            exams: exams,
            notes: notes,
            tasks: tasks,
            commuteRoutes: commuteRoutes,
            busLines: busLines,
            studySessions: studySessions,
            motivations: motivations
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(archive), let str = String(data: data, encoding: .utf8) {
            return str
        }
        return nil
    }
    
    // MARK: - Sample Data Seeder (Sapienza Farmacia)
    
    public func loadSampleData() {
        self.settings = AppSettings(
            studentName: "Studente Sapienza",
            universityName: "Sapienza Università di Roma",
            degreeCourse: "Farmacia (Ciclo Unico LM-13)",
            totalDegreeCFU: 300,
            laudeBonusPoints: 0.33,
            thesisPointsEstimate: 6.0,
            dailyStudyGoalHours: 4.5
        )
        
        let c1 = Course(
            code: "FAR-01",
            name: "Chimica Generale ed Inorganica",
            cfu: 10,
            professor: "Prof.ssa Claudia Rossi",
            professorEmail: "claudia.rossi@uniroma1.it",
            officeHours: "Martedì 11:00 - 13:00 (Ed. CU014)",
            colorHex: "#007AFF",
            semester: "1° Semestre",
            classroomDefault: "Aula A - Farmacia (Ed. CU019)",
            onlineLink: "",
            attendanceRequired: true
        )
        
        let c2 = Course(
            code: "FAR-02",
            name: "Botanica Farmaceutica & Biologia",
            cfu: 8,
            professor: "Prof. Andrea Ferri",
            professorEmail: "andrea.ferri@uniroma1.it",
            officeHours: "Giovedì 15:00 - 17:00",
            colorHex: "#34C759",
            semester: "1° Semestre",
            classroomDefault: "Aula Botanica (Ed. CU022)",
            onlineLink: "",
            attendanceRequired: false
        )
        
        let c3 = Course(
            code: "FAR-03",
            name: "Chimica Organica",
            cfu: 10,
            professor: "Prof. Stefano Moretti",
            professorEmail: "stefano.moretti@uniroma1.it",
            officeHours: "Mercoledì 10:00 (Ed. CU014)",
            colorHex: "#FF9500",
            semester: "2° Semestre",
            classroomDefault: "Aula Cannizzaro (Chimica CU014)",
            onlineLink: "",
            attendanceRequired: true
        )
        
        let c4 = Course(
            code: "FAR-04",
            name: "Anatomia Umana e Fisiologia",
            cfu: 9,
            professor: "Prof. Marco De Angelis",
            professorEmail: "marco.deangelis@uniroma1.it",
            officeHours: "Lunedì 14:00 (Ed. CU026)",
            colorHex: "#AF52DE",
            semester: "2° Semestre",
            classroomDefault: "Aula C (Fisiologia CU026)",
            onlineLink: "",
            attendanceRequired: false
        )
        
        let c5 = Course(
            code: "FAR-05",
            name: "Laboratorio Preparazioni Galeniche",
            cfu: 6,
            professor: "Prof.ssa Laura Gentile",
            professorEmail: "laura.gentile@uniroma1.it",
            officeHours: "Venerdì 14:00",
            colorHex: "#FF2D55",
            semester: "Annuale",
            classroomDefault: "Lab Galenico (Ed. CU019)",
            attendanceRequired: true
        )
        
        let c6 = Course(
            code: "FAR-06",
            name: "Chimica Farmaceutica e Tossicologica",
            cfu: 10,
            professor: "Prof. Roberto Silvestri",
            professorEmail: "roberto.silvestri@uniroma1.it",
            officeHours: "Giovedì 11:00",
            colorHex: "#5856D6",
            semester: "Anno Successivo",
            classroomDefault: "Aula A Farmacia"
        )
        
        self.courses = [c1, c2, c3, c4, c5, c6]
        
        // Lessons (Sapienza Città Universitaria)
        self.lessons = [
            // Lunedì
            Lesson(courseId: c1.id, dayOfWeek: 1, startHour: 8, startMinute: 30, endHour: 10, endMinute: 30, room: "Aula A Farmacia", building: "Edificio CU019"),
            Lesson(courseId: c2.id, dayOfWeek: 1, startHour: 11, startMinute: 0, endHour: 13, endMinute: 0, room: "Aula Botanica", building: "Edificio CU022"),
            
            // Martedì
            Lesson(courseId: c3.id, dayOfWeek: 2, startHour: 9, startMinute: 0, endHour: 11, endMinute: 30, room: "Aula Cannizzaro", building: "Edificio CU014 Chimica", notes: "Meccanismi di reazione e stereochimica"),
            Lesson(courseId: c1.id, dayOfWeek: 2, startHour: 12, startMinute: 0, endHour: 14, endMinute: 0, room: "Aula A Farmacia", building: "Edificio CU019"),
            
            // Mercoledì
            Lesson(courseId: c4.id, dayOfWeek: 3, startHour: 9, startMinute: 30, endHour: 12, endMinute: 30, room: "Aula C Fisiologia", building: "Edificio CU026"),
            
            // Giovedì
            Lesson(courseId: c3.id, dayOfWeek: 4, startHour: 10, startMinute: 0, endHour: 12, endMinute: 30, room: "Aula Cannizzaro", building: "Edificio CU014"),
            Lesson(courseId: c5.id, dayOfWeek: 4, startHour: 14, startMinute: 0, endHour: 17, endMinute: 30, room: "Laboratorio Galenico", building: "Edificio CU019", notes: "Obbligo camice e occhiali protettivi"),
            
            // Venerdì
            Lesson(courseId: c2.id, dayOfWeek: 5, startHour: 9, startMinute: 0, endHour: 11, endMinute: 30, room: "Aula Botanica", building: "Edificio CU022", notes: "Riconoscimento droghe vegetali")
        ]
        
        // Exams
        let datePassed1 = Calendar.current.date(byAdding: .month, value: -6, to: Date())
        let datePassed2 = Calendar.current.date(byAdding: .month, value: -4, to: Date())
        let dateNextExam = Calendar.current.date(byAdding: .day, value: 20, to: Date())
        
        self.exams = [
            Exam(courseId: c1.id, examDate: datePassed1, grade: 28, isLaude: false, cfu: 10, status: .verbalizzato, attemptNumber: 1, notes: "Scritto 27, orale 29 su equilibri in soluzione"),
            Exam(courseId: c2.id, examDate: datePassed2, grade: 30, isLaude: true, cfu: 8, status: .verbalizzato, attemptNumber: 1, notes: "Riconoscimento vetrini ed erbario eccellente"),
            Exam(courseId: c3.id, examDate: dateNextExam, grade: nil, isLaude: false, cfu: 10, status: .pianificato, attemptNumber: 1, notes: "Appello sessione anticipata su Infostud"),
            Exam(courseId: c4.id, examDate: nil, grade: nil, isLaude: false, cfu: 9, status: .daSostenere, attemptNumber: 1),
            Exam(courseId: c5.id, examDate: nil, grade: nil, isLaude: false, cfu: 6, status: .daSostenere, attemptNumber: 1),
            Exam(courseId: c6.id, examDate: nil, grade: nil, isLaude: false, cfu: 10, status: .daSostenere, attemptNumber: 1)
        ]
        
        // Notes
        self.notes = [
            NoteItem(
                courseId: c3.id,
                title: "Reazioni di Sostituzione Elettrofila Aromatica (SEAr)",
                content: """
                # Meccanismi di Reazione: Benzene e Derivati
                
                ## Fasi della SEAr:
                1. Generazione dell'elettrofilo $E^+$ (es. nitrazione con $HNO_3 + H_2SO_4 \\rightarrow NO_2^+$).
                2. Attacco elettrofilo con formazione del carbocatione intermedio (complesso $\\sigma$ o ione arenio stabilizzato per risonanza).
                3. Perdita di un protone per ripristinare l'aromaticità del sistema ad anello.
                
                ### Effetto dei Sostituenti:
                - **Attivanti (orto/para-orientanti)**: $-OH, -NH_2, -OCH_3, -CH_3$
                - **Disattivanti (meta-orientanti)**: $-NO_2, -CN, -COOH, -CHO$
                - **Alogeni**: debolmente disattivanti ma orto/para-orientanti per effetto di risonanza.
                """,
                tags: ["ChimicaOrganica", "Meccanismi", "Benzene", "Sapienza"]
            ),
            NoteItem(
                courseId: c2.id,
                title: "Alcaloidi della Belladonna e Principi Attivi Vegetali",
                content: """
                # Atropa Belladonna (Solanaceae)
                
                - **Droga**: foglie e radici essiccate.
                - **Principi attivi**: alcaloidi tropanici ($L$-iosciamina, atropina, scopolamina).
                - **Azione farmacologica**: parasimpaticolitico, antagonista competitivo dei recettori muscarinici dell'acetilcolina.
                - **Usi terapeutici**: midriatico (oftalmologia), antispastico della muscolatura liscia viscerale, antidoto per intossicazione da organofosforici.
                """,
                tags: ["BotanicaFarmaceutica", "Alcaloidi", "DrogheVegetali"]
            ),
            NoteItem(
                courseId: c5.id,
                title: "Norme Galeniche: Preparazione di Capsule e Polveri",
                content: """
                # Laboratorio di Preparazioni Galeniche Magistrali
                
                1. Taratura bilancia analitica di precisione ($\\pm 0.1\\,mg$).
                2. Calcolo della quantità di eccipiente (lattosio/amido di mais) per saturare il volume dell'incapsulatrice manuale.
                3. Metodo delle diluizioni geometriche per omogeneizzare principi attivi a basso dosaggio.
                4. Controllo uniformità di massa su 20 capsule secondo Farmacopea Ufficiale (FU XII ed.).
                """,
                tags: ["Galenica", "Laboratorio", "Farmacopea"]
            )
        ]
        
        // Tasks
        self.tasks = [
            TaskItem(
                courseId: c5.id,
                title: "Relazione di Laboratorio Galenico: Capsule Magistrali",
                description: "Completare la relazione con i calcoli della tara, saggio di uniformità di peso e foglio di lavorazione FU.",
                dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                priority: .alta,
                category: .progetto,
                isCompleted: false
            ),
            TaskItem(
                courseId: nil,
                title: "Pagamento 2ª Rata Tasse Sapienza (Infostud / PagoPA)",
                description: "Bollettino scaricabile dalla sezione Tasse di Infostud entro la scadenza fissata dall'ateneo.",
                dueDate: Calendar.current.date(byAdding: .day, value: 12, to: Date()) ?? Date(),
                priority: .urgente,
                category: .scadenzaTasse,
                isCompleted: false
            ),
            TaskItem(
                courseId: c3.id,
                title: "Prenotazione appello Chimica Organica su Infostud",
                description: "Verificare apertura finestra prenotazioni e ricevuta di iscrizione.",
                dueDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
                priority: .media,
                category: .iscrizioneAppello,
                isCompleted: false
            ),
            TaskItem(
                courseId: c1.id,
                title: "Ripasso equilibri acido-base e titolazioni redox",
                description: "Esercizi su pH di soluzioni tampone e idrolisi salina per il ripasso.",
                dueDate: Calendar.current.date(byAdding: .day, value: 6, to: Date()) ?? Date(),
                priority: .media,
                category: .studio,
                isCompleted: false
            )
        ]
        
        // Commute routes for Sapienza Roma
        self.commuteRoutes = [
            CommuteRoute(
                name: "Metro B da Roma Termini / Tiburtina -> Policlinico",
                origin: "Roma Termini / Tiburtina",
                destination: "Fermata Metro Policlinico (Sapienza)",
                transportType: .metro,
                typicalDurationMinutes: 12,
                bufferMinutes: 8,
                departureTimes: ["07:35", "07:42", "07:50", "07:58", "08:05", "08:12", "08:20"],
                costPerTrip: 1.50,
                notes: "Uscita Viale Regina Elena, 5 min a piedi dall'Edificio di Farmacia (CU019)."
            ),
            CommuteRoute(
                name: "Treno Regionale FL2 da Tivoli/Guidonia -> Tiburtina",
                origin: "Tivoli / Guidonia",
                destination: "Roma Tiburtina FS",
                transportType: .treno,
                typicalDurationMinutes: 35,
                bufferMinutes: 12,
                departureTimes: ["06:55", "07:22", "07:48", "08:15"],
                costPerTrip: 2.60,
                notes: "A Tiburtina cambio rapido con Metro B direzione Laurentina per 2 fermate."
            )
        ]
        
        // Bus lines for Sapienza Roma
        self.busLines = [
            BusLine(
                lineNumber: "Tram 3 / Tram 19 (Regina Elena)",
                departureStop: "Piazza di Porta Maggiore",
                arrivalStop: "Fermata Policlinico / Regina Elena (Sapienza)",
                direction: "Valle Giulia / Risorgimento",
                frequencyMinutes: 7,
                scheduledTimes: ["07:40", "07:47", "07:54", "08:01", "08:08", "08:15", "08:22"],
                travelDurationMinutes: 14,
                bufferMinutes: 6,
                colorHex: "#34C759",
                notes: "Comodissimo per studenti che alloggiano o passano da San Lorenzo"
            ),
            BusLine(
                lineNumber: "Bus 310 (Termini -> Sapienza)",
                departureStop: "Stazione Termini (Piazza dei Cinquecento)",
                arrivalStop: "Viale dell'Università (Città Universitaria)",
                direction: "Vescovio",
                frequencyMinutes: 10,
                scheduledTimes: ["07:35", "07:45", "07:55", "08:05", "08:15", "08:25"],
                travelDurationMinutes: 15,
                bufferMinutes: 7,
                colorHex: "#FF9500",
                notes: "Fermata proprio davanti ai cancelli di Viale dell'Università"
            ),
            BusLine(
                lineNumber: "Bus 492 (Tiburtina -> Piazzale Aldo Moro)",
                departureStop: "Stazione Tiburtina",
                arrivalStop: "Piazzale Aldo Moro (Ingresso Principale Sapienza)",
                direction: "Stazione Metro Cipro",
                frequencyMinutes: 12,
                scheduledTimes: ["07:30", "07:42", "07:54", "08:06", "08:18"],
                travelDurationMinutes: 16,
                bufferMinutes: 6,
                colorHex: "#007AFF",
                notes: "Porta direttamente davanti alla statua della Minerva"
            )
        ]
        
        // Motivations tailored for Sapienza Pharmacy
        self.motivations = [
            StudyMotivation(
                text: "Il farmacista è il primo presidio sanitario sul territorio: la tua competenza salverà delle vite.",
                category: "Farmacia",
                author: "Sapienza Farmacia",
                isFavorite: true
            ),
            StudyMotivation(
                text: "Ogni reazione di chimica organica e ogni saggio galenico sono un passo verso il tuo camice bianco.",
                category: "Farmacia",
                author: "Motto Studenti Sapienza",
                isFavorite: true
            ),
            StudyMotivation(
                text: "300 CFU sembrano una montagna, ma si scalano un esame alla volta. Concentrati sul capitolo di oggi!",
                category: "Traguardo Laurea",
                author: "Motivazione Personale",
                isFavorite: false
            ),
            StudyMotivation(
                text: "Pausa meritata: bevi un bicchiere d'acqua, fai respiri profondi e lascia riposare gli occhi dagli schemi molecolari.",
                category: "Relax & Benessere",
                author: "Salute & Focus",
                isFavorite: true
            ),
            StudyMotivation(
                text: "Un caffè a Piazzale Aldo Moro e poi si riparte carichi!",
                category: "Sapienza Life",
                author: "Spirito Universitario",
                isFavorite: false
            )
        ]
        
        // Study sessions
        self.studySessions = [
            StudySession(courseId: c1.id, durationMinutes: 50, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, notes: "Esercizi orbitali molecolari"),
            StudySession(courseId: c3.id, durationMinutes: 50, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, notes: "Reazioni di condensazione aldolica"),
            StudySession(courseId: c2.id, durationMinutes: 25, date: Date(), notes: "Ripasso Solanaceae e alcaloidi")
        ]
    }
}
