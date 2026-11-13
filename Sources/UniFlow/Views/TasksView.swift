import SwiftUI

public class TasksViewModel: ObservableObject {
    @Published public var filterMode: String = "In sospeso"
    @Published public var selectedCategory: TaskCategory? = nil
    @Published public var showingAddTaskSheet: Bool = false
    
    public init() {}
}

public struct TasksView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm = TasksViewModel()
    
    public init() {}
    
    private var displayedTasks: [TaskItem] {
        store.tasks.filter { task in
            let matchesStatus: Bool
            switch vm.filterMode {
            case "In sospeso": matchesStatus = !task.isCompleted
            case "Completati": matchesStatus = task.isCompleted
            default: matchesStatus = true
            }
            let matchesCategory = vm.selectedCategory == nil || task.category == vm.selectedCategory
            return matchesStatus && matchesCategory
        }
        .sorted {
            if $0.isCompleted != $1.isCompleted {
                return !$0.isCompleted && $1.isCompleted
            }
            return $0.dueDate < $1.dueDate
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scadenze & Task Accademici")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    Text("Non perdere nessuna scadenza di tasse, bandi, progetti o appelli")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { vm.showingAddTaskSheet = true }) {
                    Label("Nuova Scadenza", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Filter Pills & Segmented Control
            HStack(spacing: 14) {
                Picker("Stato:", selection: $vm.filterMode) {
                    Text("In sospeso (\(store.pendingTasks.count))").tag("In sospeso")
                    Text("Completati (\(store.completedTasksCount))").tag("Completati")
                    Text("Tutti (\(store.tasks.count))").tag("Tutti")
                }
                .pickerStyle(.segmented)
                .frame(width: 320)
                
                Spacer()
                
                // Category Filter
                Picker("Categoria:", selection: $vm.selectedCategory) {
                    Text("Tutte le categorie").tag(TaskCategory?.none)
                    ForEach(TaskCategory.allCases) { cat in
                        Text(cat.rawValue).tag(TaskCategory?.some(cat))
                    }
                }
                .frame(width: 220)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            Divider()
            
            // Tasks List
            ScrollView {
                if displayedTasks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("Nessun task trovato per questi criteri")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(displayedTasks) { task in
                            taskRow(task: task)
                        }
                    }
                    .padding(24)
                }
            }
        }
        .sheet(isPresented: $vm.showingAddTaskSheet) {
            AddTaskSheet()
                .environmentObject(store)
        }
    }
    
    // MARK: - Task Row
    
    private func taskRow(task: TaskItem) -> some View {
        let course = store.course(for: task.courseId)
        let days = task.daysRemaining
        
        return HStack(spacing: 14) {
            // Checkbox
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.toggleTaskCompletion(task)
                }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(task.title)
                        .font(.headline)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                    
                    if let course = course {
                        Text(course.name)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(course.color.opacity(0.12))
                            .foregroundColor(course.color)
                            .cornerRadius(4)
                    }
                }
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    CategoryBadge(task.category)
                    PriorityBadge(task.priority)
                    
                    Label(dateFormatter.string(from: task.dueDate), systemImage: "calendar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }
            
            Spacer()
            
            // Countdown Badge
            if !task.isCompleted {
                countdownBadge(days: days)
            }
            
            // Delete button
            Button(role: .destructive, action: {
                store.deleteTask(id: task.id)
            }) {
                Image(systemName: "trash")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .help("Elimina task")
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private func countdownBadge(days: Int) -> some View {
        let text: String
        let color: Color
        
        if days < 0 {
            text = "Scaduto (\(abs(days)) gg)"
            color = .red
        } else if days == 0 {
            text = "Scade Oggi!"
            color = .orange
        } else if days == 1 {
            text = "Domani"
            color = .orange
        } else {
            text = "Mancano \(days) gg"
            color = .blue
        }
        
        return Text(text)
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .cornerRadius(6)
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateStyle = .medium
        return f
    }
}

// MARK: - Add Task ViewModel & Sheet
public class AddTaskViewModel: ObservableObject {
    @Published public var title: String = ""
    @Published public var description: String = ""
    @Published public var dueDate: Date = Date().addingTimeInterval(86400 * 3)
    @Published public var priority: TaskPriority = .media
    @Published public var category: TaskCategory = .studio
    @Published public var selectedCourseId: UUID? = nil
    
    public init() {}
}

public struct AddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm = AddTaskViewModel()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 18) {
            Text("Aggiungi Scadenza o Promemoria")
                .font(.headline)
            
            Form {
                TextField("Titolo della scadenza:", text: $vm.title)
                TextField("Dettagli / Istruzioni:", text: $vm.description)
                
                Picker("Categoria:", selection: $vm.category) {
                    ForEach(TaskCategory.allCases) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                
                Picker("Priorità:", selection: $vm.priority) {
                    ForEach(TaskPriority.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                
                Picker("Insegnamento collegato:", selection: $vm.selectedCourseId) {
                    Text("Nessuno (Generale)").tag(UUID?.none)
                    ForEach(store.courses) { c in
                        Text(c.name).tag(UUID?.some(c.id))
                    }
                }
                
                DatePicker("Data di scadenza:", selection: $vm.dueDate, displayedComponents: [.date, .hourAndMinute])
            }
            .padding()
            
            HStack {
                Button("Annulla") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                
                Button("Salva Scadenza") {
                    guard !vm.title.isEmpty else { return }
                    let newTask = TaskItem(
                        courseId: vm.selectedCourseId,
                        title: vm.title,
                        description: vm.description,
                        dueDate: vm.dueDate,
                        priority: vm.priority,
                        category: vm.category,
                        isCompleted: false
                    )
                    store.addTask(newTask)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.title.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 440)
    }
}
