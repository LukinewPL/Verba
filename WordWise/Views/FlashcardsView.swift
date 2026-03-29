import SwiftUI

struct FlashcardsView: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(AppCoordinator.self) private var coordinator
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
                    progressSection
                }

                if vm.current != nil {
                    mainCard
                } else {
                    completionView
                }

                if vm.current != nil {
                    controls
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
                Button(action: {
                    vm.reset()
                    dragOffset = .zero
                    rotation = 0
                    showingBack = false
                }) {
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

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(lm.t("flashcards"))
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.94))
                Spacer()
                Text("\(vm.currentPosition) / \(vm.totalCount)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.glassCyan)
            }
            ProgressView(value: vm.progress)
                .tint(.glassCyan)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.13), lineWidth: 1)
        )
        .frame(maxWidth: 680)
    }

    private var mainCard: some View {
        GeometryReader { proxy in
            let width = min(max(proxy.size.width * 0.9, 280), 560)
            let height = width * 0.62

            ZStack {
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: width - 12, height: height)
                    .offset(y: 10)

                FlashcardFace(
                    text: showingBack ? vm.backText : vm.frontText,
                    languageCode: showingBack ? vm.backLanguageCode : vm.frontLanguageCode,
                    accent: showingBack ? .mint : .glassCyan,
                    cornerRadius: cardCornerRadius,
                    isBack: showingBack
                )
                .frame(width: width, height: height)
                .rotation3DEffect(
                    .degrees(rotation + Double(dragOffset.width / 18)),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.75
                )
                .offset(dragOffset)
                .opacity(cardOpacity)
                .contentShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            dragOffset = CGSize(width: gesture.translation.width, height: gesture.translation.height * 0.18)
                        }
                        .onEnded { gesture in
                            let commitThreshold: CGFloat = 120
                            let projectedX = gesture.predictedEndTranslation.width
                            let effectiveX = abs(projectedX) > abs(gesture.translation.width)
                                ? projectedX
                                : gesture.translation.width
                            
                            if abs(effectiveX) >= commitThreshold {
                                skipToNext(direction: effectiveX > 0 ? 1 : -1)
                            } else {
                                withAnimation(.easeOut(duration: 0.12)) {
                                    dragOffset = .zero
                                }
                            }
                        }
                )
                .onTapGesture {
                    flipCard()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: 680, minHeight: 280, idealHeight: 420, maxHeight: 440)
    }

    private var controls: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                controlButton(title: lm.t("flip"), icon: "arrow.triangle.2.circlepath", tint: .glassCyan) {
                    flipCard()
                }
                controlButton(title: lm.t("next"), icon: "chevron.right", tint: .mint) {
                    skipToNext(direction: -1)
                }
            }
            Text(lm.t("flashcards_swipe_hint"))
                .font(.footnote)
                .foregroundColor(.white.opacity(0.58))
        }
        .frame(maxWidth: 520)
    }

    private func controlButton(title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.headline.weight(.semibold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(tint.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(tint.opacity(0.45), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.glassCyan.opacity(0.15))
                    .frame(width: 124, height: 124)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 54))
                    .foregroundColor(.glassCyan)
            }

            VStack(spacing: 8) {
                Text(lm.t("done"))
                    .font(.largeTitle.weight(.semibold))
                    .foregroundColor(.white)
                Text(lm.t("flashcards_completed_subtitle"))
                    .font(.body.weight(.medium))
                    .foregroundColor(.white.opacity(0.68))
            }

            Button(lm.t("finish")) { dismiss() }
                .buttonStyle(GlassButtonStyle())
                .frame(width: 200)
        }
    }

    private func flipCard() {
        guard !isFlipping, vm.current != nil else { return }
        isFlipping = true

        withAnimation(.easeIn(duration: 0.11)) {
            rotation = 90
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            showingBack.toggle()
            rotation = -90
            withAnimation(.easeOut(duration: 0.13)) {
                rotation = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
                isFlipping = false
            }
        }
    }

    private func skipToNext(direction: CGFloat) {
        guard vm.current != nil, !isAdvancing else { return }
        isAdvancing = true

        withAnimation(.easeIn(duration: 0.16)) {
            dragOffset = CGSize(width: direction * 760, height: 90)
            cardOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            vm.nextWord()
            showingBack = false
            rotation = 0
            isFlipping = false
            dragOffset = CGSize(width: -direction * 120, height: -12)
            cardOpacity = 0

            withAnimation(.easeOut(duration: 0.14)) {
                dragOffset = .zero
                cardOpacity = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                isAdvancing = false
            }
        }
    }
}

struct FlashcardFace: View {
    let text: String
    let languageCode: String
    let accent: Color
    let cornerRadius: CGFloat
    let isBack: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.13, green: 0.2, blue: 0.3), Color(red: 0.09, green: 0.16, blue: 0.24)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(accent.opacity(0.55), lineWidth: 1.2)
                )
                .shadow(color: .black.opacity(0.2), radius: 14, x: 0, y: 8)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    languageBadge
                    Spacer()
                    Image(systemName: isBack ? "quote.bubble.fill" : "text.book.closed.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(accent.opacity(0.95))
                }

                Spacer(minLength: 0)

                Text(text)
                    .font(.system(size: 36, weight: .medium, design: .default))
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.6)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 0)
            }
            .padding(24)
        }
    }

    private var languageBadge: some View {
        Text(languageDisplayName(languageCode))
            .font(.caption.weight(.semibold))
            .foregroundColor(.white.opacity(0.94))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(accent.opacity(0.25))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(accent.opacity(0.55), lineWidth: 1)
            )
    }

    private func languageDisplayName(_ code: String) -> String {
        Locale.current.localizedString(forLanguageCode: code)?.capitalized ?? code.uppercased()
    }
}
