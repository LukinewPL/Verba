import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - View

struct SetsLibraryView: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(WordRepository.self) private var repository
    @Environment(\.modelContext) var ctx
    @State private var vm = SetsLibraryViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if vm.allSets.isEmpty && vm.folders.isEmpty {
                    DropZoneView(showFilePicker: $vm.showFilePicker)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(vm.folders) { folder in
                                FolderSectionView(
                                    folder: folder,
                                    vm: vm,
                                    onDrop: { ids in vm.handleDrop(ids: ids, to: folder) }
                                )
                            }
                            
                            if !vm.allSets.isEmpty {
                                UngroupedSectionView(
                                    ungroupedSets: vm.ungroupedSets,
                                    dragOverUnfiled: $vm.dragOverUnfiled,
                                    onDrop: { ids in vm.handleDrop(ids: ids, to: nil) }
                                )
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle(lm.t("sets_library"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        Button(action: { vm.showNewFolderAlert = true }) {
                            Label(lm.t("new_folder"), systemImage: "folder.badge.plus")
                        }
                        Button(action: { vm.showFilePicker = true }) {
                            Label(lm.t("import"), systemImage: "plus")
                        }
                    }
                }
            }
        }
        .fileImporter(isPresented: $vm.showFilePicker, allowedContentTypes: vm.allowedContentTypes) { result in
            switch result {
            case .success(let url): vm.importFile(url: url, context: ctx)
            case .failure(let error): 
                vm.importError = error.localizedDescription
                vm.showError = true
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
        .onAppear {
            vm.setup(repository: repository)
        }
    }
}

private struct DropZoneView: View {
    @Binding var showFilePicker: Bool
    @Environment(LanguageManager.self) private var lm
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.glassCyan)
            Text(lm.t("no_sets_yet"))
                .font(.title.bold())
                .foregroundColor(.white)
            Button(lm.t("import_file")) { 
                showFilePicker = true 
            }
            .buttonStyle(GlassButtonStyle())
        }
        .padding()
    }
}

private struct FolderSectionView: View {
    let folder: Folder
    @Bindable var vm: SetsLibraryViewModel
    let onDrop: ([String]) -> Bool
    
    @Environment(LanguageManager.self) private var lm

    var body: some View {
        let isExpanded = !vm.expandedFolders.contains(folder.id)
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .foregroundColor(.secondary)
                    .animation(.spring(bounce: 0.2), value: isExpanded)
                
                if vm.renamingFolderID == folder.id {
                    TextField("", text: $vm.folderRenameText)
                        .textFieldStyle(.plain)
                        .font(.title3.bold())
                        .onSubmit {
                            vm.renameFolder(folder, to: vm.folderRenameText)
                            vm.renamingFolderID = nil
                        }
                } else {
                    Label(folder.name, systemImage: "folder.fill")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .onTapGesture(count: 2) {
                            vm.folderRenameText = folder.name
                            vm.renamingFolderID = folder.id
                        }
                }
                
                Spacer()
                
                if vm.dragOverFolderID == folder.id {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.glassCyan)
                }
            }
            .padding()
            .background(vm.dragOverFolderID == folder.id ? Color.glassCyan.opacity(0.15) : Color.white.opacity(0.01))
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(bounce: 0.2)) {
                    if vm.expandedFolders.contains(folder.id) {
                        vm.expandedFolders.remove(folder.id)
                    } else {
                        vm.expandedFolders.insert(folder.id)
                    }
                }
                _ = ()
            }
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(vm.dragOverFolderID == folder.id ? Color.cyan : Color.clear, lineWidth: 2)
            )
            
            if isExpanded && !folder.sets.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(folder.sets.sorted(by: { $0.name < $1.name })) { s in
                                NavigationLink(destination: SetDetailView(set: s)) {
                                    SetCard(set: s)
                                }.buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 14)
                    }
                    .transition(.opacity)
                }
                .clipped()
            }
        }
        .padding(.horizontal)
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
                        _ = withAnimation(.spring(bounce: 0.2)) {
                            vm.expandedFolders.remove(folder.id)
                        }
                    }
                    _ = ()
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
        VStack(alignment: .leading) {
            HStack {
                Text(lm.t("unfiled"))
                    .font(.title3.bold())
                    .foregroundColor(.white)
                Spacer()
                if dragOverUnfiled {
                    Image(systemName: "arrow.down.doc.fill")
                        .foregroundColor(.glassCyan)
                }
            }
            .padding()
            .background(dragOverUnfiled ? Color.glassCyan.opacity(0.15) : Color.white.opacity(0.01))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(dragOverUnfiled ? Color.cyan : Color.clear, lineWidth: 2)
            )
            .dropDestination(for: String.self) { ids, _ in
                onDrop(ids)
            } isTargeted: { targeted in
                dragOverUnfiled = targeted
            }
                
            if !ungroupedSets.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(ungroupedSets) { s in
                            NavigationLink(destination: SetDetailView(set: s)) {
                                SetCard(set: s)
                            }.buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
            }
        }
        .padding(.horizontal)
    }
}
