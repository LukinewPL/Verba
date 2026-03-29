import SwiftUI

// MARK: - View

struct MainCoordinatorView: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(AppCoordinator.self) private var coordinator
    @State private var errorHandler = ErrorHandler.shared
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        @Bindable var coordinator = coordinator
        @Bindable var eh = errorHandler
        
        return NavigationSplitView(columnVisibility: $sidebarVisibility) {
            sidebarContent
        } detail: {
            detailContent
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            syncSidebarVisibility()
        }
        .onChange(of: coordinator.isInFocusedMode) { _, _ in
            syncSidebarVisibility()
        }
        .onChange(of: coordinator.path) { _, _ in
            syncSidebarVisibility()
        }
        .animation(.easeInOut(duration: 0.22), value: sidebarVisibility)
        .frame(minWidth: 700, minHeight: 500)
        .alert(lm.t("error_occurred"), isPresented: $eh.showErrorMessage) {
            Button(lm.t("ok"), role: .cancel) { eh.clear() }
        } message: {
            if let error = eh.currentError {
                Text(error.localizedDescription)
            }
        }
    }
    
    @ViewBuilder
    private func screenView(for screen: AppScreen) -> some View {
        switch screen {
        case .home: HomeView()
        case .library: SetsLibraryView()
        case .setDetail(let set): SetDetailView(set: set)
        case .studySession(let set): StudySessionView(set: set)
        case .speedRound(let set): SpeedRoundView(set: set)
        case .test(let set): TestView(set: set)
        case .flashcards(let set): FlashcardsView(set: set)
        case .settings: SettingsView()
        }
    }
    
    private var sidebarContent: some View {
        ZStack {
            sidebarBackground
            
            VStack(alignment: .leading, spacing: 14) {
                sidebarHeader
                
                VStack(spacing: 10) {
                    sidebarTabButton(tab: .home, title: lm.t("home"), icon: "house.fill")
                    sidebarTabButton(tab: .library, title: lm.t("sets_library"), icon: "books.vertical.fill")
                    sidebarTabButton(tab: .settings, title: lm.t("settings"), icon: "gearshape.fill")
                }
                .padding(10)
                .sidebarPanel(cornerRadius: 20, edgeHighlight: Color.white.opacity(0.15))
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
        }
    }
    
    private var detailContent: some View {
        ZStack {
            LinearGradient(
                colors: [.deepNavy, .glassBack],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            NavigationStack(path: pathBinding) {
                Group {
                    switch coordinator.selectedTab {
                    case .home:
                        HomeView()
                    case .library:
                        SetsLibraryView()
                    case .settings:
                        SettingsView()
                    }
                }
            }
            .navigationDestination(for: AppScreen.self) { screen in
                screenView(for: screen)
            }
            .toolbarBackground(.hidden, for: .windowToolbar)
        }
        .background(Color.clear)
    }
    
    private var sidebarHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "text.book.closed.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.glassCyan)
                .frame(width: 42, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(Color.glassCyan.opacity(0.16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(Color.glassCyan.opacity(0.4), lineWidth: 1)
                        )
                )
            
            Text(lm.t("WordWise"))
                .font(.system(size: 25, weight: .semibold, design: .default))
                .tracking(0.2)
                .lineLimit(1)
                .foregroundStyle(.white)
                .offset(y: -0.5)
            
            Spacer()
        }
        .padding(14)
        .sidebarPanel(cornerRadius: 20, edgeHighlight: Color.glassCyan.opacity(0.2))
    }
    
    private func sidebarTabButton(tab: AppCoordinator.Tab, title: String, icon: String) -> some View {
        let isSelected = coordinator.selectedTab == tab
        
        return Button {
            select(tab: tab)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(isSelected ? Color.glassCyan : Color.white.opacity(0.84))
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSelected ? Color.glassCyan.opacity(0.18) : Color.white.opacity(0.08))
                    )
                
                Text(title)
                    .font(.system(size: 20, weight: .medium, design: .default))
                    .foregroundStyle(.white.opacity(0.95))
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.glassCyan.opacity(0.92))
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                isSelected
                                ? LinearGradient(
                                    colors: [Color.glassCyan.opacity(0.24), Color.blue.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? Color.glassCyan.opacity(0.46) : Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private func select(tab: AppCoordinator.Tab) {
        withAnimation(.easeInOut(duration: 0.2)) {
            coordinator.selectedTab = tab
        }
        
        if !coordinator.path.isEmpty {
            coordinator.popToRoot()
        }
    }
    
    private var pathBinding: Binding<[AppScreen]> {
        Binding(
            get: { coordinator.path },
            set: { coordinator.path = $0 }
        )
    }
    
    private func isSidebarHiddenMode(_ screen: AppScreen) -> Bool {
        switch screen {
        case .studySession, .speedRound, .test, .flashcards:
            return true
        default:
            return false
        }
    }
    
    private func syncSidebarVisibility() {
        let shouldHide = coordinator.isInFocusedMode || (coordinator.path.last.map(isSidebarHiddenMode) ?? false)
        let target: NavigationSplitViewVisibility = shouldHide ? .detailOnly : .all
        
        guard sidebarVisibility != target else { return }
        
        withAnimation(.easeInOut(duration: 0.22)) {
            sidebarVisibility = target
        }
    }
    
    private var sidebarBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.06, blue: 0.2),
                    Color(red: 0.02, green: 0.11, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            RadialGradient(
                colors: [Color.glassCyan.opacity(0.16), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()
            
            RadialGradient(
                colors: [Color.blue.opacity(0.16), .clear],
                center: .bottomLeading,
                startRadius: 50,
                endRadius: 500
            )
            .ignoresSafeArea()
        }
    }
}

private extension View {
    func sidebarPanel(cornerRadius: CGFloat = 20, edgeHighlight: Color = Color.glassCyan.opacity(0.18)) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(edgeHighlight, lineWidth: 1.1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            .blur(radius: 0.2)
                    )
                    .shadow(color: .black.opacity(0.24), radius: 20, x: 0, y: 10)
            )
    }
}
