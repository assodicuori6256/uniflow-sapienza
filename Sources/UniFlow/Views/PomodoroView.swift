import SwiftUI
import Combine

public enum StudyTimerMode: String, CaseIterable, Identifiable {
    case studio = "Focus Studio"
    case pausaBreve = "Pausa Breve (5 min)"
    case pausaLunga = "Pausa Relax (15 min)"
    
    public var id: String { rawValue }
    
    public var defaultDuration: Int {
        switch self {
        case .studio: return 25 * 60
        case .pausaBreve: return 5 * 60
        case .pausaLunga: return 15 * 60
        }
    }
    
    public var color: Color {
        switch self {
        case .studio: return .orange
        case .pausaBreve: return .green
        case .pausaLunga: return .blue
        }
    }
}

public class PomodoroViewModel: ObservableObject {
    @Published public var mode: StudyTimerMode = .pausaBreve
    @Published public var timeRemaining: Int = 5 * 60
    @Published public var isRunning: Bool = false
    @Published public var selectedCourseId: UUID? = nil
    @Published public var completedSessionsCount: Int = 0
    @Published public var showingAddMotivationSheet: Bool = false
    @Published public var currentMotivationIndex: Int = 0
    
    public init() {}
}

public struct PomodoroView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm = PomodoroViewModel()
    
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    private var progress: Double {
        let total = Double(vm.mode.defaultDuration)
        return 1.0 - (Double(vm.timeRemaining) / total)
    }
    
    private var timeFormatted: String {
        let minutes = vm.timeRemaining / 60
        let seconds = vm.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var activeMotivation: StudyMotivation? {
        guard !store.motivations.isEmpty else { return nil }
        let idx = vm.currentMotivationIndex % store.motivations.count
        return store.motivations[idx]
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 4) {
                    Text("Pausa & Focus Studio")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    Text("Ricarica le energie durante le pause studio per Farmacia Sapienza")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 12)
                
                // Mode Selector
                Picker("Modalità:", selection: $vm.mode) {
                    ForEach(StudyTimerMode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 420)
                .onChange(of: vm.mode) { _, newMode in
                    vm.isRunning = false
                    vm.timeRemaining = newMode.defaultDuration
                }
                
                // Main Timer & Action Section
                HStack(alignment: .center, spacing: 36) {
                    // Circular Timer
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.12), lineWidth: 14)
                            .frame(width: 220, height: 220)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                vm.mode.color,
                                style: StrokeStyle(lineWidth: 14, lineCap: .round)
                            )
                            .frame(width: 220, height: 220)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1.0), value: progress)
                        
                        VStack(spacing: 6) {
                            Text(timeFormatted)
                                .font(.system(size: 46, weight: .black, design: .rounded))
                            
                            Text(vm.mode.rawValue.uppercased())
                                .font(.caption2)
                                .fontWeight(.heavy)
                                .foregroundColor(vm.mode.color)
                            
                            if let course = store.course(for: vm.selectedCourseId) {
                                Text(course.name)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .padding(.horizontal, 8)
                            }
                        }
                    }
                    
                    // Controls Column
                    VStack(alignment: .leading, spacing: 14) {
                        Picker("Materia di riferimento:", selection: $vm.selectedCourseId) {
                            Text("Studio Generale").tag(UUID?.none)
                            ForEach(store.courses) { c in
                                Text(c.name).tag(UUID?.some(c.id))
                            }
                        }
                        .frame(width: 260)
                        
                        HStack(spacing: 12) {
                            Button(action: toggleTimer) {
                                HStack(spacing: 6) {
                                    Image(systemName: vm.isRunning ? "pause.fill" : "play.fill")
                                    Text(vm.isRunning ? "Pausa" : "Avvia")
                                }
                                .font(.headline)
                                .frame(width: 110)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(vm.mode.color)
                            .controlSize(.large)
                            
                            Button(action: resetTimer) {
                                Image(systemName: "arrow.counterclockwise")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .help("Azzera timer")
                            
                            Button(action: skipSession) {
                                Image(systemName: "forward.fill")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .help("Salta al prossimo intervallo")
                        }
                        
                        // Habit checklist for breaks
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Consigli per la Pausa:")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            Label("Bevi un bicchiere d'acqua", systemImage: "drop.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Label("Rilassa la vista dagli schemi chimici", systemImage: "eye")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Label("Stretching per collo e spalle", systemImage: "figure.walk")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
                .padding(.vertical, 8)
                
                Divider()
                    .padding(.horizontal, 24)
                
                // MOTIVAZIONI NELLE PAUSE STUDIO SECTION
                motivationsBreakSection
                    .padding(.horizontal, 24)
            }
            .padding(.vertical, 20)
        }
        .sheet(isPresented: $vm.showingAddMotivationSheet) {
            AddMotivationSheet()
                .environmentObject(store)
        }
        .onReceive(timer) { _ in
            guard vm.isRunning else { return }
            if vm.timeRemaining > 0 {
                vm.timeRemaining -= 1
            } else {
                finishTimer()
            }
        }
        .onAppear {
            if vm.selectedCourseId == nil {
                vm.selectedCourseId = store.courses.first?.id
            }
        }
    }
    
    // MARK: - Motivations Break Section
    
    private var motivationsBreakSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Motivazioni & Ispirazioni nella Pausa Studio", systemImage: "sparkles")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: {
                        withAnimation {
                            vm.currentMotivationIndex += 1
                        }
                    }) {
                        Label("Altra Frase 🎲", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        vm.showingAddMotivationSheet = true
                    }) {
                        Label("Aggiungi Motivazione", systemImage: "plus")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                }
            }
            
            // Active Motivation Card
            if let m = activeMotivation {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(m.category.uppercased())
                            .font(.system(size: 10, weight: .heavy))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.purple.opacity(0.12))
                            .foregroundColor(.purple)
                            .clipShape(Capsule())
                        
                        Spacer()
                        
                        Text("— \(m.author)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("“\(m.text)”")
                        .font(.system(size: 17, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(.primary)
                        .padding(.vertical, 4)
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
            
            // List of student's personal & course motivations
            VStack(alignment: .leading, spacing: 10) {
                Text("Tutte le tue motivazioni salvate (\(store.motivations.count)):")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                LazyVStack(spacing: 8) {
                    ForEach(store.motivations) { motivation in
                        HStack(spacing: 12) {
                            Image(systemName: "quote.bubble.fill")
                                .foregroundColor(.purple.opacity(0.8))
                                .font(.caption)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(motivation.text)
                                    .font(.subheadline)
                                    .lineLimit(2)
                                HStack(spacing: 6) {
                                    Text(motivation.category)
                                        .font(.caption2)
                                        .foregroundColor(.purple)
                                    Text("•")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(motivation.author)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button(role: .destructive, action: {
                                store.deleteMotivation(id: motivation.id)
                            }) {
                                Image(systemName: "trash")
                                    .font(.caption2)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                            .help("Elimina motivazione")
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleTimer() {
        vm.isRunning.toggle()
    }
    
    private func resetTimer() {
        vm.isRunning = false
        vm.timeRemaining = vm.mode.defaultDuration
    }
    
    private func skipSession() {
        vm.isRunning = false
        if vm.mode == .studio {
            vm.completedSessionsCount += 1
            store.recordStudySession(courseId: vm.selectedCourseId, minutes: 25)
            vm.mode = (vm.completedSessionsCount % 4 == 0) ? .pausaLunga : .pausaBreve
            vm.currentMotivationIndex += 1 // Next motivation on break!
        } else {
            vm.mode = .studio
        }
        vm.timeRemaining = vm.mode.defaultDuration
    }
    
    private func finishTimer() {
        NSSound.beep()
        skipSession()
    }
}

// MARK: - Add Motivation Sheet
public class AddMotivationViewModel: ObservableObject {
    @Published public var text: String = ""
    @Published public var category: String = "Farmacia"
    @Published public var author: String = "Studente Sapienza"
    
    public init() {}
}

public struct AddMotivationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm = AddMotivationViewModel()
    
    let categories = ["Farmacia", "Traguardo Laurea", "Relax & Benessere", "Sapienza Life", "Personale"]
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 18) {
            Text("Aggiungi Nuova Motivazione per le Pause")
                .font(.headline)
            
            Text("Scrivi una frase che ti dia la carica per superare i tuoi esami di Farmacia.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Form {
                VStack(alignment: .leading, spacing: 4) {
                    Text("La tua frase o obiettivo:")
                        .font(.subheadline)
                    TextEditor(text: $vm.text)
                        .font(.body)
                        .frame(height: 80)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                }
                
                Picker("Categoria:", selection: $vm.category) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
                
                TextField("Autore o fonte (es. Promemoria personale, Prof...):", text: $vm.author)
            }
            .padding()
            
            HStack {
                Button("Annulla") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                
                Button("Salva Motivazione") {
                    guard !vm.text.isEmpty else { return }
                    let newMotivation = StudyMotivation(
                        text: vm.text,
                        category: vm.category,
                        author: vm.author.isEmpty ? "Personale" : vm.author,
                        isFavorite: true
                    )
                    store.addMotivation(newMotivation)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(vm.text.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 450)
    }
}
