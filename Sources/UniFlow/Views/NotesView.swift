import SwiftUI

public class NotesViewModel: ObservableObject {
    @Published public var selectedNoteId: UUID? = nil
    @Published public var searchText: String = ""
    @Published public var selectedCourseFilter: UUID? = nil
    @Published public var showingAddNoteSheet: Bool = false
    
    public init() {}
}

public struct NotesView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm = NotesViewModel()
    
    public init() {}
    
    private var filteredNotes: [NoteItem] {
        store.notes.filter { note in
            let matchesSearch = vm.searchText.isEmpty ||
                note.title.localizedCaseInsensitiveContains(vm.searchText) ||
                note.content.localizedCaseInsensitiveContains(vm.searchText) ||
                note.tags.contains { $0.localizedCaseInsensitiveContains(vm.searchText) }
            
            let matchesCourse = vm.selectedCourseFilter == nil || note.courseId == vm.selectedCourseFilter
            return matchesSearch && matchesCourse
        }
    }
    
    public var body: some View {
        HSplitView {
            // Left Notes List Sidebar
            VStack(spacing: 0) {
                // Header & Action
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Appunti & Risorse")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("\(filteredNotes.count) appunti")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: { vm.showingAddNoteSheet = true }) {
                            Label("Nuovo Appunto", systemImage: "plus")
                                .font(.caption)
                        }
                        .buttonStyle(.borderedProminent)
                        .help("Crea nuovo appunto (⌘N)")
                    }
                    
                    TextField("Cerca per titolo, formula o tag...", text: $vm.searchText)
                        .textFieldStyle(.roundedBorder)
                    
                    // Filter by course
                    Picker("Insegnamento:", selection: $vm.selectedCourseFilter) {
                        Text("Tutti i corsi").tag(UUID?.none)
                        ForEach(store.courses) { course in
                            Text(course.name).tag(UUID?.some(course.id))
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(14)
                
                Divider()
                
                // Notes List
                if filteredNotes.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "note.text.badge.plus")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("Nessun appunto trovato")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Aggiungi il primo", action: { vm.showingAddNoteSheet = true })
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                    .padding(.top, 40)
                    .frame(maxWidth: .infinity)
                } else {
                    List(selection: $vm.selectedNoteId) {
                        ForEach(filteredNotes) { note in
                            noteRow(note: note)
                                .tag(note.id)
                        }
                        .onDelete(perform: deleteNotes)
                    }
                    .listStyle(.sidebar)
                }
            }
            .frame(minWidth: 280, maxWidth: 360)
            
            // Right Editor Pane
            if let noteId = vm.selectedNoteId, let noteIndex = store.notes.firstIndex(where: { $0.id == noteId }) {
                noteEditor(for: noteIndex)
            } else {
                VStack(spacing: 14) {
                    Image(systemName: "cross.vial.fill")
                        .font(.system(size: 54))
                        .foregroundColor(.purple.opacity(0.6))
                    Text("Quaderno Appunti di Farmacia")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Seleziona una nota dalla lista a sinistra oppure creane una nuova.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: { vm.showingAddNoteSheet = true }) {
                        Label("Crea Nuovo Appunto", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $vm.showingAddNoteSheet) {
            AddNoteSheet()
                .environmentObject(store)
        }
        .onAppear {
            if vm.selectedNoteId == nil, let first = store.notes.first {
                vm.selectedNoteId = first.id
            }
        }
    }
    
    // MARK: - Subviews
    
    private func noteRow(note: NoteItem) -> some View {
        let course = store.course(for: note.courseId)
        
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(note.title.isEmpty ? "Nuovo Appunto" : note.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if let course = course {
                    Circle()
                        .fill(course.color)
                        .frame(width: 8, height: 8)
                }
            }
            
            Text(note.content.isEmpty ? "Nessun contenuto..." : note.content.replacingOccurrences(of: "\n", with: " "))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack(spacing: 4) {
                ForEach(note.tags.prefix(3), id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(dateFormatter.string(from: note.updatedAt))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }
    
    private func noteEditor(for index: Int) -> some View {
        VStack(spacing: 0) {
            // Note Top Toolbar
            HStack(spacing: 12) {
                Picker("Insegnamento:", selection: $store.notes[index].courseId) {
                    Text("Nessuno").tag(UUID?.none)
                    ForEach(store.courses) { c in
                        Text(c.name).tag(UUID?.some(c.id))
                    }
                }
                .frame(maxWidth: 280)
                
                Spacer()
                
                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(store.notes[index].content, forType: .string)
                }) {
                    Label("Copia", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .help("Copia testo negli appunti")
                
                Button(role: .destructive, action: {
                    let id = store.notes[index].id
                    store.deleteNote(id: id)
                    vm.selectedNoteId = store.notes.first?.id
                }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
                .help("Elimina nota")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            Divider()
            
            // Title input
            TextField("Titolo dell'appunto...", text: $store.notes[index].title)
                .font(.system(size: 24, weight: .bold))
                .textFieldStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .onChange(of: store.notes[index].title) {
                    store.saveData()
                }
            
            // Content Text Editor
            TextEditor(text: $store.notes[index].content)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 16)
                .scrollContentBackground(.hidden)
                .background(Color(NSColor.textBackgroundColor))
                .onChange(of: store.notes[index].content) {
                    store.saveData()
                }
        }
    }
    
    private func deleteNotes(at offsets: IndexSet) {
        for index in offsets {
            let id = filteredNotes[index].id
            store.deleteNote(id: id)
        }
        vm.selectedNoteId = store.notes.first?.id
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateStyle = .short
        return f
    }
}

// MARK: - Add Note Sheet with Pharmacy Templates
public class AddNoteViewModel: ObservableObject {
    @Published public var title: String = ""
    @Published public var selectedCourseId: UUID? = nil
    @Published public var tagsString: String = "Farmacia, Sapienza"
    @Published public var selectedTemplate: String = "Libero"
    @Published public var content: String = ""
    
    public init() {}
}

public struct AddNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm = AddNoteViewModel()
    
    let templates = [
        ("Libero", "Appunto generico o riassunto di lezione"),
        ("Scheda Farmaco", "Principio attivo, meccanismo e posologia"),
        ("Lab Galenico", "Metodica galenica, calcoli tara e FU")
    ]
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            Text("Aggiungi Nuovo Appunto di Studio")
                .font(.headline)
            
            Form {
                TextField("Titolo dell'appunto:", text: $vm.title)
                
                Picker("Insegnamento / Corso:", selection: $vm.selectedCourseId) {
                    Text("Nessuno (Generale)").tag(UUID?.none)
                    ForEach(store.courses) { c in
                        Text(c.name).tag(UUID?.some(c.id))
                    }
                }
                
                Picker("Modello / Template:", selection: $vm.selectedTemplate) {
                    ForEach(templates, id: \.0) { t in
                        Text(t.0).tag(t.0)
                    }
                }
                .onChange(of: vm.selectedTemplate) { _, newTemplate in
                    applyTemplate(newTemplate)
                }
                
                TextField("Tag (separati da virgola):", text: $vm.tagsString)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Contenuto Markdown:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $vm.content)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 140)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                }
            }
            .padding()
            
            HStack {
                Button("Annulla") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                
                Button("Crea Appunto") {
                    guard !vm.title.isEmpty else { return }
                    let tags = vm.tagsString
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                    
                    let newNote = NoteItem(
                        courseId: vm.selectedCourseId,
                        title: vm.title,
                        content: vm.content.isEmpty ? "# \(vm.title)\n\n" : vm.content,
                        tags: tags
                    )
                    store.addNote(newNote)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(vm.title.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 500)
        .onAppear {
            if vm.selectedCourseId == nil {
                vm.selectedCourseId = store.courses.first?.id
            }
            applyTemplate(vm.selectedTemplate)
        }
    }
    
    private func applyTemplate(_ template: String) {
        switch template {
        case "Scheda Farmaco":
            vm.title = vm.title.isEmpty ? "Scheda Farmaco: [Nome Farmaco]" : vm.title
            vm.tagsString = "Farmacologia, Farmaco, Meccanismo"
            vm.content = """
            # Scheda Farmaco
            
            - **Principio Attivo**: 
            - **Classe Farmacoterapeutica**: 
            - **Meccanismo d'Azione**: 
            - **Indicazioni Terapeutiche**: 
            - **Effetti Collaterali & Tossicità**: 
            - **Interazioni e Controindicazioni**: 
            """
        case "Lab Galenico":
            vm.title = vm.title.isEmpty ? "Preparazione Galenica: [Forma Farmaceutica]" : vm.title
            vm.tagsString = "Galenica, Laboratorio, Farmacopea"
            vm.content = """
            # Preparazione Galenica Magistrale
            
            - **Forma Farmaceutica**: Capsule / Polvere / Soluzione
            - **Composizione e Sostanze**:
              - Principio Attivo: [quantità]
              - Eccipiente / Diluente: [quantità]
            - **Taratura e Calcoli**: 
            - **Procedimento di Allestimento**: 
            - **Saggi di Farmacopea (FU)**: Uniformità di massa e tenuta.
            """
        default:
            vm.content = "# \(vm.title.isEmpty ? "Appunti di Studio" : vm.title)\n\nInserisci qui i tuoi concetti chiave, formule chimiche e reazioni..."
        }
    }
}
