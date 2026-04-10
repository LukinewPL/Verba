import SwiftUI

struct ImportConfirmationView: View {
    @Environment(LanguageManager.self) private var lm
    @Binding var config: ImportConfiguration?
    var onConfirm: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text(lm.t("import_file"))
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
            
            if let config = config {
                VStack(alignment: .leading, spacing: 18) {
                    Text(config.name)
                        .font(.headline)
                        .foregroundColor(.glassTeal)
                    
                    Text(lm.t("import_language_detection_info"))
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.65))
                    
                    HStack(spacing: 20) {
                        LanguageColumn(
                            title: lm.t("first_column"),
                            lang: Binding(
                                get: { self.config?.lang1 },
                                set: { self.config?.lang1 = $0 }
                            ),
                            sample: config.rows.first?.first ?? ""
                        )
                        
                        Image(systemName: "arrow.left.and.right")
                            .foregroundColor(.glassSky.opacity(0.8))
                        
                        LanguageColumn(
                            title: lm.t("second_column"),
                            lang: Binding(
                                get: { self.config?.lang2 },
                                set: { self.config?.lang2 = $0 }
                            ),
                            sample: config.rows.first?.last ?? ""
                        )
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    
                    if let source = effectiveSourceLanguage, let target = effectiveTargetLanguage {
                            HStack(spacing: 8) {
                            Text(lm.t("import_direction"))
                                .foregroundColor(.white.opacity(0.65))
                            Text("\(localizedLanguageName(source)) → \(localizedLanguageName(target))")
                                .foregroundColor(.glassMint)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    
                    Toggle(lm.t("flip_columns"), isOn: Binding(
                        get: { self.config?.swapColumns ?? false },
                        set: { self.config?.swapColumns = $0 }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: .glassTeal))
                    .foregroundColor(.white)
                }
                .padding()
            }
            
            HStack(spacing: 20) {
                Button(lm.t("cancel")) {
                    config = nil
                }
                .buttonStyle(GlassButtonStyle())
                
                Button(lm.t("import")) {
                    if let swap = config?.swapColumns {
                        onConfirm(swap)
                    }
                }
                .buttonStyle(GlassButtonStyle())
            }
        }
        .padding(30)
        .frame(width: 500)
        .background(DesignSystem.Colors.background.ignoresSafeArea())
    }
    
    private var effectiveSourceLanguage: String? {
        guard let config = config else { return nil }
        return config.swapColumns ? config.lang2 : config.lang1
    }
    
    private var effectiveTargetLanguage: String? {
        guard let config = config else { return nil }
        return config.swapColumns ? config.lang1 : config.lang2
    }
    
    private func localizedLanguageName(_ code: String) -> String {
        Locale.current.localizedString(forLanguageCode: code)?.capitalized ?? code.uppercased()
    }
}

struct LanguageColumn: View {
    @Environment(LanguageManager.self) private var lm
    let title: String
    @Binding var lang: String?
    let sample: String
    
    private static let languageOptions: [(code: String, name: String)] = {
        Locale.LanguageCode.isoLanguageCodes
            .compactMap { code in
                let identifier = code.identifier
                guard let name = Locale.current.localizedString(forLanguageCode: identifier) else { return nil }
                return (identifier, name.capitalized)
            }
            .sorted { $0.name < $1.name }
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            if let l = lang {
                Text("\(lm.t("detected")): \(Locale.current.localizedString(forLanguageCode: l) ?? l)")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.glassMint)
            } else {
                Text(lm.t("not_detected"))
                    .font(.subheadline)
                    .foregroundColor(.glassSky)
            }
            
            Picker(lm.t("choose_language"), selection: Binding(
                get: { lang ?? "und" },
                set: { lang = $0 == "und" ? nil : $0 }
            )) {
                Text(lm.t("choose_language")).tag("und")
                ForEach(Self.languageOptions, id: \.code) { option in
                    Text(option.name).tag(option.code)
                }
            }
            .pickerStyle(.menu)
            .tint(.glassTeal)
            
            Text("\"\(sample)\"")
                .font(.footnote.italic())
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
