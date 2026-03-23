import SwiftUI
import SwiftData
import Observation



struct SettingsView: View {
    @Environment(LanguageManager.self) private var lm
    @Environment(\.modelContext) private var ctx
    @AppStorage("animationSpeed") var animationSpeed: Double = 1.0
    @State private var showResetAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(lm.t("settings")).font(.largeTitle.bold()).foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(lm.t("app_language")).font(.headline).foregroundColor(.glassCyan)
                    VStack {
                        ForEach(lm.availableLanguages) { lang in
                            Button(action: { lm.selectedCode = lang.language_code }) {
                                HStack {
                                    Text(lang.language_name).foregroundColor(.white)
                                    Spacer()
                                    if lm.selectedCode == lang.language_code {
                                        Image(systemName: "checkmark").foregroundColor(.glassCyan)
                                    }
                                }.padding(.vertical, 5)
                            }.buttonStyle(.plain)
                            if lang.id != lm.availableLanguages.last?.id { Divider().background(Color.white.opacity(0.1)) }
                        }
                    }.padding().glassEffect()
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(lm.t("animation_speed")).font(.headline).foregroundColor(.glassCyan)
                    HStack {
                        Text(animationSpeed == 0 ? lm.t("off") : String(format: "%.1fx", animationSpeed))
                            .foregroundColor(.white)
                            .frame(width: 60)
                        Slider(value: $animationSpeed, in: 0.0...2.0, step: 0.5).tint(.glassCyan)
                    }
                }.glassEffect()
                
                Spacer().frame(height: 50)
                
                Button(role: .destructive, action: { showResetAlert = true }) {
                    Text(lm.t("reset_all_data")).foregroundColor(.red).font(.headline).frame(maxWidth: .infinity)
                }.buttonStyle(GlassButtonStyle())
            }.padding()
        }
        .alert(lm.t("reset_all_data_q"), isPresented: $showResetAlert) {
            Button(lm.t("cancel"), role: .cancel) {}
            Button(lm.t("reset"), role: .destructive) { resetAll() }
        } message: { Text(lm.t("undone_msg")) }
    }
    
    private func resetAll() {
        do {
            try ctx.delete(model: WordSet.self)
            try ctx.delete(model: StudySession.self)
            try ctx.delete(model: Word.self)
            try ctx.save()
        } catch {
            print("WordWise: Save failed — \(error)")
        }
    }
}
