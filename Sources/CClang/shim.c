#include "shim.h"

uint32_t CClang_cursorKind(CXCursor cursor) {
    return (uint32_t)clang_getCursorKind(cursor);
}

CXString CClang_cursorKindSpelling(uint32_t kind) {
    return clang_getCursorKindSpelling((enum CXCursorKind)kind);
}

int CClang_cursorIsAttribute(CXCursor cursor) {
    return clang_isAttribute(clang_getCursorKind(cursor));
}

uint32_t CClang_typeKind(CXType type) {
    return (uint32_t)type.kind;
}

uint32_t CClang_typeNullability(CXType type) {
    return (uint32_t)clang_Type_getNullability(type);
}

uint32_t CClang_tokenKind(CXToken token) {
    return (uint32_t)clang_getTokenKind(token);
}

uint32_t CClang_diagnosticSeverity(CXDiagnostic diagnostic) {
    return (uint32_t)clang_getDiagnosticSeverity(diagnostic);
}

uint32_t CClang_cursorAvailability(CXCursor cursor) {
    return (uint32_t)clang_getCursorAvailability(cursor);
}

uint32_t CClang_cxxAccessSpecifier(CXCursor cursor) {
    return (uint32_t)clang_getCXXAccessSpecifier(cursor);
}

uint32_t CClang_cursorLinkage(CXCursor cursor) {
    return (uint32_t)clang_getCursorLinkage(cursor);
}

uint32_t CClang_cursorVisibility(CXCursor cursor) {
    return (uint32_t)clang_getCursorVisibility(cursor);
}

uint32_t CClang_cursorStorageClass(CXCursor cursor) {
    return (uint32_t)clang_Cursor_getStorageClass(cursor);
}

uint32_t CClang_cursorTLSKind(CXCursor cursor) {
    return (uint32_t)clang_getCursorTLSKind(cursor);
}

uint32_t CClang_typeCallingConvention(CXType type) {
    return (uint32_t)clang_getFunctionTypeCallingConv(type);
}

uint32_t CClang_overriddenCursorCount(CXCursor cursor) {
    CXCursor *overridden = NULL;
    unsigned count = 0;
    clang_getOverriddenCursors(cursor, &overridden, &count);
    if (overridden) clang_disposeOverriddenCursors(overridden);
    return count;
}

CXCursor CClang_overriddenCursorAt(CXCursor cursor, uint32_t index) {
    CXCursor *overridden = NULL;
    unsigned count = 0;
    clang_getOverriddenCursors(cursor, &overridden, &count);
    CXCursor result = index < count ? overridden[index] : clang_getNullCursor();
    if (overridden) clang_disposeOverriddenCursors(overridden);
    return result;
}

int32_t CClang_parseTranslationUnit2(
    CXIndex CIdx,
    const char *source_filename,
    const char *const *command_line_args,
    int num_command_line_args,
    struct CXUnsavedFile *unsaved_files,
    unsigned num_unsaved_files,
    unsigned options,
    CXTranslationUnit *out_TU
) {
    return (int32_t)clang_parseTranslationUnit2(
        CIdx,
        source_filename,
        command_line_args,
        num_command_line_args,
        unsaved_files,
        num_unsaved_files,
        options,
        out_TU
    );
}
