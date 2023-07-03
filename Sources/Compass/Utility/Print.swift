import Foundation
import Hitch

extension Compass {
    @usableFromInline
    static func print(_ items: Any..., separator: String = " ", terminator: String = "\n", truncate: Int) {
#if DEBUG
        let output = items.map { "\($0)" }.joined(separator: separator)
        Swift.print(output)
#endif
    }
    
    @usableFromInline
    static func print(tag: String, _ items: Any..., separator: String = " ", terminator: String = "\n", truncate: Int) {
#if DEBUG
        let output = items.map { "\($0)" }.joined(separator: separator)
        Swift.print("\(tag): \(output)")
#endif
    }
    
    @usableFromInline
    static func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        print(items, separator: separator, terminator: terminator, truncate: 4096)
    }
    
    @usableFromInline
    static func print(tag: String, _ items: Any..., separator: String = " ", terminator: String = "\n") {
        print(tag: tag, items, separator: separator, terminator: terminator, truncate: 4096)
    }
}
