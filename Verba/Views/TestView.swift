import SwiftUI
import SwiftData

struct TestView: View {
    @Environment(LanguageManager.self) private var lm
    @Bindable var set: WordSet
    @State private var vm: TestViewModel

    @Environment(WordRepository.self) private var repository
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.dismiss) private var dismiss
    @State private var showExitConfirm = false
    @FocusState private var isOpenAnswerFocused: Bool
    @State private var focusTask: Task<Void, Never>?

    init(set: WordSet) {
        self.set = set
        _vm = State(initialValue: TestViewModel(set: set))
    }

    var body: some View {
        ZStack {
            testBackground

            contentView
                .frame(maxWidth: 980)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
        }
        .overlay {
            if vm.feedbackColor != .clear {
                DesignSystem.Feedback.gradient(isSuccess: vm.feedbackIsSuccess)
                    .opacity(0.24)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            coordinator.enterFocusedMode()
            vm.setup(repository: repository, dismiss: { dismiss() })
            vm.reset()
        }
        .onChange(of: vm.currentIdx) { _, _ in
            requestOpenAnswerFocus()
        }
        .onChange(of: vm.isSetup) { _, _ in
            requestOpenAnswerFocus()
        }
        .onChange(of: vm.isMultipleChoice) { _, _ in
            requestOpenAnswerFocus()
        }
        .onDisappear {
            focusTask?.cancel()
            focusTask = nil
            coordinator.exitFocusedMode()
            isOpenAnswerFocused = false
            vm.abandonTest()
        }
        .alert(lm.t("finish"), isPresented: $showExitConfirm) {
            Button(lm.t("cancel"), role: .cancel) { }
            Button(lm.t("finish"), role: .destructive) {
                vm.abandonTest()
                dismiss()
            }
        } message: {
            Text(lm.t("undone_msg"))
        }
        .navigationTitle(lm.t("test"))
        .toolbarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .windowToolbar)
    }

    @ViewBuilder
    private var contentView: some View {
        if vm.isSetup {
            TestSetupView(vm: vm, set: set) {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                    vm.startTest()
                }
            }
        } else if vm.isFinished {
            TestResultsView(vm: vm) {
                vm.finishTestAndSave()
            }
        } else {
            TestQuestionView(
                vm: vm,
                openAnswerFocus: $isOpenAnswerFocused,
                onExitRequested: { showExitConfirm = true },
                onRequestFocus: requestOpenAnswerFocus
            )
        }
    }

    private func requestOpenAnswerFocus() {
        focusTask?.cancel()
        guard !vm.isSetup, !vm.isFinished, !vm.isMultipleChoice else {
            isOpenAnswerFocused = false
            return
        }

        focusTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000)
            guard !Task.isCancelled else { return }
            guard !vm.isSetup, !vm.isFinished, !vm.isMultipleChoice, vm.selectedOption == nil else { return }
            isOpenAnswerFocused = true
        }
    }

    private var testBackground: some View {
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
                startRadius: 30,
                endRadius: 520
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.glassSky.opacity(0.16), .clear],
                center: .bottomLeading,
                startRadius: 40,
                endRadius: 600
            )
            .ignoresSafeArea()
        }
    }
}
