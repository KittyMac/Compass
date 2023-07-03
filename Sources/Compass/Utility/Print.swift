import Foundation
import Hitch


func print(_ items: Any..., separator: String = " ", terminator: String = "\n", truncate: Int) {
    #if DEBUG
    let output = items.map { "\($0)" }.joined(separator: separator)
    Swift.print(output)
    #endif
}

func print(tag: String, _ items: Any..., separator: String = " ", terminator: String = "\n", truncate: Int) {
    let output = items.map { "\($0)" }.joined(separator: separator)
    Swift.print(output)
}

func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print(items, separator: separator, terminator: terminator, truncate: 4096)
}

func print(tag: String, _ items: Any..., separator: String = " ", terminator: String = "\n") {
    print(tag: tag, items, separator: separator, terminator: terminator, truncate: 4096)
}
