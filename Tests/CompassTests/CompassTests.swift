import XCTest

import Compass

final class HitchTests: XCTestCase {
    
    func testCompile() {
        let compassJson = """
        [
            [
                "// simple match",
                "line1",
                "!--",
                "*--",
                "REPEAT",
                "REPEAT_UNTIL_STRUCTURE",
                "*",
                "?",
                "!*",
                ".",
                "DEBUG",
                "/line(.*)/",
                ["KEY", "()", "IsString"]
            ]
        ]
        """
        guard let compass = Compass(json: compassJson) else { XCTFail(); return }
        XCTAssertEqual(compass.description, #"[["// simple match","line1","!--","*--","REPEAT","REPEAT_UNTIL_STRUCTURE","*","?","!*",".","DEBUG","/line(.*)/",["KEY","()","IsString"]]]"#)
    }
    
    func testSimpleMatch() {
        let sourceJson = """
        [
            "line0",
            "line1",
            "line2",
            "line3",
            "line4",
        ]
        """
        
        let compassJson = """
        [
            [
                "// simple match",
                "line1",
                ["KEY", "()", "IsString"],
                "line2",
            ]
        ]
        """
        
        guard let compass = Compass(json: compassJson) else { XCTFail(); return }
        
        let results = compass.matches(against: sourceJson)
        
        print(results)
    }
}
