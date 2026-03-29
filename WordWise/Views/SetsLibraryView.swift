import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SetsLibraryView: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(WordRepository.self) private var repository
    @State private var vm = SetsLibraryViewModel()
    
    var body: some View {
        ZStack {
            libraryBackground
            
            VStack(spacing: 12) {
                headerCard
                
                if vm.allSets.isEmpty && vm.folders.isEmpty {
                    DropZoneView(showFilePicker: $vm.showFilePicker)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(vm.folders) { folder in
                                FolderSectionView(
                                    folder: folder,
                                    vm: vm,
                                    onDrop: { ids in vm.handleDrop(ids: ids, to: folder) }
                                )
                            }
                            
                            UngroupedSectionView(
                                ungroupedSets: vm.ungroupedSets,
                                dragOverUnfiled: $vm.dragOverUnfiled,
                                onDrop: { ids in vm.handleDrop(ids: ids, to: nil) }
                            )
                        }
                        .padding(.bottom, 22)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .frame(maxWidth: 1120)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .fileImporter(isPresented: $vm.showFilePicker, allowedContentTypes: vm.allowedContentTypes) { result in
            switch result {
            case .success(let url): vm.startImport(url: url)
            case .failure(let error):
                vm.importError = error.localizedDescription
                vm.showError = true
            }
        }
        .sheet(item: $vm.importConfig) { _ in
            ImportConfirmationView(config: $vm.importConfig) { swap in
                vm.confirmImport(swap: swap)
            }
        }
        .alert(lm.t("import_error"), isPresented: $vm.showError, presenting: vm.importError) { _ in
            Button(lm.t("ok"), role: .cancel) { }
        } message: { msg in
            Text(msg)
        }
        .alert(lm.t("new_folder"), isPresented: $vm.showNewFolderAlert) {
            TextField(lm.t("new_folder_name"), text: $vm.newFolderName)
            Button(lm.t("cancel"), role: .cancel) {}
            Button(lm.t("create")) { vm.createFolder() }
        }
        .navigationTitle("")
        .toolbarTitleDisplayMode(.inline)
        .onAppear {
            vm.setup(repository: repository)
        }
    }
    
    private var headerCard: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.glassCyan)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.glassCyan.opacity(0.16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.glassCyan.opacity(0.36), lineWidth: 1)
                            )
                    )
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(lm.t("sets_library"))
                        .font(.system(size: 24, weight: .medium, design: .default))
                        .foregroundColor(.white)
                    HStack(spacing: 10) {
                        Label("\(vm.allSets.count) \(lm.t("words"))", systemImage: "text.book.closed.fill")
                        Label("\(vm.folders.count)", systemImage: "folder.fill")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.62))
                }
            }
            
            Spacer(minLength: 12)
            
            HStack(spacing: 8) {
                actionPillButton(title: lm.t("new_folder"), icon: "folder.badge.plus") {
                    vm.showNewFolderAlert = true
                }
                actionPillButton(title: lm.t("import"), icon: "plus") {
                    vm.showFilePicker = true
                }
            }
        }
        .padding(14)
        .libraryPanel(cornerRadius: 20)
    }
    
    private func actionPillButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
    
    private var libraryBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.04, blue: 0.2),
                    Color(red: 0.02, green: 0.05, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            RadialGradient(
                colors: [Color.glassCyan.opacity(0.16), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 560
            )
            .ignoresSafeArea()
            
            RadialGradient(
                colors: [Color.blue.opacity(0.14), .clear],
                center: .bottomLeading,
                startRadius: 80,
                endRadius: 660
            )
            .ignoresSafeArea()
        }
    }
}

private struct DropZoneView: View {
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
        .libraryPanel(cornerRadius: 22)
    }
}

private struct FolderSectionView: View {
    let folder: Folder
    @Bindable var vm: SetsLibraryViewModel
    let onDrop: ([String]) -> Bool
    
    @Environment(LanguageManager.self) private var lm

    var body: some View {
        let isExpanded = !vm.expandedFolders.contains(folder.id)
        
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
                    if vm.expandedFolders.contains(folder.id) {
                        vm.expandedFolders.remove(folder.id)
                    } else {
                        vm.expandedFolders.insert(folder.id)
                    }
                }
            }
            
            if isExpanded && !folder.sets.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 12)], spacing: 12) {
                    ForEach(folder.sets.sorted(by: { $0.name < $1.name })) { s in
                        SetCard(set: s)
                    }
                }
                .padding(.top, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .libraryPanel(cornerRadius: 18)
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
                            vm.expandedFolders.remove(folder.id)
                        }
                    }
                }
            }
        }
    }
}

private struct UngroupedSectionView: View {
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
                ForEach(ungroupedSets) { s in
                    SetCard(set: s)
                }
            }
            .padding(.top, 6)
        }
        .padding(12)
        .libraryPanel(cornerRadius: 18)
    }
}

private extension View {
    func libraryPanel(cornerRadius: CGFloat = 18, edgeHighlight: Color = Color.glassCyan.opacity(0.16)) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.1), Color.white.opacity(0.04)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(edgeHighlight, lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.22), radius: 14, x: 0, y: 8)
            )
    }
}
