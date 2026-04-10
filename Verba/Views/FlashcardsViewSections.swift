import SwiftUI

struct FlashcardsProgressSection: View {
    @Environment(LanguageManager.self) private var lm
    @Bindable var vm: FlashcardsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(lm.t("flashcards"))
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.94))
                Spacer()
                Text("\(vm.currentPosition) / \(vm.totalCount)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.glassTeal)
            }
            ProgressView(value: vm.progress)
                .tint(.glassTeal)
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
}

struct FlashcardsMainCardSection: View {
    @Bindable var vm: FlashcardsViewModel
    let cardCornerRadius: CGFloat
    let rotation: Double
    let dragOffset: CGSize
    let showingBack: Bool
    let cardOpacity: Double
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    let onCardTapped: () -> Void

    var body: some View {
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
                    accent: showingBack ? .glassMint : .glassTeal,
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
                        .onChanged(onDragChanged)
                        .onEnded(onDragEnded)
                )
                .onTapGesture(perform: onCardTapped)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: 680, minHeight: 280, idealHeight: 420, maxHeight: 440)
    }
}

struct FlashcardsControlsSection: View {
    @Environment(LanguageManager.self) private var lm
    let canGoBack: Bool
    let onPrevious: () -> Void
    let onFlip: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                controlButton(
                    title: lm.t("previous"),
                    icon: "chevron.left",
                    tint: .glassSky,
                    shortcut: .leftArrow,
                    isDisabled: !canGoBack,
                    action: onPrevious
                )
                controlButton(
                    title: lm.t("flip"),
                    icon: "arrow.triangle.2.circlepath",
                    tint: .glassCyan,
                    shortcut: .space,
                    action: onFlip
                )
                controlButton(
                    title: lm.t("next"),
                    icon: "chevron.right",
                    tint: .glassMint,
                    shortcut: .rightArrow,
                    action: onNext
                )
            }
            Text(lm.t("flashcards_swipe_hint"))
                .font(.footnote)
                .foregroundColor(.white.opacity(0.58))
        }
        .frame(maxWidth: 520)
    }

    private func controlButton(
        title: String,
        icon: String,
        tint: Color,
        shortcut: KeyEquivalent,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
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
        .keyboardShortcut(shortcut, modifiers: [])
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
    }
}

struct FlashcardsCompletionSection: View {
    @Environment(LanguageManager.self) private var lm
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.glassMint.opacity(0.15))
                    .frame(width: 124, height: 124)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 54))
                    .foregroundColor(.glassTeal)
            }

            VStack(spacing: 8) {
                Text(lm.t("done"))
                    .font(.largeTitle.weight(.semibold))
                    .foregroundColor(.white)
                Text(lm.t("flashcards_completed_subtitle"))
                    .font(.body.weight(.medium))
                    .foregroundColor(.white.opacity(0.68))
            }

            Button(lm.t("finish"), action: onFinish)
                .buttonStyle(GlassButtonStyle())
                .frame(width: 200)
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
                            colors: [Color(red: 0.08, green: 0.22, blue: 0.22), Color(red: 0.10, green: 0.28, blue: 0.26)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(accent.opacity(0.55), lineWidth: 1.2)
                )
                .shadow(color: Color.glassShadow.opacity(0.2), radius: 14, x: 0, y: 8)

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
