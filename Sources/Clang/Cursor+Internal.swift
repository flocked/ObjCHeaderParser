import CClang

extension Cursor {
    package func wrapping(type rawValue: CXType) -> ClangType {
        ClangType(rawValue: rawValue, owner: translationUnitOwner)
    }

    package var translationUnitOwner: TranslationUnit {
        ownerForPackage
    }
}
