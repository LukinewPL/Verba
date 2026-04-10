import SwiftUI

struct SetDetailView: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.dismiss) private var dismiss
    @Bindable var set: WordSet

    private var masteredCount: Int {
        get { set.words.filter(\.isMastered).count }
    }

    private var progress: Double {
        get { Double(masteredCount) / Double(max(1, set.words.count)) }
    }

    private var isSourceToTarget: Bool {
        get { self.set.translationDirectionRaw == TranslationDirection.polishToEnglish.rawValue }
    }

    private var sourceLanguageCode: String {
        get { self.set.sourceLanguage.uppercased() }
    }

    private var targetLanguageCode: String {
        get { self.set.targetLanguage.uppercased() }
    }

    var body: some View {
        ZStack {
            detailBackground

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    headerCard
                    modeButtons
                    translationDirectionCard
                    wordsCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 20)
                .frame(maxWidth: 1120)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                }
            }
        }
        .toolbarBackground(.hidden, for: .windowToolbar)
    }

    private var headerCard: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text(set.name)
                    .font(.system(size: 28, weight: .medium, design: .default))
                    .foregroundColor(.white)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    statPill(icon: "text.book.closed.fill", text: "\(set.words.count) \(lm.t("words"))")
                    statPill(icon: "star.fill", text: "\(masteredCount)")
                }
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(colors: [.glassMint, .glassSky, .glassTeal], center: .center),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color.glassCyan.opacity(0.28), radius: 8, x: 0, y: 3)
                Text("\(Int(progress * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 60, height: 60)
        }
        .padding(14)
        .glassPanel(cornerRadius: 20)
    }

    private var modeButtons: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 10)], spacing: 10) {
            modeButton(title: lm.t("study"), icon: "book.fill") {
                coordinator.navigate(to: .studySession(set))
            }
            modeButton(title: lm.t("flashcards"), icon: "rectangle.stack.fill") {
                coordinator.navigate(to: .flashcards(set))
            }
            modeButton(title: lm.t("speed_round"), icon: "bolt.fill") {
                coordinator.navigate(to: .speedRound(set))
            }
            modeButton(title: lm.t("test"), icon: "checkmark.circle.fill") {
                coordinator.navigate(to: .test(set))
            }
        }
    }

    private var translationDirectionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(lm.t("translation"), systemImage: "arrow.left.arrow.right")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.82))

            HStack(spacing: 10) {
                directionButton(
                    label: "\(sourceLanguageCode) → \(targetLanguageCode)",
                    selected: isSourceToTarget
                ) {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        set.translationDirectionRaw = TranslationDirection.polishToEnglish.rawValue
                    }
                }
                directionButton(
                    label: "\(targetLanguageCode) → \(sourceLanguageCode)",
                    selected: !isSourceToTarget
                ) {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        set.translationDirectionRaw = TranslationDirection.englishToPolish.rawValue
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .glassPanel(cornerRadius: 16)
    }

    private var wordsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isSourceToTarget ? sourceLanguageCode : targetLanguageCode)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.62))
                Spacer()
                Text(isSourceToTarget ? targetLanguageCode : sourceLanguageCode)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.62))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            LazyVStack(spacing: 0) {
                ForEach(set.words) { w in
                    HStack(spacing: 12) {
                        Text(isSourceToTarget ? w.polish : w.english)
                            .foregroundColor(.white.opacity(0.95))
                            .lineLimit(2)

                        Spacer(minLength: 20)

                        Text(isSourceToTarget ? w.english : w.polish)
                            .foregroundColor(.white.opacity(0.86))
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)

                        if w.isMastered {
                            Image(systemName: "star.fill")
                                .foregroundStyle(Color.glassMint)
                        }
                    }
                    .font(.system(size: 19, weight: .medium, design: .default))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)

                    Divider()
                        .overlay(Color.white.opacity(0.1))
                }
            }
        }
        .padding(.bottom, 6)
        .glassPanel(cornerRadius: 18)
    }

    private func modeButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.glassCyan)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 88)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func directionButton(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                    .background(
                    Capsule()
                        .fill(
                            selected
                            ? LinearGradient(colors: [Color.glassMint.opacity(0.5), Color.glassSky.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .overlay(
                            Capsule()
                                .stroke(selected ? Color.glassTeal.opacity(0.48) : Color.white.opacity(0.16), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func statPill(icon: String, text: String) -> some View {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(Color.glassTeal)
                Text(text)
                    .foregroundColor(.white.opacity(0.84))
            }
        .font(.caption.weight(.medium))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
                .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1))
        )
    }

    private var detailBackground: some View {
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
                startRadius: 50,
                endRadius: 520
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.glassSky.opacity(0.14), .clear],
                center: .bottomLeading,
                startRadius: 80,
                endRadius: 620
            )
            .ignoresSafeArea()
        }
    }
}
