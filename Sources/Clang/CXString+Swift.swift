import CClang

extension CXString {
    package consuming func takeString() -> String {
        defer { clang_disposeString(self) }
        guard let pointer = clang_getCString(self) else { return "" }
        return String(cString: pointer)
    }
}
