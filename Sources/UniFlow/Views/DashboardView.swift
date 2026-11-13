import SwiftUI

public struct DashboardView: View {
    @EnvironmentObject private var store: DataStore
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "EEEE d MMMM yyyy"
        return f
    }
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Header Banner
                headerBanner
                
                // Stat Cards Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ], spacing: 14) {
                    StatCard(
                        title: "Media Ponderata",
                        value: store.weightedGPA > 0 ? String(format: "%.2f", store.weightedGPA) : "—",
                        subtitle: "Aritmetica: \(store.arithmeticGPA > 0 ? String(format: "%.2f", store.arithmeticGPA) : "—")",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "CFU Acquisiti",
                        value: "\(store.totalPassedCFU) / \(store.settings.totalDegreeCFU)",
                        subtitle: "\(String(format: "%.0f%%", store.cfuProgressPercentage * 100)) completato",
                        icon: "graduationcap.fill",
                        color: .purple
                    )
                    
                    StatCard(
                        title: "Base di Laurea",
                        value: store.graduationBaseScore > 0 ? String(format: "%.1f", store.graduationBaseScore) : "—",
                        subtitle: "Stima finale: \(store.projectedGraduationScore > 0 ? String(format: "%.0f/110", store.projectedGraduationScore) : "—")",
                        icon: "rosette",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "Task in Scadenza",
                        value: "\(store.urgentTasks.count)",
                        subtitle: "\(store.pendingTasks.count) totali in sospeso",
                        icon: "clock.badge.exclamationmark",
                        color: store.urgentTasks.isEmpty ? .green : .red
                    )
                }
                
                // Next Up Lesson Banner
                if let next = store.nextUpcomingLesson {
                    nextLessonCard(lesson: next.lesson, course: next.course)
                }
                
                // Two Column Layout: Today's Schedule & Urgent Tasks
                HStack(alignment: .top, spacing: 18) {
                    todayScheduleSection
                        .frame(maxWidth: .infinity)
                    
                    urgentTasksSection
                        .frame(maxWidth: .infinity)
                }
                
                // Quick Commute & Pomodoro Section
                quickActionsSection
            }
            .padding(24)
        }
    }
    
    // MARK: - Subviews
    
    private var headerBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(dateFormatter.string(from: Date()).capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text("Bentornato, \(store.settings.studentName) 👋")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                
                Text("\(store.settings.degreeCourse) • \(store.settings.universityName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            // CFU Mini Progress Circle
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 6)
                        .frame(width: 52, height: 52)
                    
                    Circle()
                        .trim(from: 0, to: store.cfuProgressPercentage)
                        .stroke(
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(store.cfuProgressPercentage * 100))%")
                        .font(.system(size: 11, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Obiettivo Laurea")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(store.remainingCFU) CFU mancanti")
                        .font(.callout)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
    }
    
    private func nextLessonCard(lesson: Lesson, course: Course) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(course.color.opacity(0.18))
                    .frame(width: 56, height: 56)
                Image(systemName: "bell.badge.fill")
                    .font(.title2)
                    .foregroundColor(course.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("PROSSIMA LEZIONE OGGI")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(course.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(course.color.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Text(lesson.timeRangeString)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Text(course.name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack(spacing: 14) {
                    Label(lesson.room.isEmpty ? "Aula non definita" : lesson.room, systemImage: "mappin.and.ellipse")
                    if !lesson.building.isEmpty {
                        Label(lesson.building, systemImage: "building.2")
                    }
                    if !course.professor.isEmpty {
                        Label(course.professor, systemImage: "person")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            if !course.onlineLink.isEmpty, let url = URL(string: course.onlineLink) {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Image(systemName: "video.fill")
                        Text("Teams")
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(course.color.opacity(0.3), lineWidth: 1.5)
                )
        )
    }
    
    private var todayScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Lezioni di Oggi", systemImage: "calendar")
                    .font(.headline)
                Spacer()
                Text("\(store.todayLessons.count) in programma")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if store.todayLessons.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Nessuna lezione in programma per oggi!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 140)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(store.todayLessons, id: \.lesson.id) { item in
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(item.course.color)
                                .frame(width: 4)
                                .cornerRadius(2)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.course.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                HStack(spacing: 8) {
                                    Text(item.lesson.timeRangeString)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("•")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(item.lesson.room)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if !item.lesson.notes.isEmpty {
                                Image(systemName: "info.circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .help(item.lesson.notes)
                            }
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private var urgentTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Scadenze & Promemoria", systemImage: "checklist")
                    .font(.headline)
                Spacer()
                Button(action: {
                    store.selectedNavigationItem = .tasks
                }) {
                    Text("Vedi tutti")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            
            if store.pendingTasks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("Tutte le scadenze completate!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 140)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(store.pendingTasks.prefix(4)) { task in
                        HStack(spacing: 10) {
                            Button(action: {
                                withAnimation {
                                    store.toggleTaskCompletion(task)
                                }
                            }) {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(task.isCompleted ? .green : .secondary)
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(.plain)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .strikethrough(task.isCompleted)
                                
                                HStack(spacing: 6) {
                                    CategoryBadge(task.category)
                                    PriorityBadge(task.priority)
                                }
                            }
                            
                            Spacer()
                            
                            // Days badge
                            let days = task.daysRemaining
                            Text(days < 0 ? "Scaduto" : (days == 0 ? "Oggi!" : "\(days) gg"))
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(days <= 1 ? Color.red.opacity(0.15) : Color.secondary.opacity(0.1))
                                .foregroundColor(days <= 1 ? .red : .primary)
                                .cornerRadius(6)
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        HStack(spacing: 14) {
            // Commute summary
            if let commute = store.commuteRoutes.first {
                HStack(spacing: 14) {
                    Image(systemName: commute.transportType.iconName)
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pendolarismo: \(commute.name)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("\(commute.origin) → \(commute.destination) (\(commute.typicalDurationMinutes) min + \(commute.bufferMinutes) min margine)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    Button("Tratte") {
                        store.selectedNavigationItem = .commute
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
            
            // Pomodoro & Break quick action
            HStack(spacing: 14) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.title)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pausa & Focus Studio")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Ricarica mentale e motivazioni nelle pause")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button("Apri Sezione") {
                    store.selectedNavigationItem = .pomodoro
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.small)
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
    }
}
