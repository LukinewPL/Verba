import SwiftUI
import SwiftData

struct SetCard: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(AppCoordinator.self) private var coordinator
    @Bindable var set: WordSet
    @Environment(\.modelContext) private var ctx
    @State private var errorHandler = ErrorHandler.shared
    @State private var showDeleteConfirm = false
    @State private var showRenameAlert = false
    @State private var newName = ""
    @Query(sort: \Folder.name) private var folders: [Folder]

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
        VStack(alignment: .leading, spacing: 14) {
            headerSection
            actionGrid
        }
        .padding(12)
        .frame(minWidth: 280, maxWidth: .infinity)
        .glassPanel(cornerRadius: 18)
        .draggable(set.id.uuidString) {
            dragPreview
        }
        .contextMenu {
            contextMenuContent
        }
        .alert(lm.t("rename_set"), isPresented: $showRenameAlert) {
            TextField(lm.t("new_name"), text: $newName)
            Button(lm.t("cancel"), role: .cancel) {}
            Button(lm.t("save")) {
                let sanitized = sanitizeSetName(newName)
                guard !sanitized.isEmpty else { return }
                set.name = sanitized
                saveContext()
            }
        }
        .alert(lm.t("delete_set_q"), isPresented: $showDeleteConfirm) {
            Button(lm.t("cancel"), role: .cancel) {}
            Button(lm.t("delete"), role: .destructive) { deleteSet() }
        } message: { Text(lm.t("undone_msg")) }
    }

    private var headerSection: some View {
        Button(action: openSetDetails) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(set.name)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Text("\(totalCount) \(lm.t("words"))")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color.glassCyan.opacity(0.9))
                }

                Spacer()

                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 4)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                AngularGradient(colors: [.glassCyan, .blue, .glassCyan], center: .center),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(width: 38, height: 38)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.top, 2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var actionGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                actionButton(lm.t("study"), icon: "book.fill") { coordinator.navigate(to: .studySession(set)) }
                actionButton(lm.t("flashcards"), icon: "rectangle.stack.fill") { coordinator.navigate(to: .flashcards(set)) }
            }

            HStack(spacing: 8) {
                actionButton(lm.t("speed_round"), icon: "bolt.fill") { coordinator.navigate(to: .speedRound(set)) }
                actionButton(lm.t("test"), icon: "checkmark.circle.fill") { coordinator.navigate(to: .test(set)) }
            }
        }
    }

    private func openSetDetails() {
        coordinator.navigate(to: .setDetail(set))
    }

    private var dragPreview: some View {
        HStack(spacing: 12) {
            Image(systemName: "rectangle.stack.fill")
                .font(.title3)
                .foregroundStyle(.cyan)
            VStack(alignment: .leading, spacing: 2) {
                Text(set.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(set.words.count) \(lm.t("words"))")
                    .font(.caption)
                    .foregroundStyle(.cyan.opacity(0.8))
            }
        }
        .padding()
        .background(DesignSystem.Colors.background.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2)))
    }

    private var contextMenuContent: some View {
        Group {
            Button {
                newName = set.name
                showRenameAlert = true
            } label: {
                Label(lm.t("rename"), systemImage: "pencil")
            }

            Menu {
                Button {
                    set.folder = nil
                    saveContext()
                } label: { Label(lm.t("none"), systemImage: "xmark") }

                ForEach(folders) { f in
                    Button(f.name) {
                        set.folder = f
                        saveContext()
                    }
                }
            } label: { Label(lm.t("move_to_folder"), systemImage: "folder") }

            Divider()

            Button(role: .destructive) { showDeleteConfirm = true } label: {
                Label(lm.t("delete"), systemImage: "trash")
            }
        }
    }

    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.glassCyan)
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(colors: [Color.white.opacity(0.11), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func deleteSet() {
        ctx.delete(set)
        saveContext()
    }

    private func saveContext() {
        do {
            try ctx.save()
        } catch {
            errorHandler.handle(error)
        }
    }

    private func sanitizeSetName(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
