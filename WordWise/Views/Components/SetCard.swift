import SwiftUI; import SwiftData

struct SetCard: View {
    @Environment(LanguageManager.self) private var lm
    @Bindable var set: WordSet
    @Environment(\.modelContext) private var ctx
    @State private var navigateStudy = false
    @State private var navigateSpeedRound = false
    @State private var navigateTest = false
    @State private var showDeleteConfirm = false
    @State private var showRenameAlert = false
    @State private var newName = ""
    @Query(sort: \Folder.name) private var folders: [Folder]
    @State private var appearing = false
    
    // Explicitly compute to ensure reactivity when underlying words change
    private var masteredCount: Int {
        get { set.words.filter { $0.isMastered }.count }
    }
    private var totalCount: Int {
        get { set.words.count }
    }
    private var progress: Double {
        get { Double(masteredCount) / Double(max(1, totalCount)) }
    }
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading) {
                    Text(set.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(totalCount) \(lm.t("words"))")
                        .font(.subheadline)
                        .foregroundColor(.glassCyan)
                }
                Spacer()
                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
            }
            
            
            HStack(spacing: 8) {
                actionButton(lm.t("study"), icon: "book.fill") { navigateStudy = true }
                    .help(lm.t("study"))
                actionButton(lm.t("speed_round"), icon: "bolt.fill") { navigateSpeedRound = true }
                    .help(lm.t("speed_round"))
                actionButton(lm.t("test"), icon: "checkmark.circle.fill") { navigateTest = true }
                    .help(lm.t("test"))
            }
        }
        .padding()
        .frame(minWidth: 300)
        .fixedSize(horizontal: false, vertical: true)
        .glassEffect()
        .onAppear { withAnimation { appearing = true } }
        .transition(.scale(0.9).combined(with: .opacity))
        .animation(.spring(bounce: 0.3), value: appearing)
        .draggable(set.id.uuidString) {
            ZStack {
                // Base glass layer
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.15, green: 0.2, blue: 0.4).opacity(0.85),
                                Color(red: 0.08, green: 0.12, blue: 0.28).opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                // Top highlight (glass shine)
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.25), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                // Border
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                // Content
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.title3)
                        .foregroundStyle(.cyan)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(set.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text("\(set.words.count) \(lm.t("words"))")
                            .font(.caption)
                            .foregroundStyle(.cyan.opacity(0.8))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .frame(width: 280, height: 72)
            .environment(\.colorScheme, .dark)
            .shadow(color: .cyan.opacity(0.2), radius: 16, y: 8)
            .compositingGroup()
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .clipped()
        }
        .contextMenu {
            Button {
                newName = set.name
                showRenameAlert = true
            } label: {
                Label(lm.t("rename"), systemImage: "pencil")
            }
            
            Menu {
                Button {
                    set.folder = nil
                    do {
                        try ctx.save()
                    } catch {
                        print("WordWise: Save failed — \(error)")
                    }
                } label: {
                    Label(lm.t("none"), systemImage: "xmark")
                }
                
                ForEach(folders) { f in
                    Button(f.name) {
                        set.folder = f
                        do {
                            try ctx.save()
                        } catch {
                            print("WordWise: Save failed — \(error)")
                        }
                    }
                }
            } label: {
                Label(lm.t("move_to_folder"), systemImage: "folder")
            }
            
            Divider()
            
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label(lm.t("delete"), systemImage: "trash")
            }
        }
        .alert(lm.t("rename_set"), isPresented: $showRenameAlert) {
            TextField(lm.t("new_name"), text: $newName)
            Button(lm.t("cancel"), role: .cancel) {}
            Button(lm.t("save")) {
                set.name = newName
                do {
                    try ctx.save()
                } catch {
                    print("WordWise: Save failed — \(error)")
                }
            }
        }
        .navigationDestination(isPresented: $navigateStudy) { StudySessionView(set: set) }
        .navigationDestination(isPresented: $navigateSpeedRound) { SpeedRoundView(set: set) }
        .navigationDestination(isPresented: $navigateTest) { TestView(set: set) }
        .alert(lm.t("delete_set_q"), isPresented: $showDeleteConfirm) {
            Button(lm.t("cancel"), role: .cancel) {}
            Button(lm.t("delete"), role: .destructive) { deleteSet() }
        } message: { Text(lm.t("undone_msg")) }
    }
    
    
    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .frame(maxWidth: .infinity, minHeight: 72)
        }
        .buttonStyle(GlassButtonStyle())
    }

    private func deleteSet() {
        for word in set.words { ctx.delete(word) }
        ctx.delete(set)
        do {
            try ctx.save()
        } catch {
            print("WordWise: Save failed — \(error)")
        }
    }
}
