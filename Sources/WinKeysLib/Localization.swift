import Foundation

func L(_ key: String) -> String {
    NSLocalizedString(key, bundle: Bundle.module, comment: "")
}

func L(_ key: String, _ args: CVarArg...) -> String {
    String(format: NSLocalizedString(key, bundle: Bundle.module, comment: ""), arguments: args)
}
