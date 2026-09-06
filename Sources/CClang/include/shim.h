#pragma once
#include <stdint.h>
#include <clang-c/Index.h>

#ifdef __cplusplus
extern "C" {
#endif

uint32_t CClang_cursorKind(CXCursor cursor);
CXString CClang_cursorKindSpelling(uint32_t kind);
int CClang_cursorIsAttribute(CXCursor cursor);
uint32_t CClang_typeKind(CXType type);
uint32_t CClang_typeNullability(CXType type);
uint32_t CClang_tokenKind(CXToken token);
uint32_t CClang_diagnosticSeverity(CXDiagnostic diagnostic);
uint32_t CClang_cursorAvailability(CXCursor cursor);
uint32_t CClang_cxxAccessSpecifier(CXCursor cursor);

uint32_t CClang_cursorLinkage(CXCursor cursor);
uint32_t CClang_cursorVisibility(CXCursor cursor);
uint32_t CClang_cursorStorageClass(CXCursor cursor);
uint32_t CClang_cursorTLSKind(CXCursor cursor);
uint32_t CClang_typeCallingConvention(CXType type);
uint32_t CClang_overriddenCursorCount(CXCursor cursor);
CXCursor CClang_overriddenCursorAt(CXCursor cursor, uint32_t index);
int32_t CClang_parseTranslationUnit2(
    CXIndex CIdx,
    const char *source_filename,
    const char *const *command_line_args,
    int num_command_line_args,
    struct CXUnsavedFile *unsaved_files,
    unsigned num_unsaved_files,
    unsigned options,
    CXTranslationUnit *out_TU
);

#ifdef __cplusplus
}
#endif
