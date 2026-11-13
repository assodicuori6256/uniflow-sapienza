import SwiftUI

public class CommuteViewModel: ObservableObject {
    @Published public var showingAddRouteSheet: Bool = false
    @Published public var showingAddBusSheet: Bool = false
    @Published public var selectedFilter: String = "Tutti"
    
    // Calculator selection
    @Published public var selectedLessonForCalcId: UUID? = nil
    @Published public var calcTransitMode: String = "Tratta" // "Tratta" o "Bus"
    @Published public var selectedRouteForCalcId: UUID? = nil
    @Published public var selectedBusForCalcId: UUID? = nil
    
    public init() {}
}

public struct CommuteView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm = CommuteViewModel()
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Top Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trasporti & Pendolarismo")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                        Text("Gestisci tratte, treni e linee autobus manualmente per raggiungere le lezioni")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 10) {
                        Button(action: { vm.showingAddBusSheet = true }) {
                            Label("Aggiungi Autobus", systemImage: "bus.fill")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: { vm.showingAddRouteSheet = true }) {
                            Label("Aggiungi Tratta", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                // Smart Departure Calculator
                departureCalculatorSection
                
                // Filter Tabs
                HStack {
                    Picker("Visualizza:", selection: $vm.selectedFilter) {
                        Text("Tutti i Mezzi (\(store.commuteRoutes.count + store.busLines.count))").tag("Tutti")
                        Text("Tratte Pendolari (\(store.commuteRoutes.count))").tag("Tratte")
                        Text("Linee Autobus & Navette (\(store.busLines.count))").tag("Bus")
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 440)
                    
                    Spacer()
                }
                
                // Content based on filter
                if vm.selectedFilter == "Tutti" || vm.selectedFilter == "Tratte" {
                    routesSection
                }
                
                if vm.selectedFilter == "Tutti" || vm.selectedFilter == "Bus" {
                    busLinesSection
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $vm.showingAddRouteSheet) {
            AddCommuteRouteSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $vm.showingAddBusSheet) {
            AddBusLineSheet()
                .environmentObject(store)
        }
        .onAppear {
            if vm.selectedLessonForCalcId == nil, let first = store.todayLessons.first?.lesson {
                vm.selectedLessonForCalcId = first.id
            }
            if vm.selectedRouteForCalcId == nil, let first = store.commuteRoutes.first {
                vm.selectedRouteForCalcId = first.id
            }
            if vm.selectedBusForCalcId == nil, let first = store.busLines.first {
                vm.selectedBusForCalcId = first.id
            }
        }
    }
    
    // MARK: - Smart Departure Calculator
    
    private var departureCalculatorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Calcolatore Orario di Partenza Intelligente", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
                Text("Arriva in aula puntuale e senza stress")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                // Controls
                VStack(alignment: .leading, spacing: 12) {
                    // Pick Today's Lesson
                    Picker("Lezione di destinazione:", selection: $vm.selectedLessonForCalcId) {
                        Text("Seleziona una lezione...").tag(UUID?.none)
                        ForEach(store.todayLessons, id: \.lesson.id) { item in
                            Text("\(item.course.name) (\(item.lesson.timeRangeString))").tag(UUID?.some(item.lesson.id))
                        }
                    }
                    
                    // Choose between Route and Bus
                    Picker("Tipo di mezzo:", selection: $vm.calcTransitMode) {
                        Text("Tratta Pendolare").tag("Tratta")
                        Text("Linea Autobus / Navetta").tag("Bus")
                    }
                    .pickerStyle(.segmented)
                    
                    if vm.calcTransitMode == "Tratta" {
                        Picker("Tratta da percorrere:", selection: $vm.selectedRouteForCalcId) {
                            Text("Seleziona tratta...").tag(UUID?.none)
                            ForEach(store.commuteRoutes) { route in
                                Text("\(route.name) (\(route.origin) → \(route.destination))").tag(UUID?.some(route.id))
                            }
                        }
                    } else {
                        Picker("Autobus da prendere:", selection: $vm.selectedBusForCalcId) {
                            Text("Seleziona bus...").tag(UUID?.none)
                            ForEach(store.busLines) { bus in
                                Text("\(bus.lineNumber) (\(bus.departureStop) → \(bus.arrivalStop))").tag(UUID?.some(bus.id))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                // Result Computation
                if let info = departureInfo() {
                    VStack(alignment: .center, spacing: 4) {
                        Text("ORA DI PARTENZA CONSIGLIATA")
                            .font(.caption2)
                            .fontWeight(.heavy)
                            .foregroundColor(.secondary)
                        
                        Text(info.time)
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(.blue)
                        
                        Text(info.label)
                            .font(.caption)
                            .fontWeight(.bold)
                            .lineLimit(1)
                        
                        Text("(\(info.travel) min viaggio + \(info.buffer) min margine)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 230)
                    .padding()
                    .background(Color.blue.opacity(0.06))
                    .cornerRadius(12)
                } else {
                    VStack {
                        Text("Seleziona una lezione e un mezzo per calcolare la partenza")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 230)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1.5)
                )
        )
    }
    
    private func departureInfo() -> (time: String, label: String, travel: Int, buffer: Int)? {
        guard let lessonId = vm.selectedLessonForCalcId,
              let lesson = store.lessons.first(where: { $0.id == lessonId }) else {
            return nil
        }
        
        let lessonStartMinutes = lesson.startHour * 60 + lesson.startMinute
        let travel: Int
        let buffer: Int
        let label: String
        
        if vm.calcTransitMode == "Tratta" {
            guard let routeId = vm.selectedRouteForCalcId,
                  let route = store.commuteRoutes.first(where: { $0.id == routeId }) else {
                return nil
            }
            travel = route.typicalDurationMinutes
            buffer = route.bufferMinutes
            label = route.name
        } else {
            guard let busId = vm.selectedBusForCalcId,
                  let bus = store.busLines.first(where: { $0.id == busId }) else {
                return nil
            }
            travel = bus.travelDurationMinutes
            buffer = bus.bufferMinutes
            label = bus.lineNumber
        }
        
        let totalNeeded = travel + buffer
        let departureMinutes = max(0, lessonStartMinutes - totalNeeded)
        let depHour = departureMinutes / 60
        let depMin = departureMinutes % 60
        let timeStr = String(format: "%02d:%02d", depHour, depMin)
        return (timeStr, label, travel, buffer)
    }
    
    // MARK: - Commute Routes Section
    
    private var routesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Tratte Pendolari Principali", systemImage: "tram.fill")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { vm.showingAddRouteSheet = true }) {
                    Label("Nuova Tratta", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            
            if store.commuteRoutes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tram")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Nessuna tratta registrata.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 90)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(store.commuteRoutes) { route in
                        routeCard(route: route)
                    }
                }
            }
        }
    }
    
    // MARK: - Bus Lines Section
    
    private var busLinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Linee Autobus & Navette Campus", systemImage: "bus.fill")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { vm.showingAddBusSheet = true }) {
                    Label("Aggiungi Bus Manualmente", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            
            if store.busLines.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bus")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Nessuna linea bus inserita. Aggiungi la tua linea o navetta con orari e fermate manuali.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 90)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(store.busLines) { bus in
                        busCard(bus: bus)
                    }
                }
            }
        }
    }
    
    // MARK: - Route Card
    
    private func routeCard(route: CommuteRoute) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: route.transportType.iconName)
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(route.name)
                            .font(.headline)
                        
                        Text(route.transportType.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Text("\(route.origin) ➔ \(route.destination)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(route.typicalDurationMinutes) min")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("+ \(route.bufferMinutes) min margine")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Button(role: .destructive, action: {
                    store.deleteCommuteRoute(id: route.id)
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .padding(.leading, 8)
            }
            
            if !route.departureTimes.isEmpty {
                Divider()
                
                HStack(spacing: 8) {
                    Text("Orari frequenti:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    ForEach(route.departureTimes, id: \.self) { time in
                        Text(time)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.primary.opacity(0.06))
                            .cornerRadius(5)
                    }
                    
                    Spacer()
                    
                    if route.costPerTrip > 0 {
                        Text(String(format: "€ %.2f / corsa", route.costPerTrip))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Bus Card
    
    private func busCard(bus: BusLine) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(bus.color.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "bus.fill")
                        .font(.title3)
                        .foregroundColor(bus.color)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(bus.lineNumber)
                            .font(.headline)
                        
                        if bus.frequencyMinutes > 0 {
                            Label("Ogni \(bus.frequencyMinutes) min", systemImage: "clock")
                                .font(.caption2)
                                .foregroundColor(bus.color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(bus.color.opacity(0.12))
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Text("Salita:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(bus.departureStop)
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("➔ Discesa:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(bus.arrivalStop)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    if !bus.direction.isEmpty {
                        Text("Direzione: \(bus.direction)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(bus.travelDurationMinutes) min")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("+ \(bus.bufferMinutes) min margine")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Button(role: .destructive, action: {
                    store.deleteBusLine(id: bus.id)
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .padding(.leading, 8)
            }
            
            // Manual Scheduled Times
            if !bus.scheduledTimes.isEmpty {
                Divider()
                
                HStack(spacing: 8) {
                    Text("Orari passaggio:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    ForEach(bus.scheduledTimes, id: \.self) { time in
                        Text(time)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.primary.opacity(0.06))
                            .cornerRadius(5)
                    }
                    
                    Spacer()
                    
                    if !bus.notes.isEmpty {
                        Text(bus.notes)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Add Commute Route ViewModel & Sheet
public class AddCommuteRouteViewModel: ObservableObject {
    @Published public var name: String = ""
    @Published public var origin: String = ""
    @Published public var destination: String = ""
    @Published public var transportType: TransportType = .treno
    @Published public var durationMinutes: Int = 30
    @Published public var bufferMinutes: Int = 10
    @Published public var departureTimesString: String = "07:30, 08:00, 08:30"
    @Published public var costPerTrip: Double = 2.50
    @Published public var notes: String = ""
    
    public init() {}
}

public struct AddCommuteRouteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm = AddCommuteRouteViewModel()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 18) {
            Text("Aggiungi Tratta di Viaggio")
                .font(.headline)
            
            Form {
                TextField("Nome della tratta (es. Treno Regionale Diretto):", text: $vm.name)
                TextField("Punto di Partenza (es. Stazione Saronno):", text: $vm.origin)
                TextField("Destinazione (es. Campus Bovisa):", text: $vm.destination)
                
                Picker("Mezzo di trasporto:", selection: $vm.transportType) {
                    ForEach(TransportType.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                
                Stepper("Durata tragitto: \(vm.durationMinutes) min", value: $vm.durationMinutes, in: 5...180, step: 5)
                Stepper("Margine di sicurezza (buffer): \(vm.bufferMinutes) min", value: $vm.bufferMinutes, in: 0...60, step: 5)
                
                TextField("Orari di partenza (separati da virgola):", text: $vm.departureTimesString)
                
                TextField("Note aggiuntive (es. Binario 2):", text: $vm.notes)
            }
            .padding()
            
            HStack {
                Button("Annulla") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                
                Button("Salva Tratta") {
                    guard !vm.name.isEmpty else { return }
                    let times = vm.departureTimesString
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                    
                    let newRoute = CommuteRoute(
                        name: vm.name,
                        origin: vm.origin,
                        destination: vm.destination,
                        transportType: vm.transportType,
                        typicalDurationMinutes: vm.durationMinutes,
                        bufferMinutes: vm.bufferMinutes,
                        departureTimes: times,
                        costPerTrip: vm.costPerTrip,
                        notes: vm.notes
                    )
                    store.addCommuteRoute(newRoute)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.name.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 440)
    }
}

// MARK: - Add Bus Line ViewModel & Sheet
public class AddBusLineViewModel: ObservableObject {
    @Published public var lineNumber: String = ""
    @Published public var departureStop: String = ""
    @Published public var arrivalStop: String = ""
    @Published public var direction: String = ""
    @Published public var frequencyMinutes: Int = 10
    @Published public var scheduledTimesString: String = "07:30, 07:45, 08:00, 08:15, 08:30"
    @Published public var travelDurationMinutes: Int = 15
    @Published public var bufferMinutes: Int = 5
    @Published public var colorHex: String = "#FF9500"
    @Published public var notes: String = ""
    
    public init() {}
}

public struct AddBusLineSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm = AddBusLineViewModel()
    
    let colors = ["#FF9500", "#34C759", "#007AFF", "#AF52DE", "#FF2D55", "#5856D6"]
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 18) {
            Text("Aggiungi Linea Autobus / Navetta Manuale")
                .font(.headline)
            
            Form {
                TextField("Numero / Nome Linea (es. Linea 93, Bus 61, Navetta Campus):", text: $vm.lineNumber)
                TextField("Fermata di Salita (es. Lambrate FS):", text: $vm.departureStop)
                TextField("Fermata di Discesa (es. Piazza Leonardo da Vinci):", text: $vm.arrivalStop)
                TextField("Direzione / Capolinea (opzionale):", text: $vm.direction)
                
                Stepper("Frequenza corse: ogni \(vm.frequencyMinutes) min", value: $vm.frequencyMinutes, in: 0...60, step: 2)
                
                TextField("Orari di passaggio manuali (separati da virgola):", text: $vm.scheduledTimesString)
                
                Stepper("Durata percorrenza: \(vm.travelDurationMinutes) min", value: $vm.travelDurationMinutes, in: 2...120, step: 1)
                Stepper("Margine anticipo / buffer: \(vm.bufferMinutes) min", value: $vm.bufferMinutes, in: 0...30, step: 1)
                
                TextField("Note o consigli (es. molto affollato alle 8):", text: $vm.notes)
                
                // Color Picker
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
                
                Button("Salva Linea Bus") {
                    guard !vm.lineNumber.isEmpty else { return }
                    let times = vm.scheduledTimesString
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                    
                    let newBus = BusLine(
                        lineNumber: vm.lineNumber,
                        departureStop: vm.departureStop,
                        arrivalStop: vm.arrivalStop,
                        direction: vm.direction,
                        frequencyMinutes: vm.frequencyMinutes,
                        scheduledTimes: times,
                        travelDurationMinutes: vm.travelDurationMinutes,
                        bufferMinutes: vm.bufferMinutes,
                        colorHex: vm.colorHex,
                        notes: vm.notes
                    )
                    store.addBusLine(newBus)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.lineNumber.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 480)
    }
}
