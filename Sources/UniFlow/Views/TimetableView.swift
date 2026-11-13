import SwiftUI

public class TimetableViewModel: ObservableObject {
    @Published public var selectedDay: Int = 1 // 1 = Lun, ..., 6 = Sab
    @Published public var showingAddLessonSheet: Bool = false
    @Published public var showingAddCourseSheet: Bool = false
    
    public init() {}
}

public struct TimetableView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm = TimetableViewModel()
    
    let days = [
        (1, "Lunedì"),
        (2, "Martedì"),
        (3, "Mercoledì"),
        (4, "Giovedì"),
        (5, "Venerdì"),
        (6, "Sabato")
    ]
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Orario & Lezioni")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    Text("Pianifica la tua frequenza, aule e orari settimanali")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 10) {
                    Button(action: { vm.showingAddCourseSheet = true }) {
                        Label("Nuovo Corso", systemImage: "folder.badge.plus")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { vm.showingAddLessonSheet = true }) {
                        Label("Aggiungi Lezione", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Day Selector Picker
            HStack(spacing: 8) {
                ForEach(days, id: \.0) { day in
                    let isSelected = vm.selectedDay == day.0
                    let lessonCount = store.lessons(forDay: day.0).count
                    
                    Button(action: {
                        vm.selectedDay = day.0
                    }) {
                        VStack(spacing: 4) {
                            Text(day.1)
                                .font(.subheadline)
                                .fontWeight(isSelected ? .bold : .medium)
                            
                            Text("\(lessonCount) lezioni")
                                .font(.caption2)
                                .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.blue : Color(NSColor.controlBackgroundColor))
                        .foregroundColor(isSelected ? .white : .primary)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            Divider()
            
            // Lessons list for selected day
            ScrollView {
                let currentDayLessons = store.lessons(forDay: vm.selectedDay)
                
                if currentDayLessons.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("Nessuna lezione programmata per questo giorno")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Button("Aggiungi la prima lezione") {
                            vm.showingAddLessonSheet = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(currentDayLessons, id: \.lesson.id) { item in
                            lessonCard(item: item)
                        }
                    }
                    .padding(24)
                }
            }
        }
        .sheet(isPresented: $vm.showingAddLessonSheet) {
            AddLessonSheet(selectedDay: vm.selectedDay)
                .environmentObject(store)
        }
        .sheet(isPresented: $vm.showingAddCourseSheet) {
            AddCourseSheet()
                .environmentObject(store)
        }
    }
    
    private func lessonCard(item: (lesson: Lesson, course: Course)) -> some View {
        let lesson = item.lesson
        let course = item.course
        
        return HStack(spacing: 16) {
            // Time Column
            VStack(alignment: .center, spacing: 4) {
                Text(String(format: "%02d:%02d", lesson.startHour, lesson.startMinute))
                    .font(.headline)
                    .fontWeight(.bold)
                Text("↓")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%02d:%02d", lesson.endHour, lesson.endMinute))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                Text("\(lesson.durationMinutes) min")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            .frame(width: 75)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(8)
            
            // Color pill
            Rectangle()
                .fill(course.color)
                .frame(width: 5)
                .cornerRadius(2.5)
            
            // Course & Location info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(course.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    if !course.code.isEmpty {
                        Text(course.code)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    if course.attendanceRequired {
                        Label("Frequenza Obbligatoria", systemImage: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                
                HStack(spacing: 16) {
                    Label(lesson.room.isEmpty ? "Aula da definire" : lesson.room, systemImage: "mappin.circle.fill")
                    if !lesson.building.isEmpty {
                        Label(lesson.building, systemImage: "building.2.crop.circle")
                    }
                    if !course.professor.isEmpty {
                        Label(course.professor, systemImage: "person.circle")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                if !lesson.notes.isEmpty {
                    Text(lesson.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Actions
            VStack(spacing: 8) {
                if !course.onlineLink.isEmpty, let url = URL(string: course.onlineLink) {
                    Link(destination: url) {
                        HStack(spacing: 4) {
                            Image(systemName: "video.fill")
                            Text("Aula Virtuale")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                
                Button(role: .destructive, action: {
                    store.deleteLesson(id: lesson.id)
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .help("Elimina lezione")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.03), radius: 2, y: 1)
        )
    }
}

// MARK: - Add Lesson ViewModel & Sheet
public class AddLessonViewModel: ObservableObject {
    @Published public var selectedCourseId: UUID = UUID()
    @Published public var selectedDay: Int = 1
    @Published public var startHour: Int = 9
    @Published public var startMinute: Int = 0
    @Published public var endHour: Int = 11
    @Published public var endMinute: Int = 0
    @Published public var room: String = ""
    @Published public var building: String = ""
    @Published public var notes: String = ""
    
    public init(selectedDay: Int = 1) {
        self.selectedDay = selectedDay
    }
}

public struct AddLessonSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm: AddLessonViewModel
    
    public init(selectedDay: Int = 1) {
        _vm = StateObject(wrappedValue: AddLessonViewModel(selectedDay: selectedDay))
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("Aggiungi Lezione")
                .font(.headline)
            
            Form {
                Picker("Corso:", selection: $vm.selectedCourseId) {
                    ForEach(store.courses) { course in
                        Text(course.name).tag(course.id)
                    }
                }
                
                Picker("Giorno:", selection: $vm.selectedDay) {
                    Text("Lunedì").tag(1)
                    Text("Martedì").tag(2)
                    Text("Mercoledì").tag(3)
                    Text("Giovedì").tag(4)
                    Text("Venerdì").tag(5)
                    Text("Sabato").tag(6)
                }
                
                HStack {
                    Text("Inizio:")
                    Stepper("\(String(format: "%02d", vm.startHour)):\(String(format: "%02d", vm.startMinute))", onIncrement: {
                        if vm.startHour < 22 { vm.startHour += 1 }
                    }, onDecrement: {
                        if vm.startHour > 7 { vm.startHour -= 1 }
                    })
                }
                
                HStack {
                    Text("Fine:")
                    Stepper("\(String(format: "%02d", vm.endHour)):\(String(format: "%02d", vm.endMinute))", onIncrement: {
                        if vm.endHour < 23 { vm.endHour += 1 }
                    }, onDecrement: {
                        if vm.endHour > vm.startHour { vm.endHour -= 1 }
                    })
                }
                
                TextField("Aula (es. Aula 3):", text: $vm.room)
                TextField("Edificio (es. Edificio B):", text: $vm.building)
                TextField("Note aggiuntive:", text: $vm.notes)
            }
            .padding()
            
            HStack {
                Button("Annulla") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                
                Button("Salva Lezione") {
                    let newLesson = Lesson(
                        courseId: vm.selectedCourseId,
                        dayOfWeek: vm.selectedDay,
                        startHour: vm.startHour,
                        startMinute: vm.startMinute,
                        endHour: vm.endHour,
                        endMinute: vm.endMinute,
                        room: vm.room,
                        building: vm.building,
                        notes: vm.notes
                    )
                    store.addLesson(newLesson)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear {
            if let first = store.courses.first {
                vm.selectedCourseId = first.id
                vm.room = first.classroomDefault
            }
        }
    }
}

// MARK: - Add Course ViewModel & Sheet
public class AddCourseViewModel: ObservableObject {
    @Published public var name: String = ""
    @Published public var code: String = ""
    @Published public var cfu: Int = 6
    @Published public var professor: String = ""
    @Published public var professorEmail: String = ""
    @Published public var classroomDefault: String = ""
    @Published public var onlineLink: String = ""
    @Published public var semester: String = "1° Semestre"
    @Published public var attendanceRequired: Bool = false
    @Published public var colorHex: String = "#0A84FF"
    
    public init() {}
}

public struct AddCourseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm = AddCourseViewModel()
    
    let colors = ["#007AFF", "#34C759", "#FF9500", "#FF2D55", "#AF52DE", "#5856D6", "#30B0C7", "#A2845E"]
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 18) {
            Text("Nuovo Corso / Insegnamento")
                .font(.headline)
            
            Form {
                TextField("Nome Corso (es. Reti di Calcolatori):", text: $vm.name)
                TextField("Codice Insegnamento (es. INF-08):", text: $vm.code)
                
                Stepper("Crediti Formativi: \(vm.cfu) CFU", value: $vm.cfu, in: 1...30)
                
                TextField("Docente:", text: $vm.professor)
                TextField("Email Docente:", text: $vm.professorEmail)
                TextField("Aula di Riferimento:", text: $vm.classroomDefault)
                TextField("Link Teams / Meet:", text: $vm.onlineLink)
                
                Picker("Semestre:", selection: $vm.semester) {
                    Text("1° Semestre").tag("1° Semestre")
                    Text("2° Semestre").tag("2° Semestre")
                    Text("Annuale").tag("Annuale")
                }
                
                Toggle("Frequenza Obbligatoria", isOn: $vm.attendanceRequired)
                
                // Color selector
                HStack {
                    Text("Colore identificativo:")
                    Spacer()
                    ForEach(colors, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: vm.colorHex == hex ? 2 : 0)
                            )
                            .onTapGesture {
                                vm.colorHex = hex
                            }
                    }
                }
            }
            .padding()
            
            HStack {
                Button("Annulla") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                
                Button("Crea Corso") {
                    guard !vm.name.isEmpty else { return }
                    let newCourse = Course(
                        code: vm.code,
                        name: vm.name,
                        cfu: vm.cfu,
                        professor: vm.professor,
                        professorEmail: vm.professorEmail,
                        colorHex: vm.colorHex,
                        semester: vm.semester,
                        classroomDefault: vm.classroomDefault,
                        onlineLink: vm.onlineLink,
                        attendanceRequired: vm.attendanceRequired
                    )
                    store.addCourse(newCourse)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.name.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 460)
    }
}
