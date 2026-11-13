import SwiftUI

public class SettingsViewModel: ObservableObject {
    @Published public var showingExportModal: Bool = false
    @Published public var exportedJSON: String = ""
    @Published public var showingResetAlert: Bool = false
    @Published public var showingWipeAlert: Bool = false
    
    public init() {}
}

public struct SettingsView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var vm = SettingsViewModel()
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Impostazioni & Profilo Accademico")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    Text("Configura le regole di calcolo della laurea, i tuoi dati e il backup offline")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Student Profile Section
                VStack(alignment: .leading, spacing: 14) {
                    Text("Profilo Studente")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Form {
                        TextField("Nome e Cognome:", text: $store.settings.studentName)
                        TextField("Ateneo / Università:", text: $store.settings.universityName)
                        TextField("Corso di Laurea:", text: $store.settings.degreeCourse)
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // Degree & GPA Rules
                VStack(alignment: .leading, spacing: 14) {
                    Text("Parametri Carriera & Laurea")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Form {
                        Stepper("Totale CFU del corso: \(store.settings.totalDegreeCFU) CFU", value: $store.settings.totalDegreeCFU, in: 60...360, step: 30)
                        
                        HStack {
                            Text("Bonus Lodi (per ogni 30L):")
                            Spacer()
                            Text(String(format: "+%.2f pt", store.settings.laudeBonusPoints))
                                .fontWeight(.semibold)
                        }
                        Slider(value: $store.settings.laudeBonusPoints, in: 0.0...1.0, step: 0.1)
                        
                        HStack {
                            Text("Punti tesi predefiniti:")
                            Spacer()
                            Text(String(format: "+%.1f pt", store.settings.thesisPointsEstimate))
                                .fontWeight(.semibold)
                        }
                        Slider(value: $store.settings.thesisPointsEstimate, in: 0...10, step: 0.5)
                        
                        Stepper("Obiettivo studio giornaliero: \(String(format: "%.1f", store.settings.dailyStudyGoalHours)) ore", value: $store.settings.dailyStudyGoalHours, in: 1.0...12.0, step: 0.5)
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // Backup & Data Management
                VStack(alignment: .leading, spacing: 14) {
                    Text("Gestione Dati & Privacy (Offline-First)")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tutti i tuoi dati sono salvati localmente sul tuo Mac M2 in una cartella sicura di sistema. Nessun dato viene trasmesso a server esterni o cloud senza il tuo consenso esplicito.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                store.reopenOnboarding()
                            }) {
                                Label("Rifai Questionario", systemImage: "sparkles")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                            
                            Button(action: {
                                if let json = store.exportArchiveJSON() {
                                    vm.exportedJSON = json
                                    let pb = NSPasteboard.general
                                    pb.clearContents()
                                    pb.setString(json, forType: .string)
                                    vm.showingExportModal = true
                                }
                            }) {
                                Label("Esporta Backup JSON", systemImage: "arrow.down.doc")
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: {
                                vm.showingResetAlert = true
                            }) {
                                Label("Dati di Esempio", systemImage: "arrow.counterclockwise")
                            }
                            .buttonStyle(.bordered)
                            
                            Button(role: .destructive, action: {
                                vm.showingWipeAlert = true
                            }) {
                                Label("Azzera Tutto da Zero", systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // App Info
                HStack(spacing: 12) {
                    Image(systemName: "laptopcomputer.and.ipad")
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("UniFlow — Il tuo ecosistema universitario")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text("Versione 1.0.0 • Compilato nativamente per macOS Apple Silicon (M2)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 10)
            }
            .padding(24)
        }
        .alert("Ripristinare i dati di esempio?", isPresented: $vm.showingResetAlert) {
            Button("Annulla", role: .cancel) {}
            Button("Ripristina", role: .destructive) {
                store.resetToSampleData()
            }
        } message: {
            Text("Questa operazione ricaricherà i dati realistici di prova per corsi, orari ed esami.")
        }
        .alert("Azzerare completamente tutti i dati?", isPresented: $vm.showingWipeAlert) {
            Button("Annulla", role: .cancel) {}
            Button("Cancella Tutto", role: .destructive) {
                store.clearAllData()
            }
        } message: {
            Text("Questa operazione cancellerà ogni corso, orario, esame, appunto e tratta salvata, riaprendo il questionario iniziale da zero.")
        }
        .sheet(isPresented: $vm.showingExportModal) {
            VStack(spacing: 14) {
                Text("Backup Dati UniFlow (JSON)")
                    .font(.headline)
                
                Text("Il contenuto è stato copiato anche nei tuoi appunti (Clipboard).")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    Text(vm.exportedJSON)
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                
                Button("Chiudi") {
                    vm.showingExportModal = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(20)
            .frame(width: 500, height: 400)
        }
    }
}
