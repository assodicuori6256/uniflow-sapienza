import SwiftUI

public class OnboardingViewModel: ObservableObject {
    @Published public var currentStep: Int = 1
    
    // Step 1: Personal
    @Published public var studentName: String = "Studente Sapienza"
    @Published public var universityName: String = "Sapienza Università di Roma"
    
    // Step 2: Degree & CFU
    @Published public var degreeCourse: String = "Farmacia (Ciclo Unico LM-13)"
    @Published public var selectedDegreeType: String = "Ciclo Unico (5a)"
    @Published public var totalCFU: Int = 300
    
    // Step 3: Habits & Commute
    @Published public var isCommuter: Bool = true
    @Published public var primaryTransport: String = "Metro B"
    @Published public var targetGraduationGrade: Int = 110
    @Published public var dailyStudyHours: Double = 4.5
    
    public init() {}
}

public struct OnboardingView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm = OnboardingViewModel()
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // macOS Background Blur & Style
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Progress Indicator
                topProgressHeader
                    .padding(.top, 24)
                    .padding(.horizontal, 36)
                    .padding(.bottom, 16)
                
                Divider()
                
                // Step Content in ScrollView with generous padding
                ScrollView {
                    VStack(spacing: 24) {
                        switch vm.currentStep {
                        case 1:
                            stepOneProfile
                        case 2:
                            stepTwoDegree
                        case 3:
                            stepThreeCommuteAndGoals
                        case 4:
                            stepFourSummary
                        default:
                            stepOneProfile
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    .padding(.bottom, 36)
                    .frame(maxWidth: 620)
                }
                
                Divider()
                
                // Bottom Navigation Buttons
                bottomNavigationButtons
                    .padding(.horizontal, 36)
                    .padding(.vertical, 16)
                    .background(Color(NSColor.controlBackgroundColor))
            }
        }
        #if os(macOS)
        .frame(minWidth: 720, minHeight: 650)
        #endif
        .onAppear {
            if !store.settings.studentName.isEmpty {
                vm.studentName = store.settings.studentName
            }
            if !store.settings.universityName.isEmpty {
                vm.universityName = store.settings.universityName
            }
            if !store.settings.degreeCourse.isEmpty {
                vm.degreeCourse = store.settings.degreeCourse
            }
            vm.totalCFU = store.settings.totalDegreeCFU > 0 ? store.settings.totalDegreeCFU : 300
        }
    }
    
    // MARK: - Top Header & Step Progress
    
    private var topProgressHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(width: 44, height: 44)
                    .cornerRadius(12)
                Image(systemName: "cross.vial.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Benvenuto in UniFlow")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("• Sapienza Farmacia")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.12))
                        .foregroundColor(.red)
                        .cornerRadius(6)
                }
                
                Text("Configuriamo insieme il tuo percorso di studi (Passo \(vm.currentStep) di 4)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Step indicator pills
            HStack(spacing: 8) {
                ForEach(1...4, id: \.self) { step in
                    Circle()
                        .fill(vm.currentStep >= step ? Color.blue : Color.secondary.opacity(0.2))
                        .frame(width: 10, height: 10)
                }
            }
        }
    }
    
    // MARK: - Step 1: Personal Profile
    
    private var stepOneProfile: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("1. Chi sei?")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Inserisci il tuo nome e conferma il tuo ateneo di riferimento.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Il tuo nome e cognome")
                        .font(.headline)
                    TextField("es. Mario Rossi", text: $vm.studentName)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Università / Facoltà")
                        .font(.headline)
                    TextField("Ateneo", text: $vm.universityName)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                }
                
                // Suggested universities
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ateneo pre-impostato:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Button(action: { vm.universityName = "Sapienza Università di Roma" }) {
                            Label("Sapienza Roma (Consigliato)", systemImage: "building.columns.fill")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red.opacity(0.8))
                        
                        Button(action: { vm.universityName = "Tor Vergata" }) {
                            Text("Tor Vergata")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(14)
        }
    }
    
    // MARK: - Step 2: Degree & CFU
    
    private var stepTwoDegree: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("2. Corso di Laurea in Farmacia")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Il corso a ciclo unico in Farmacia (LM-13) prevede 300 CFU comprensivi di tirocinio professionale.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Corso di Laurea")
                        .font(.headline)
                    TextField("es. Farmacia (Ciclo Unico LM-13)", text: $vm.degreeCourse)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tipologia di Percorso:")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        degreeTypeCard(title: "Farmacia (Ciclo Unico)", cfu: 300, subtitle: "5 Anni • LM-13")
                        degreeTypeCard(title: "CTF (Chimica e Tecn.)", cfu: 300, subtitle: "5 Anni • LM-13")
                        degreeTypeCard(title: "Scienze Farmaceutiche", cfu: 180, subtitle: "Triennale • L-29")
                        degreeTypeCard(title: "Personalizzato", cfu: vm.totalCFU, subtitle: "CFU a scelta")
                    }
                }
                
                HStack {
                    Text("Crediti Formativi Totali (CFU):")
                        .font(.subheadline)
                    Spacer()
                    Stepper("\(vm.totalCFU) CFU", value: $vm.totalCFU, in: 60...400, step: 10)
                        .font(.headline)
                }
                .padding(.top, 4)
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(14)
        }
    }
    
    private func degreeTypeCard(title: String, cfu: Int, subtitle: String) -> some View {
        let isSelected = vm.selectedDegreeType == title
        
        return Button(action: {
            vm.selectedDegreeType = title
            vm.totalCFU = cfu
        }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                Text("\(cfu) CFU • \(subtitle)")
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.blue.opacity(0.12) : Color.primary.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
            )
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Step 3: Commute & Goals (Fixed & Unbugged)
    
    private var stepThreeCommuteAndGoals: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("3. Pendolarismo verso la Sapienza & Obiettivi")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Raggiungi la Città Universitaria (Piazzale Aldo Moro / Regina Elena) sempre in orario.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 18) {
                // Commuter toggle
                Toggle(isOn: $vm.isCommuter) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sei uno studente pendolare?")
                            .font(.headline)
                        Text("Abilita il calcolo automatico dell'orario di partenza in base a Metro, Bus e Treni.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if vm.isCommuter {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Come raggiungi la Sapienza?")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        // Clean, flexible grid of transport cards that NEVER clip
                        let transitOptions = [
                            ("Metro B (Policlinico)", "tram.tunnel.fill"),
                            ("Tram 3 o 19 (Regina Elena)", "tram.fill"),
                            ("Bus 310 / 492 / Linee Atac", "bus.fill"),
                            ("Treno Regionale (FL1/FL2)", "train.side.front.car"),
                            ("Automobile / Scooter", "car.fill"),
                            ("A piedi / Bici", "bicycle")
                        ]
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(transitOptions, id: \.0) { option in
                                let isSelected = vm.primaryTransport == option.0
                                Button(action: {
                                    vm.primaryTransport = option.0
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: option.1)
                                            .foregroundColor(isSelected ? .blue : .secondary)
                                            .font(.system(size: 14))
                                        
                                        Text(option.0)
                                            .font(.caption)
                                            .fontWeight(isSelected ? .bold : .regular)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 9)
                                    .background(isSelected ? Color.blue.opacity(0.12) : Color.primary.opacity(0.04))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Target Grade Slider
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Voto di Laurea desiderato:")
                            .font(.headline)
                        Spacer()
                        Text("\(vm.targetGraduationGrade)/110")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    }
                    Slider(value: Binding(
                        get: { Double(vm.targetGraduationGrade) },
                        set: { vm.targetGraduationGrade = Int($0) }
                    ), in: 66...110, step: 1)
                    .tint(.purple)
                }
                
                // Daily Study Goal
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Obiettivo studio giornaliero:")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f ore/giorno", vm.dailyStudyHours))
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    Slider(value: $vm.dailyStudyHours, in: 1.0...10.0, step: 0.5)
                        .tint(.orange)
                }
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(14)
        }
    }
    
    // MARK: - Step 4: Summary
    
    private var stepFourSummary: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("4. Pronto per Iniziare! 🎓")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Ecco il riepilogo del tuo profilo accademico per Farmacia Sapienza.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                summaryRow(icon: "person.fill", title: "Studente", value: vm.studentName.isEmpty ? "Studente Farmacia" : vm.studentName, color: .blue)
                summaryRow(icon: "building.columns.fill", title: "Ateneo", value: vm.universityName.isEmpty ? "Sapienza Università di Roma" : vm.universityName, color: .red)
                summaryRow(icon: "cross.vial.fill", title: "Corso", value: "\(vm.degreeCourse) (\(vm.totalCFU) CFU)", color: .purple)
                summaryRow(icon: "tram.fill", title: "Mobilità", value: vm.isCommuter ? "Pendolare (\(vm.primaryTransport))" : "In sede a Roma", color: .green)
                summaryRow(icon: "star.fill", title: "Target Laurea", value: "\(vm.targetGraduationGrade) / 110", color: .yellow)
                summaryRow(icon: "cup.and.saucer.fill", title: "Studio & Pause", value: "\(String(format: "%.1f", vm.dailyStudyHours)) ore/giorno", color: .orange)
            }
            .padding(18)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(14)
            
            HStack(spacing: 6) {
                Text("UniFlow sviluppato da Aldo Cuko (aldo.superiori@gmail.com)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                if let url = URL(string: "https://github.com/assodicuori6256/uniflow-sapienza") {
                    Link("• GitHub", destination: url)
                        .font(.caption2)
                }
            }
        }
    }
    
    private func summaryRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
        }
    }
    
    // MARK: - Bottom Buttons
    
    private var bottomNavigationButtons: some View {
        HStack {
            if vm.currentStep > 1 {
                Button("Indietro") {
                    withAnimation {
                        vm.currentStep -= 1
                    }
                }
                .buttonStyle(.bordered)
            } else {
                Button("Salta per ora") {
                    store.settings.hasCompletedOnboarding = true
                    store.saveData()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if vm.currentStep < 4 {
                Button("Avanti") {
                    withAnimation {
                        vm.currentStep += 1
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            } else {
                Button("Inizia con Farmacia Sapienza 🚀") {
                    let finalName = vm.studentName.isEmpty ? "Studente Sapienza" : vm.studentName
                    let finalUni = vm.universityName.isEmpty ? "Sapienza Università di Roma" : vm.universityName
                    let finalDegree = vm.degreeCourse.isEmpty ? "Farmacia (Ciclo Unico LM-13)" : vm.degreeCourse
                    
                    store.completeOnboarding(
                        studentName: finalName,
                        universityName: finalUni,
                        degreeCourse: finalDegree,
                        totalCFU: vm.totalCFU,
                        targetGrade: vm.targetGraduationGrade,
                        isCommuter: vm.isCommuter,
                        primaryTransport: vm.primaryTransport,
                        dailyHours: vm.dailyStudyHours
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
        }
    }
}
