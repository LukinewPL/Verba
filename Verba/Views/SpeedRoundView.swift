import SwiftUI
import SwiftData
import Combine

struct SpeedRoundView: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(WordRepository.self) private var repository
    @Environment(AppCoordinator.self) private var coordinator
    @State private var vm: SpeedRoundViewModel
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var pendingTransitionTask: Task<Void, Never>?

    private let timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(set: WordSet) {
        _vm = State(initialValue: SpeedRoundViewModel(set: set))
    }

    var body: some View {
        ZStack {
            speedBackground

            Group {
                if !vm.isStarted {
                    SpeedRoundStartSection(vm: vm) {
                        vm.startGame()
                        scheduleTransition(after: 0.45) {
                            isFocused = true
                        }
                    }
                } else if vm.isFinished {
                    SpeedRoundFinishedSection(vm: vm) {
                        dismiss()
                    }
                } else {
                    SpeedRoundGameSection(
                        vm: vm,
                        focusBinding: $isFocused,
                        onSubmitAnswer: checkAnswer
                    )
                }
            }
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .overlay {
            vm.feedbackColor.opacity(0.24)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onReceive(timerPublisher) { _ in
            vm.tick()
        }
        .onAppear {
            coordinator.enterFocusedMode()
            vm.setup(repository: repository)
        }
        .onDisappear {
            pendingTransitionTask?.cancel()
            pendingTransitionTask = nil
            coordinator.exitFocusedMode()
            vm.saveSession()
        }
        .navigationTitle(lm.t("speed_round"))
        .toolbarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .windowToolbar)
    }

    private func checkAnswer() {
        vm.checkAnswer(
            onSuccess: {
                scheduleTransition(after: 0.2) {
                    vm.feedbackColor = .clear
                    vm.nextWord()
                    isFocused = true
                }
            },
            onFailure: {
                scheduleTransition(after: 1.5) {
                    vm.showWrongAnswer = false
                    vm.feedbackColor = .clear
                    vm.answer = ""
                    vm.nextWord()
                    isFocused = true
                }
            }
        )
    }

    private func scheduleTransition(after seconds: Double, action: @escaping @MainActor () -> Void) {
        pendingTransitionTask?.cancel()
        pendingTransitionTask = Task { @MainActor in
            let delay = UInt64(max(0, seconds) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }
            action()
        }
    }

    private var speedBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.04, blue: 0.2),
                    Color(red: 0.02, green: 0.03, blue: 0.17)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.glassCyan.opacity(0.18), .clear],
                center: .top,
                startRadius: 20,
                endRadius: 500
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.blue.opacity(0.16), .clear],
                center: .bottomTrailing,
                startRadius: 60,
                endRadius: 620
            )
            .ignoresSafeArea()
        }
    }
}
