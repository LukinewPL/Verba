import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(\.modelContext) private var ctx
    @AppStorage("animationSpeed") var animationSpeed: Double = 1.0
    @State private var errorHandler = ErrorHandler.shared
    @State private var showResetAlert = false

    private let legendColumns = [
        GridItem(.flexible(minimum: 140), spacing: 12),
        GridItem(.flexible(minimum: 140), spacing: 12)
    ]

    var body: some View {
        ZStack {
            settingsBackground

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    headerCard
                    languageCard

                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 16) {
                            legendCard.frame(maxWidth: .infinity)
                            animationCard.frame(maxWidth: .infinity)
                        }

                        VStack(spacing: 16) {
                            legendCard
                            animationCard
                        }
                    }

                    resetCard
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 30)
                .frame(maxWidth: 1020)
                .frame(maxWidth: .infinity)
            }
        }
        .alert(lm.t("reset_all_data_q"), isPresented: $showResetAlert) {
            Button(lm.t("cancel"), role: .cancel) { }
            Button(lm.t("reset"), role: .destructive) { resetAll() }
        } message: {
            Text(lm.t("undone_msg"))
        }
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Color.glassCyan)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(Color.glassCyan.opacity(0.12))
                        .overlay(
                            Circle()
                                .stroke(Color.glassCyan.opacity(0.38), lineWidth: 1)
                        )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(lm.t("settings"))
                    .font(.system(size: 34, weight: .medium, design: .default))
                    .foregroundColor(.white)
                Text(lm.t("Verba"))
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(22)
        .glassPanel(cornerRadius: 28, edgeHighlight: Color.glassCyan.opacity(0.22), gradientTopOpacity: 0.1, gradientBottomOpacity: 0.05, borderOpacity: 0.18, shadowOpacity: 0.24, shadowRadius: 22, shadowY: 10)
    }

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(lm.t("app_language"), icon: "globe")

            VStack(spacing: 10) {
                ForEach(lm.availableLanguages) { lang in
                    languageOptionRow(for: lang)
                }
            }
        }
        .padding(20)
        .glassPanel(cornerRadius: 22, edgeHighlight: Color.glassCyan.opacity(0.18), gradientTopOpacity: 0.1, gradientBottomOpacity: 0.05, borderOpacity: 0.18, shadowOpacity: 0.24, shadowRadius: 22, shadowY: 10)
    }

    private func languageOptionRow(for lang: LanguageInfo) -> some View {
        let selected = lm.selectedCode == lang.language_code

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                lm.selectedCode = lang.language_code
            }
        } label: {
            HStack(spacing: 12) {
                Text(lang.language_name)
                    .font(.system(size: 22, weight: .medium, design: .default))
                    .foregroundColor(.white)

                Spacer()

                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.glassCyan)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                selected
                                ? LinearGradient(
                                    colors: [Color.glassCyan.opacity(0.24), Color.blue.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.09), Color.white.opacity(0.04)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selected ? Color.glassCyan.opacity(0.45) : Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var legendCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(lm.t("legend"), icon: "sparkles")

            LazyVGrid(columns: legendColumns, spacing: 12) {
                legendTile(icon: "book.fill", label: lm.t("study"), tint: .glassCyan)
                legendTile(icon: "rectangle.stack.fill", label: lm.t("flashcards"), tint: Color(red: 0.5, green: 0.8, blue: 1.0))
                legendTile(icon: "bolt.fill", label: lm.t("speed_round"), tint: Color(red: 0.43, green: 0.85, blue: 0.96))
                legendTile(icon: "checkmark.circle.fill", label: lm.t("test"), tint: Color(red: 0.37, green: 0.93, blue: 0.83))
            }
        }
        .padding(20)
        .glassPanel(cornerRadius: 22, edgeHighlight: Color.glassCyan.opacity(0.18), gradientTopOpacity: 0.1, gradientBottomOpacity: 0.05, borderOpacity: 0.18, shadowOpacity: 0.24, shadowRadius: 22, shadowY: 10)
    }

    private func legendTile(icon: String, label: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tint.opacity(0.15))
                )

            Text(label)
                .font(.system(size: 20, weight: .medium, design: .default))
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var animationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionTitle(lm.t("animation_speed"), icon: "dial.medium")
                Spacer()
                Text(animationSpeed == 0 ? lm.t("off") : String(format: "%.1fx", animationSpeed))
                    .font(.system(size: 22, weight: .medium, design: .default))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.glassCyan.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(Color.glassCyan.opacity(0.4), lineWidth: 1)
                            )
                    )
            }

            VStack(spacing: 10) {
                Slider(value: $animationSpeed, in: 0.0...2.0, step: 0.5)
                    .tint(.glassCyan)

                HStack {
                    Text("0x").foregroundColor(.white.opacity(0.55))
                    Spacer()
                    Text("1x").foregroundColor(.white.opacity(0.55))
                    Spacer()
                    Text("2x").foregroundColor(.white.opacity(0.55))
                }
                .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.glassCyan.opacity(0.22), lineWidth: 1)
                    )
            )
        }
        .padding(20)
        .glassPanel(cornerRadius: 22, edgeHighlight: Color.glassCyan.opacity(0.18), gradientTopOpacity: 0.1, gradientBottomOpacity: 0.05, borderOpacity: 0.18, shadowOpacity: 0.24, shadowRadius: 22, shadowY: 10)
    }

    private var resetCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red.opacity(0.9))
                Text(lm.t("reset_all_data"))
                    .font(.system(size: 20, weight: .medium, design: .default))
                    .foregroundColor(.white)
            }

            Button(role: .destructive, action: { showResetAlert = true }) {
                Text(lm.t("reset_all_data"))
                    .font(.headline)
                    .foregroundColor(.red.opacity(0.95))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.red.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.red.opacity(0.45), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .glassPanel(cornerRadius: 22, edgeHighlight: Color.red.opacity(0.22), gradientTopOpacity: 0.1, gradientBottomOpacity: 0.05, borderOpacity: 0.18, shadowOpacity: 0.24, shadowRadius: 22, shadowY: 10)
    }

    private func sectionTitle(_ text: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.glassCyan)
            Text(text)
                .font(.system(size: 22, weight: .medium, design: .default))
                .foregroundColor(.white)
        }
    }

    private var settingsBackground: some View {
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
                colors: [Color.glassCyan.opacity(0.18), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 520
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.blue.opacity(0.18), .clear],
                center: .bottomLeading,
                startRadius: 60,
                endRadius: 620
            )
            .ignoresSafeArea()
        }
    }

    private func resetAll() {
        do {
            try ctx.delete(model: WordSet.self)
            try ctx.delete(model: StudySession.self)
            try ctx.delete(model: Word.self)
            try ctx.save()
        } catch {
            errorHandler.handle(error)
        }
    }
}
