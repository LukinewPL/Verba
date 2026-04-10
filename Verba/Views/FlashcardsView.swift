import SwiftUI

struct FlashcardsView: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(AppCoordinator.self) private var coordinator
    @AppStorage("animationSpeed") private var animationSpeed: Double = 1.0
    @State private var vm: FlashcardsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var rotation: Double = 0
    @State private var dragOffset: CGSize = .zero
    @State private var showingBack = false
    @State private var isFlipping = false
    @State private var isAdvancing = false
    @State private var cardOpacity: Double = 1

    private let cardCornerRadius: CGFloat = 30

    init(set: WordSet) {
        _vm = State(initialValue: FlashcardsViewModel(set: set))
    }

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()
            backgroundAccent

            VStack(spacing: 18) {
                if vm.current != nil {
                    FlashcardsProgressSection(vm: vm)
                }

                if vm.current != nil {
                    FlashcardsMainCardSection(
                        vm: vm,
                        cardCornerRadius: cardCornerRadius,
                        rotation: rotation,
                        dragOffset: dragOffset,
                        showingBack: showingBack,
                        cardOpacity: cardOpacity,
                        onDragChanged: { gesture in
                            dragOffset = CGSize(width: gesture.translation.width, height: gesture.translation.height * 0.18)
                        },
                        onDragEnded: handleCardDragEnd,
                        onCardTapped: flipCard
                    )
                } else {
                    FlashcardsCompletionSection {
                        dismiss()
                    }
                }

                if vm.current != nil {
                    FlashcardsControlsSection(
                        canGoBack: vm.canGoBack,
                        onPrevious: { skipToPrevious(direction: -1) },
                        onFlip: flipCard,
                        onNext: { skipToNext(direction: 1) }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: resetDeck) {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
        }
        .navigationTitle(lm.t("flashcards"))
        .toolbarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .windowToolbar)
        .onAppear {
            coordinator.enterFocusedMode()
        }
        .onDisappear {
            coordinator.exitFocusedMode()
        }
    }

    private var backgroundAccent: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.02),
                Color.glassCyan.opacity(0.03),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func resetDeck() {
        vm.reset()
        dragOffset = .zero
        rotation = 0
        showingBack = false
        isFlipping = false
        isAdvancing = false
        cardOpacity = 1
    }

    private func handleCardDragEnd(_ gesture: DragGesture.Value) {
        let commitThreshold: CGFloat = 120
        let projectedX = gesture.predictedEndTranslation.width
        let effectiveX = abs(projectedX) > abs(gesture.translation.width)
            ? projectedX
            : gesture.translation.width

        if abs(effectiveX) >= commitThreshold {
            skipToNext(direction: effectiveX > 0 ? 1 : -1)
        } else {
            withAnimation(.easeOut(duration: adjustedDuration(0.12))) {
                dragOffset = .zero
            }
        }
    }

    private func flipCard() {
        guard !isFlipping, vm.current != nil else { return }
        isFlipping = true

        withAnimation(.easeIn(duration: adjustedDuration(0.11))) {
            rotation = 90
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + adjustedDuration(0.11)) {
            showingBack.toggle()
            rotation = -90
            withAnimation(.easeOut(duration: adjustedDuration(0.13))) {
                rotation = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + adjustedDuration(0.13)) {
                isFlipping = false
            }
        }
    }

    private func skipToNext(direction: CGFloat) {
        guard vm.current != nil, !isAdvancing else { return }
        isAdvancing = true

        withAnimation(.easeIn(duration: adjustedDuration(0.16))) {
            dragOffset = CGSize(width: direction * 760, height: 90)
            cardOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + adjustedDuration(0.16)) {
            vm.goToNextWord()
            completeCardTransition(oppositeDirection: -direction)
        }
    }

    private func skipToPrevious(direction: CGFloat) {
        guard vm.current != nil, !isAdvancing else { return }
        guard vm.goToPreviousWord() else { return }
        isAdvancing = true

        dragOffset = CGSize(width: direction * 120, height: -12)
        cardOpacity = 0
        showingBack = false
        rotation = 0
        isFlipping = false

        withAnimation(.easeOut(duration: adjustedDuration(0.18))) {
            dragOffset = .zero
            cardOpacity = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + adjustedDuration(0.18)) {
            isAdvancing = false
        }
    }

    private func completeCardTransition(oppositeDirection: CGFloat) {
        showingBack = false
        rotation = 0
        isFlipping = false
        dragOffset = CGSize(width: oppositeDirection * 120, height: -12)
        cardOpacity = 0

        withAnimation(.easeOut(duration: adjustedDuration(0.14))) {
            dragOffset = .zero
            cardOpacity = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + adjustedDuration(0.14)) {
            isAdvancing = false
        }
    }

    private func adjustedDuration(_ base: Double) -> Double {
        guard animationSpeed > 0 else { return 0.01 }
        return base / animationSpeed
    }
}
