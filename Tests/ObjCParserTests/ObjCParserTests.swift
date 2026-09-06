import Foundation
import Testing
@testable import ObjCParser

@Test func modelRoundTrip() throws {
    let location = ObjCSourceLocation(file: URL(fileURLWithPath: "/tmp/Test.h"), line: 1, column: 1, offset: 0)
    let range = ObjCSourceRange(start: location, end: location)
    let source = """
    @interface Thing
    @end
    """
    let info = ObjCDeclarationInfo(
        name: "Thing",
        usr: "c:objc(cs)Thing",
        sourceText: source,
        normalizedSourceText: "@interface Thing @end",
        headerText: "@interface Thing",
        location: location,
        extent: range,
        availability: .available
    )
    let value = ObjCClass(info: info, name: "Thing", superclass: nil, protocols: [], properties: [], methods: [], ivars: [])
    let header = ObjCHeader(url: URL(fileURLWithPath: "/tmp/Test.h"), sourceText: source, declarations: [.class(value)])
    let data = try JSONEncoder().encode(header)
    let decoded = try JSONDecoder().decode(ObjCHeader.self, from: data)
    #expect(decoded == header)
    #expect(decoded.classes[0].sourceText == source)
    #expect(decoded.classes[0].headerText == "@interface Thing")
}

@Test func propertyAttributesAreIndependent() {
    let attributes: ObjCPropertyAttributes = [.nonatomic, .copy, .readonly]
    #expect(attributes.contains(.nonatomic))
    #expect(attributes.contains(.copy))
    #expect(attributes.contains(.readonly))
    #expect(!attributes.contains(.strong))
}

@Test func exactMultilineSourceText() throws {
    let source = """
    @interface Example
    @property (nonatomic, assign)
        int value;

    - (void)performValue:(int)value
                  second:(double)second;
    @end
    """

    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let url = directory.appendingPathComponent("Example.h")
    try source.write(to: url, atomically: true, encoding: .utf8)

    let header = try ObjCParser().parse(url)
    let cls = try #require(header.classes.first)
    let property = try #require(cls.properties.first)
    let method = try #require(cls.methods.first)

    #expect(header.sourceText == source)
    #expect(property.sourceText == """
    @property (nonatomic, assign)
        int value;
    """)
    #expect(method.sourceText == """
    - (void)performValue:(int)value
                  second:(double)second;
    """)
    #expect(method.sourceText.contains("\n"))
    #expect(cls.sourceText.contains("@end"))
    #expect(cls.headerText == "@interface Example")
}
