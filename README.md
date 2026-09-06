# ObjCHeaderParser

A Swift 6 / SwiftPM framework for parsing Objective-C public headers with libclang into strongly typed, Codable Swift values.

The package has three layers:

- `CClang`: a small compiled C compatibility shim over libclang's public `clang-c/Index.h` API.
- `Clang`: Swift wrappers for translation units, cursors, types, tokens, diagnostics and source locations.
- `ObjCParser`: a high-level Objective-C/C header model that does not expose libclang C enums in serialized data.

## Requirements

- macOS 12 or later
- Swift 6
- Homebrew LLVM (`brew install llvm`)

`Package.swift` resolves LLVM using `LLVM_PREFIX` first, then `brew --prefix llvm`, then the standard Apple Silicon/Intel Homebrew locations. Both the libclang headers and `libclang.dylib` are taken from the same LLVM installation.

## Parsed model

`ObjCHeader` exposes classes, protocols, categories, enums, structs, unions, typedefs, C functions, variables, macros, `#include`/`#import` directives, module imports and forward declarations.

Declarations preserve exact source text when it can be read from the source range, a normalized token rendering, spelling and expansion locations, source extent, USR, canonical/referenced/definition relationships, semantic and lexical parents, linkage, visibility, availability, attributes and documentation.

`ObjCType` preserves the normalized kind plus the original libclang type-kind raw value, spelling/canonical spelling, nullability, Objective-C ownership qualifiers, `__kindof`, C qualifiers, pointee/element/result/parameter types, lightweight generic arguments, protocol constraints, array size, size/alignment, declaration identity, variadic state and function calling convention.

Additional Objective-C/C semantics include:

- property attributes, custom getter/setter names, class properties and protocol optionality
- method family inference and overridden-method references
- Objective-C generic parameter names, bounds and covariance/contravariance when present in source
- enum case evaluated values plus written expressions
- `NS_ENUM`, `NS_OPTIONS`, `NS_ERROR_ENUM`, `CF_ENUM` and `CF_OPTIONS` recognition
- typed/extensible enum typedef recognition (`NS_TYPED_ENUM`, `NS_TYPED_EXTENSIBLE_ENUM`, `NS_EXTENSIBLE_STRING_ENUM`)
- anonymous record state and typedef-to-underlying-declaration relationships
- function/variable storage class, TLS state, linkage and visibility
- variable initializer source text
- macro parameters, replacement tokens and variadic state
- structured attribute kinds while preserving unknown future raw values

## Basic use

```swift
import ObjCParser

let parser = ObjCParser(
    configuration: .init(
        sdk: URL(fileURLWithPath: "/path/to/MacOSX.sdk"),
        target: "arm64-apple-macosx27.0",
        includeMacros: true
    )
)

let result = try parser.parseResult(URL(fileURLWithPath: "/path/to/MyHeader.h"))
let header = result.header

for cls in header.classes {
    print(cls.name)
    print(cls.genericParameters)

    for property in cls.properties {
        print(property.name, property.type.spelling, property.attributes)
    }

    for method in cls.methods {
        print(method.selector, method.family, method.overriddenMethods)
    }
}
```

By default, declarations are limited to the requested main header. Use `.allIncludedHeaders` to retain declarations from imported headers as well.

`includeImports` defaults to `true`, which enables libclang's detailed preprocessing record so inclusion directives can be returned. `includeMacros` remains opt-in because SDK macro inventories can be very large.

## Remaining limitations

libclang intentionally exposes less information than Clang's C++ AST. Some syntax therefore still requires source/token interpretation. The parser does not attempt to parse Objective-C implementation bodies or general C/Objective-C expressions as a compiler AST.

Not yet modeled as dedicated high-level values are the full parsed-comment AST (`@param`, `@return`, code blocks, HTML commands), inactive conditional-compilation branches, arbitrary pragmas, every Clang-specific attribute payload, and every newly-added `CXTypeKind`. Unknown type/attribute/calling-convention values are nevertheless preserved through raw values where the model exposes them, so newer libclang data is not silently discarded.

## Exact source text

Parsed declarations preserve their original source text using Clang source-range byte offsets rather than rebuilding declarations from tokens. This keeps multiline formatting, indentation, whitespace, and inline comments intact.

Every declaration/member that has `ObjCDeclarationInfo` exposes `sourceText`, `normalizedSourceText`, and, for declarations with bodies such as Objective-C classes/protocols/categories, `headerText`:

```swift
let header = try ObjCParser().parse(url)
let method = header.classes[0].methods[0]

print(method.sourceText)            // Exact text as written in the header.
print(method.normalizedSourceText)  // Token-normalized representation.
print(header.classes[0].headerText) // e.g. @interface MyClass : NSObject <NSCopying>
```

`ObjCParameter` also carries optional declaration info and therefore exposes `sourceText` when Clang provides a parameter cursor range. `ObjCHeader.sourceText` contains the complete UTF-8 source of the requested header.

The compatibility properties `ObjCDeclarationInfo.declaration` and `normalizedDeclaration` remain available as aliases for `sourceText` and `normalizedSourceText`.
