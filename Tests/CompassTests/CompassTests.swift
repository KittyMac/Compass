import XCTest

import Compass
import Spanker

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
    
    func testSimpleMatch0() {
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
                "// should capture line2",
                "line1",
                ["KEY", "()", "."],
                "line3",
            ]
        ]
        """
        
        let expectedMatches = JsonElement(unknown: [
            "KEY": JsonElement(unknown: ["line2"])
        ])
        
        guard let compass = Compass(json: compassJson) else { XCTFail(); return }
        
        guard let matches = compass.matches(against: sourceJson) else { XCTFail(); return }
        
        XCTAssertEqual(matches.description, expectedMatches.description)
    }
    
    func testSimpleMatch1() {
        // NOTE: will match ELEPHANT until we implement validation IsCat
        let sourceJson = """
        [
            "DOG",
            "CAT1",
            "DOG",
            "ELEPHANT",
            "DOG",
            "CAT2",
            "DOG"
            "KITTEN0",
            "DOG"
        ]
        """
        
        let compassJson = """
        [
            {
                "validation": "isCat",
                "allow": [
                    "/CAT\\d+/",
                    "/KITTEN\\d+/"
                ],
                "disallow": []
            },
            [
                "// should capture both cats",
                "DOG",
                ["KEY", "()", "isCat"],
                "DOG"
            ]
        ]
        """
        
        let expectedMatches = JsonElement(unknown: [
            "KEY": JsonElement(unknown: ["CAT1", "CAT2", "KITTEN0"])
        ])
        
        guard let compass = Compass(json: compassJson) else { XCTFail(); return }
        
        guard let matches = compass.matches(against: sourceJson) else { XCTFail(); return }
        
        XCTAssertEqual(matches.description, expectedMatches.description)
    }
}
