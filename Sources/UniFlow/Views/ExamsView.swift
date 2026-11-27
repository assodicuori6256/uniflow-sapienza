import SwiftUI

public class ExamsViewModel: ObservableObject {
    @Published public var filterStatus: String = "Tutti"
    @Published public var showingAddExamSheet: Bool = false
    @Published public var simulatedThesisPoints: Double = 5.0
    @Published public var includeLaudeBonus: Bool = true
    
    public init() {}
}

public struct ExamsView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm = ExamsViewModel()
    
    public init() {}
    
    private var filteredExams: [Exam] {
        switch vm.filterStatus {
        case "Superati":
            return store.exams.filter { $0.status == .superato || $0.status == .verbalizzato }
        case "Da sostenere":
            return store.exams.filter { $0.status == .daSostenere || $0.status == .pianificato }
        default:
            return store.exams
        }
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Libretto & Simulatore Laurea")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                        Text("Monitora la tua carriera universitaria, calcola la media e simula il voto finale")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { vm.showingAddExamSheet = true }) {
                        Label("Registra Esame / Appello", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // Stat KPI Cards
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ], spacing: 14) {
                    StatCard(
                        title: "Media Ponderata",
                        value: store.weightedGPA > 0 ? String(format: "%.2f", store.weightedGPA) : "—",
                        subtitle: "Pesata sui crediti CFU",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Media Aritmetica",
                        value: store.arithmeticGPA > 0 ? String(format: "%.2f", store.arithmeticGPA) : "—",
                        subtitle: "\(store.passedExams.count) esami superati",
                        icon: "percent",
                        color: .teal
                    )
                    
                    StatCard(
                        title: "Progresso CFU",
                        value: "\(store.totalPassedCFU) / \(store.settings.totalDegreeCFU)",
                        subtitle: "\(store.remainingCFU) CFU alla tesi",
                        icon: "graduationcap.fill",
                        color: .purple
                    )
                    
                    StatCard(
                        title: "Lodi Accademiche",
                        value: "\(store.laudeCount)",
                        subtitle: store.laudeCount > 0 ? "Ottimo curriculum!" : "Nessuna lode",
                        icon: "star.fill",
                        color: .yellow
                    )
                }
                
                // Graduation Simulator Interactive Panel
                graduationSimulatorSection
                
                // Exams Table Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Elenco Esami del Piano di Studi")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Picker("Filtra per stato:", selection: $vm.filterStatus) {
                            Text("Tutti (\(store.exams.count))").tag("Tutti")
                            Text("Superati (\(store.passedExams.count))").tag("Superati")
                            Text("Da sostenere (\(store.exams.count - store.passedExams.count))").tag("Da sostenere")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 320)
                    }
                    
                    if filteredExams.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "folder.badge.questionmark")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Nessun esame trovato per questo filtro.")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(filteredExams) { exam in
                                examRow(exam: exam)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $vm.showingAddExamSheet) {
            AddExamSheet()
                .environmentObject(store)
        }
    }
    
    // MARK: - Graduation Simulator
    
    private var graduationSimulatorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Simulatore Voto di Laurea", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundColor(.purple)
                
                Spacer()
                
                Text("Formula: (Media Ponderata × 110) / 30 + Punti Tesi")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 24) {
                // Interactive Sliders
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Punti Tesi Stimati (Commissione):")
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "+%.1f punti", vm.simulatedThesisPoints))
                                .font(.headline)
                                .foregroundColor(.purple)
                        }
                        Slider(value: $vm.simulatedThesisPoints, in: 0...10, step: 0.5)
                            .tint(.purple)
                    }
                    
                    Toggle(isOn: $vm.includeLaudeBonus) {
                        HStack {
                            Text("Includi Bonus Lodi (\(store.laudeCount) lodi × \(String(format: "%.2f", store.settings.laudeBonusPoints)) pt)")
                                .font(.subheadline)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                // Calculated Result Preview
                let base = store.graduationBaseScore
                let laudeBonus = vm.includeLaudeBonus ? Double(store.laudeCount) * store.settings.laudeBonusPoints : 0
                let totalEstimated = min(110.0, base + vm.simulatedThesisPoints + laudeBonus)
                let isLaudeEligible = totalEstimated >= 110.0 && store.laudeCount >= 1
                
                VStack(alignment: .center, spacing: 6) {
                    Text("VOTO DI LAUREA PREVISTO")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(base > 0 ? String(format: "%.1f", totalEstimated) : "—")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundColor(.purple)
                        
                        Text("/ 110")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    if isLaudeEligible {
                        Label("Possibile 110 e Lode 🎓✨", systemImage: "rosette")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow.opacity(0.15))
                            .clipShape(Capsule())
                    } else {
                        Text("Base di partenza: \(String(format: "%.2f", base)) / 110")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 220)
                .padding()
                .background(Color.purple.opacity(0.06))
                .cornerRadius(12)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.purple.opacity(0.25), lineWidth: 1.5)
                )
        )
    }
    
    // MARK: - Exam Row
    
    private func examRow(exam: Exam) -> some View {
        let course = store.course(for: exam.courseId)
        
        return HStack(spacing: 16) {
            // Grade badge
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(exam.status == .superato || exam.status == .verbalizzato ? (exam.isLaude ? Color.yellow.opacity(0.2) : Color.green.opacity(0.15)) : Color.secondary.opacity(0.1))
                    .frame(width: 52, height: 52)
                
                VStack(spacing: 1) {
                    Text(exam.gradeDisplay)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(exam.isLaude ? .orange : (exam.grade != nil ? .primary : .secondary))
                    
                    Text("\(exam.cfu) CFU")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            
            // Course details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(course?.name ?? "Insegnamento non specificato")
                        .font(.headline)
                    
                    if let code = course?.code, !code.isEmpty {
                        Text(code)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 12) {
                    ExamStatusBadge(exam.status)
                    
                    if let date = exam.examDate {
                        Label(dateFormatter.string(from: date), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !exam.notes.isEmpty {
                        Text(exam.notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 10) {
                Button(role: .destructive, action: {
                    store.deleteExam(id: exam.id)
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .help("Elimina esame")
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateStyle = .medium
        return f
    }
}

// MARK: - Add Exam ViewModel & Sheet
public class AddExamViewModel: ObservableObject {
    @Published public var selectedCourseId: UUID = UUID()
    @Published public var grade: Int = 28
    @Published public var isLaude: Bool = false
    @Published public var cfu: Int = 6
    @Published public var status: ExamStatus = .superato
    @Published public var hasGrade: Bool = true
    @Published public var examDate: Date = Date()
    @Published public var notes: String = ""
    
    public init() {}
}

public struct AddExamSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm = AddExamViewModel()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 18) {
            Text("Registra Esame o Appello")
                .font(.headline)
            
            Form {
                Picker("Insegnamento / Corso:", selection: $vm.selectedCourseId) {
                    ForEach(store.courses) { course in
                        Text(course.name).tag(course.id)
                    }
                }
                .onChange(of: vm.selectedCourseId) { newId in
                    if let c = store.course(for: newId) {
                        vm.cfu = c.cfu
                    }
                }
                
                Picker("Stato:", selection: $vm.status) {
                    ForEach(ExamStatus.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                
                Stepper("Crediti: \(vm.cfu) CFU", value: $vm.cfu, in: 1...30)
                
                DatePicker("Data Appello / Verbalizzazione:", selection: $vm.examDate, displayedComponents: .date)
                
                if vm.status == .superato || vm.status == .verbalizzato {
                    Toggle("Assegna Voto", isOn: $vm.hasGrade)
                    
                    if vm.hasGrade {
                        Stepper("Voto: \(vm.grade)/30", value: $vm.grade, in: 18...30)
                        
                        if vm.grade == 30 {
                            Toggle("Con Lode (30 e Lode)", isOn: $vm.isLaude)
                        }
                    }
                }
                
                TextField("Note (es. voto scritto/orale, commissione):", text: $vm.notes)
            }
            .padding()
            
            HStack {
                Button("Annulla") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                
                Button("Salva nel Libretto") {
                    let newExam = Exam(
                        courseId: vm.selectedCourseId,
                        examDate: vm.examDate,
                        grade: (vm.status == .superato || vm.status == .verbalizzato) && vm.hasGrade ? vm.grade : nil,
                        isLaude: vm.isLaude,
                        cfu: vm.cfu,
                        status: vm.status,
                        notes: vm.notes
                    )
                    store.addExam(newExam)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 440)
        .onAppear {
            if let first = store.courses.first {
                vm.selectedCourseId = first.id
                vm.cfu = first.cfu
            }
        }
    }
}
