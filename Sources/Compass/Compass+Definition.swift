import Foundation
import Hitch
import Spanker

/// A definition is a reusable portion of JSON

public struct Definition {
    public let name: Hitch
    public let element: JsonElement
    public var queryPart: QueryPart
    
    init?(element: JsonElement,
          compass: Compass) {
        guard let name: Hitch = element["definition"] else {
            //Compass.print("Malformed definition is missing \"definition\" key: \(element)")
            return nil
        }
        self.name = name
        guard let element: JsonElement = element["value"] else {
            Compass.print("Malformed definition is missing \"value\" key: \(element)")
            return nil
        }
        
        guard let queryPart = QueryPart(element: element,
                                        compass: compass) else {
            return nil
        }
        
        self.element = element
        self.queryPart = queryPart
    }
}
