import SwiftUI

struct DropZoneView: View {
    @Binding var showFilePicker: Bool
    @Environment(LanguageManager.self) private var lm

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "tray.and.arrow.down.fill")
                .font(.system(size: 42, weight: .medium))
                .foregroundStyle(Color.glassCyan)

            Text(lm.t("no_sets_yet"))
                .font(.system(size: 26, weight: .medium, design: .default))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Button(lm.t("import_file")) {
                showFilePicker = true
            }
            .buttonStyle(GlassButtonStyle())
        }
        .padding(22)
        .frame(maxWidth: 560)
        .glassPanel(cornerRadius: 22)
    }
}

struct FolderSectionView: View {
    let folder: Folder
    @Bindable var vm: SetsLibraryViewModel
    let onDrop: ([String]) -> Bool

    @Environment(LanguageManager.self) private var lm

    var body: some View {
        let isExpanded = !vm.collapsedFolderIDs.contains(folder.id)

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.medium))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .foregroundColor(.white.opacity(0.7))
                    .animation(.spring(response: 0.28, dampingFraction: 0.84), value: isExpanded)

                if vm.renamingFolderID == folder.id {
                    TextField("", text: $vm.folderRenameText)
                        .textFieldStyle(.plain)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .onSubmit {
                            vm.renameFolder(folder, to: vm.folderRenameText)
                            vm.renamingFolderID = nil
                        }
                } else {
                    Label(folder.name, systemImage: "folder.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .onTapGesture(count: 2) {
                            vm.folderRenameText = folder.name
                            vm.renamingFolderID = folder.id
                        }
                }

                Spacer()

                Text("\(folder.sets.count)")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.82))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                    )

                if vm.dragOverFolderID == folder.id {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.glassCyan)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(vm.dragOverFolderID == folder.id ? Color.glassCyan.opacity(0.18) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(vm.dragOverFolderID == folder.id ? Color.glassCyan.opacity(0.55) : Color.white.opacity(0.14), lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                    if vm.collapsedFolderIDs.contains(folder.id) {
                        vm.collapsedFolderIDs.remove(folder.id)
                    } else {
                        vm.collapsedFolderIDs.insert(folder.id)
                    }
                }
            }

            if isExpanded && !folder.sets.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 12)], spacing: 12) {
                    ForEach(folder.sets.sorted(by: { $0.name < $1.name })) { set in
                        SetCard(set: set)
                    }
                }
                .padding(.top, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .glassPanel(cornerRadius: 18)
        .contextMenu {
            Button(lm.t("rename")) {
                vm.folderRenameText = folder.name
                vm.renamingFolderID = folder.id
            }
            Button(lm.t("delete"), role: .destructive) {
                vm.deleteFolder(folder)
            }
        }
        .dropDestination(for: String.self) { ids, _ in
            onDrop(ids)
        } isTargeted: { targeted in
            vm.dragOverFolderID = targeted ? folder.id : nil
            if targeted && !isExpanded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    if vm.dragOverFolderID == folder.id {
                        _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                            vm.collapsedFolderIDs.remove(folder.id)
                        }
                    }
                }
            }
        }
    }
}

struct UngroupedSectionView: View {
    let ungroupedSets: [WordSet]
    @Binding var dragOverUnfiled: Bool
    let onDrop: ([String]) -> Bool
    @Environment(LanguageManager.self) private var lm

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(lm.t("unfiled"), systemImage: "tray.full.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                Spacer()
                if dragOverUnfiled {
                    Image(systemName: "arrow.down.doc.fill")
                        .foregroundColor(.glassCyan)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(dragOverUnfiled ? Color.glassCyan.opacity(0.16) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(dragOverUnfiled ? Color.glassCyan.opacity(0.5) : Color.white.opacity(0.14), lineWidth: 1)
                    )
            )
            .dropDestination(for: String.self) { ids, _ in
                onDrop(ids)
            } isTargeted: { targeted in
                dragOverUnfiled = targeted
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 12)], spacing: 12) {
                ForEach(ungroupedSets) { set in
                    SetCard(set: set)
                }
            }
            .padding(.top, 6)
        }
        .padding(12)
        .glassPanel(cornerRadius: 18)
    }
}
