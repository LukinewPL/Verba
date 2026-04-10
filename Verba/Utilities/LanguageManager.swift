import SwiftUI
import Observation

struct LanguageInfo: Codable, Identifiable {
    var id: String { language_code }
    let language_name: String
    let language_code: String
    let translations: [String: String]
}

/// To add a new language, create a new JSON file in Resources/Languages/
/// following the same structure as en.json and add it to the Xcode project's
/// Copy Bundle Resources phase.
@Observable @MainActor class LanguageManager {
    static let shared = LanguageManager()
    
    var availableLanguages: [LanguageInfo] = []
    var currentLanguage: LanguageInfo?
    
    var selectedCode: String {
        get { UserDefaults.standard.string(forKey: "selectedLanguageCode") ?? "en" }
        set { 
            UserDefaults.standard.set(newValue, forKey: "selectedLanguageCode")
            loadSelectedLanguage()
        }
    }
    
    init() {
        loadAvailableLanguages()
        loadSelectedLanguage()
    }
    
    func t(_ key: String) -> String {
        return currentLanguage?.translations[key] ?? key
    }
    
    private func loadAvailableLanguages() {
        guard let url = Bundle.main.url(forResource: "Languages", withExtension: nil) else {
            // If the folder is not found directly, try to find JSONs in the bundle
            discoverLanguagesInBundle()
            return
        }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            for file in files where file.pathExtension == "json" {
                if let data = try? Data(contentsOf: file),
                   let info = try? JSONDecoder().decode(LanguageInfo.self, from: data) {
                    availableLanguages.append(info)
                }
            }
        } catch {
            print("Error loading languages: \(error)")
        }
    }
    
    private func discoverLanguagesInBundle() {
        // Find all JSON files in the main bundle root
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) else { return }
        
        for url in urls {
            if let data = try? Data(contentsOf: url),
               let info = try? JSONDecoder().decode(LanguageInfo.self, from: data) {
                // To avoid duplicates if both folder and root are searched
                if !availableLanguages.contains(where: { $0.language_code == info.language_code }) {
                    availableLanguages.append(info)
                }
            }
        }
    }
    
    private func loadSelectedLanguage() {
        if let found = availableLanguages.first(where: { $0.language_code == selectedCode }) {
            currentLanguage = found
        } else {
            currentLanguage = availableLanguages.first(where: { $0.language_code == "en" })
        }
    }
}
