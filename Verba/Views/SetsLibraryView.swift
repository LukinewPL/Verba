import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SetsLibraryView: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(WordRepository.self) private var repository
    @Environment(AppCoordinator.self) private var coordinator
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
        .onChange(of: coordinator.path) { _, _ in
            vm.refresh()
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
                        Label("\(vm.allSets.count) \(lm.t("sets"))", systemImage: "text.book.closed.fill")
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
        .glassPanel(cornerRadius: 20)
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
                colors: [Color(red: 0.04, green: 0.12, blue: 0.15), Color.glassBack],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.glassMint.opacity(0.18), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 560
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.glassSky.opacity(0.14), .clear],
                center: .bottomLeading,
                startRadius: 80,
                endRadius: 660
            )
            .ignoresSafeArea()
        }
    }
}
