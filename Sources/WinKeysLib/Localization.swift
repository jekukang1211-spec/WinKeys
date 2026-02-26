import Foundation

struct AppLanguage {
    let code: String
    let nativeName: String
}

let availableLanguages: [AppLanguage] = [
    AppLanguage(code: "en", nativeName: "English"),
    AppLanguage(code: "ko", nativeName: "한국어"),
    AppLanguage(code: "ja", nativeName: "日本語"),
    AppLanguage(code: "zh-Hans", nativeName: "简体中文"),
    AppLanguage(code: "zh-Hant", nativeName: "繁體中文"),
    AppLanguage(code: "es", nativeName: "Español"),
    AppLanguage(code: "pt-BR", nativeName: "Português"),
    AppLanguage(code: "fr", nativeName: "Français"),
    AppLanguage(code: "de", nativeName: "Deutsch"),
    AppLanguage(code: "ru", nativeName: "Русский"),
    AppLanguage(code: "hi", nativeName: "हिन्दी"),
    AppLanguage(code: "ar", nativeName: "العربية"),
    AppLanguage(code: "vi", nativeName: "Tiếng Việt"),
    AppLanguage(code: "th", nativeName: "ไทย"),
    AppLanguage(code: "id", nativeName: "Bahasa Indonesia"),
    AppLanguage(code: "tr", nativeName: "Türkçe"),
]

private var languageBundle: Bundle = {
    loadLanguageBundle(for: Preferences.shared.appLanguage)
}()

private func loadLanguageBundle(for code: String) -> Bundle {
    if let path = Bundle.module.path(forResource: code, ofType: "lproj"),
       let bundle = Bundle(path: path) {
        return bundle
    }
    // Fallback to English
    if let path = Bundle.module.path(forResource: "en", ofType: "lproj"),
       let bundle = Bundle(path: path) {
        return bundle
    }
    return Bundle.module
}

func updateLanguageBundle() {
    languageBundle = loadLanguageBundle(for: Preferences.shared.appLanguage)
}

func L(_ key: String) -> String {
    NSLocalizedString(key, bundle: languageBundle, comment: "")
}

func L(_ key: String, _ args: CVarArg...) -> String {
    String(format: NSLocalizedString(key, bundle: languageBundle, comment: ""), arguments: args)
}
