import SwiftUI

struct TestSetupView: View {
    @Environment(LanguageManager.self) private var lm
    @Bindable var vm: TestViewModel
    let set: WordSet
    let onStart: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.glassCyan.opacity(0.14))
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(.white, Color.glassCyan)
                    }
                    .frame(width: 46, height: 46)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(lm.t("test_setup"))
                            .font(.system(size: 26, weight: .medium, design: .default))
                            .foregroundColor(.white)
                        Text(set.name)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.62))
                            .lineLimit(1)
                    }

                    Spacer()

                    TestStatChip(icon: "text.book.closed.fill", label: "\(set.words.count) \(lm.t("words"))")
                }
                .padding(14)
                .glassPanel(cornerRadius: 20, edgeHighlight: Color.glassCyan.opacity(0.2))

                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(lm.t("questions"))
                                .font(.system(size: 18, weight: .medium, design: .default))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(Int(vm.questionCount))")
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundStyle(Color.glassCyan)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.glassCyan.opacity(0.2))
                                        .overlay(Capsule().stroke(Color.glassCyan.opacity(0.45), lineWidth: 1))
                                )
                        }

                        Slider(value: $vm.questionCount, in: 5...50, step: 5)
                            .tint(.glassCyan)

                        HStack {
                            Text("5")
                            Spacer()
                            Text("25")
                            Spacer()
                            Text("50")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.55))
                    }
                    .padding(12)
                    .glassPanel(cornerRadius: 14, edgeHighlight: Color.white.opacity(0.14))

                    VStack(alignment: .leading, spacing: 12) {
                        Text(lm.t("multiple_choice"))
                            .font(.system(size: 15, weight: .medium, design: .default))
                            .foregroundColor(.white.opacity(0.86))

                        HStack(spacing: 8) {
                            TestModeButton(
                                title: lm.t("multiple_choice"),
                                icon: "list.bullet.rectangle.portrait.fill",
                                isSelected: vm.isMultipleChoice,
                                action: { vm.isMultipleChoice = true }
                            )

                            TestModeButton(
                                title: lm.t("translation"),
                                icon: "keyboard.fill",
                                isSelected: !vm.isMultipleChoice,
                                action: { vm.isMultipleChoice = false }
                            )
                        }
                    }
                }
                .padding(14)
                .glassPanel(cornerRadius: 20)

                Button(action: onStart) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.headline.weight(.semibold))
                        Text(lm.t("start"))
                            .font(.system(size: 18, weight: .medium, design: .default))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [Color.glassCyan.opacity(0.95), Color.blue.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.26), lineWidth: 1)
                    )
                    .shadow(color: Color.glassCyan.opacity(0.24), radius: 12, x: 0, y: 7)
                }
                .buttonStyle(.plain)
                .pressAnimation()
            }
            .padding(.top, 10)
            .padding(.bottom, 18)
        }
    }
}
