import Foundation
import Hitch

extension Compass {
    @usableFromInline
    static func print(indent: Int, _ items: Any..., separator: String = " ", terminator: String = "\n", truncate: Int) {
#if DEBUG
        let output = items.map { "\($0)" }.joined(separator: separator)
        let indentString = String(repeating: " ", count: indent * 2)
        Swift.print(indentString + output)
#endif
    }
    
    @usableFromInline
    static func print(indent: Int, tag: String, _ items: Any..., separator: String = " ", terminator: String = "\n", truncate: Int) {
#if DEBUG
        let output = items.map { "\($0)" }.joined(separator: separator)
        let indentString = String(repeating: " ", count: indent * 2)
        Swift.print("\(indentString)\(tag): \(output)")
#endif
    }
        
    @usableFromInline
    static func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        print(indent: 0, items, separator: separator, terminator: terminator, truncate: 4096)
    }
    
    @usableFromInline
    static func print(indent: Int, tag: String, _ items: Any..., separator: String = " ", terminator: String = "\n") {
        print(indent: indent, tag: tag, items, separator: separator, terminator: terminator, truncate: 4096)
    }
}
