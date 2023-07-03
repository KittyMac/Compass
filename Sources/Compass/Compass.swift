import Foundation
import Hitch
import Spanker

// Compass is like regex for json structures. You create a a Compass supplying it
// a "json regex", which Compass compiles into a more optimized format. You can then
// run this compass against different json and it will return the matches found.

public final class Compass {
    
    public var queries: [Query] = []
    
    public init?(queries root: JsonElement) {
        // Note: the memory used by element will be deallocated after this call, so it it
        // important to not rely on the contents of element for persistance
        //
        // Note: element is expected to be an array of queries
        //
        
        guard root.type == .array else { return nil }
        
        for queryElement in root.iterValues {
            guard let query = compile(query: queryElement) else {
                continue
            }
            queries.append(query)
        }
    }
    
    public convenience init?(json: HalfHitch) {
        guard let root = Spanker.parse(halfhitch: json) else { return nil }
        self.init(queries: root)
    }
    
    public convenience init?(json: Hitch) {
        self.init(json: json.halfhitch())
    }
    
    public convenience init?(json: String) {
        self.init(json: Hitch(string: json).halfhitch())
    }
    
    
    public func matches(against: JsonElement) -> JsonElement? {
        return matches(against: against, queries: queries)
    }
    
    public func matches(against: HalfHitch) -> JsonElement? {
        guard let element = Spanker.parse(halfhitch: against) else { return nil }
        return matches(against: element)
    }
    
    public func matches(against: Hitch) -> JsonElement? {
        return matches(against: against.halfhitch())
    }
    
    public func matches(against: String) -> JsonElement? {
        return matches(against: Hitch(string: against).halfhitch())
    }
    
    
}
