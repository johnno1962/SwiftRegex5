//
//  SwiftRegex5Tests.swift
//  SwiftRegex5Tests
//
//  Created by John Holdsworth on 13/01/2018.
//  Copyright © 2018 John Holdsworth. All rights reserved.
//

import XCTest
import SwiftRegex5

class SwiftRegex5Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        var str = "Hello, playground"

        // TupleRegex.swift defines seven new member functions on String to make working
        // with regular expressions easier.

        if str.containsMatch(of: "play\\w+") {
            XCTAssert(true, "basic match")
        }

        if let firstWord: String = str.firstMatch(of: "(\\w)(\\w*)") {
            XCTAssertEqual(firstWord, "Hello", "extract match")
        }

        // functions are generic by return value and can single value or tuples or
        // arrays of any of: String, Substring?, Range<String.Index>? or NSRange

        if let (initial, remainnder): (String, String) = str.firstMatch(of: "(\\w)(\\w*)") {
            XCTAssert((initial, remainnder) == ("H", "ello"), "extract match")
        }

        // While tuples start at group 1, arrays contain "group 0", the full match

        if let match: [Substring?] = str.firstMatch(of: "(\\w)(\\w*)") {
            XCTAssertEqual(match, ["Hello", "H", "ello"], "array match")
        }

        // when not optional it is also possible to extract all matches from a string

        let allWords: [(String, String)] = str.allMatches(of: "(\\w)(\\w*)")
        XCTAssert(allWords[0] == ("H", "ello") && allWords[1] == ("p", "layground"))

        // there are functions available to replace the contents of the match

        let replaced1 = str.replacing(regex: "Hello", with: "Ola")
        XCTAssertEqual(replaced1, "Ola, playground", "simple replace")

        // simple tuple values are a gloal replace

        let replaced2 = str.replacing(regex: "\\w+", with: "Ola")
        XCTAssertEqual(replaced2, "Ola, Ola", "global replace")

        // to replace only the first or "N" matches use array assignment

        let replaced3 = str.replacing(regex: "(\\w)(\\w*)", with: [("S", "alute")])
        XCTAssertEqual(replaced3, "Salute, playground", "constrained replace")

        // where pocessing is required a closure replace can be used.

        let replaced4 = str.replacing(regex: "(\\w)(\\w*)") {
            (groups: (initial: String, remainder: String), stop) in
            return groups.initial+groups.remainder.uppercased()
        }
        XCTAssertEqual(replaced4, "HELLO, pLAYGROUND", "constrained replace")

        // At this point it's possible to define a generic subscript of a String by a
        // String with getters and setters to provide a shorthand for these functions.

        if str["play\\w+"] {
            XCTAssert(true, "basic match")
        }

        if let firstWord: String = str["(\\w)(\\w*)"] {
            XCTAssertEqual(firstWord, "Hello", "extract match")
        }

        if let (initial, remainnder): (String, String) = str["(\\w)(\\w*)"] {
            XCTAssert((initial, remainnder) == ("H", "ello"), "extract match")
        }

        let allWords2: [(String, String)] = str["(\\w)(\\w*)"]
        XCTAssert(allWords2[0] == ("H", "ello") && allWords2[1] == ("p", "layground"))

        // perhaps this makes more sense when you realise subscripts can be assigned to

        str["Hello"] = "Ola"
        XCTAssertEqual(str, "Ola, playground", "simple replace")

        str["\\w+"] = "Ola"
        XCTAssertEqual(str, "Ola, Ola", "global replace")

        str["(\\w)(\\w*)"] = [("S", "alute")]
        XCTAssertEqual(str, "Salute, Ola", "constrained replace")

        // this yields a single unified syntax for a variety of regex operations.

        str = "Hello, playground"

        // the first sections develop the idea from regex object to subscripts on string regexs

        let word = RegexImpl<(first: String, rest: String)>(pattern: "(\\w)(\\w*)")

        if let detail = word.match(target: str) {
            XCTAssertEqual(detail.first, "H")
            XCTAssertEqual(detail.rest, "ello")
        }

        let matches = word.matches(target: str)
        print(matches)

        for (first, rest) in word.matches(target: str) {
            print(first, rest)
        }

        for (first, rest) in word.iterator(target: str) {
            print(first, rest)
        }

        str = word.replacing(target: str, templates: [("O", "la")])
        XCTAssertEqual(str, "Ola, playground")

        // declare subscripts in extension on String to create a shorthand.
        // tuple is global replace, array applies only the given matches

        str["(\\w)(\\w*)"] = [("B", "onjour")]
        XCTAssertEqual(str, "Bonjour, playground")

        if let detail: (first: String, rest: String) = str["(\\w)(\\w*)"] {
            XCTAssertEqual(detail.first, "B")
            XCTAssertEqual(detail.rest, "onjour")
        }

        if let (first, rest): (String, String) = str["(\\w)(\\w*)".caseInsensitive] {
            XCTAssertEqual(first, "B")
            XCTAssertEqual(rest, "onjour")
        }

        let matches3: [(String, String)] = str["(\\w)(\\w*)"]
        print(matches3)

        for (first, rest): (String, String) in str["(\\w)(\\w*)"] {
            print(first, rest)
        }

        for (first, rest): (String, String) in str["(\\w)(\\w*)".regexLazy] {
            print(first, rest)
        }

        str["(\\w)(\\w*)"] = [("S", "alut")]
        XCTAssertEqual(str, "Salut, playground")

        // fetch to tuple and assign from tuple operate on first match,

        var numbers = "phone: 555 666-1234 fax: 555 666-4321"

        if let match: (String, String, String) = numbers["(\\d+) (\\d+)-(\\d+)"] {
            XCTAssert(match == ("555", "666","1234"), "single match")
        }
        numbers["(\\d+) (\\d+)-(\\d+)"] = [("555", "777", "1234")]
        XCTAssertEqual(numbers, "phone: 555 777-1234 fax: 555 666-4321")

        // arrays of tuples operate on all matches

        let matches4: [(String, String, String)] = numbers["(\\d+) (\\d+)-(\\d+)"]
        print(matches4)

        numbers["(\\d+) (\\d+)-(\\d+)"] = [("555", "888", "1234"), ("555", "999", "4321")]
        XCTAssertEqual(numbers, "phone: 555 888-1234 fax: 555 999-4321")

        // individual groups of first match can be addressed and assigned to

        if let area = numbers["(\\d+) (\\d+)-(\\d+)", 1] {
            XCTAssertEqual(area, "555")
        }

        numbers["(\\d+) (\\d+)-(\\d+)", 1] = ["444"]
        XCTAssertEqual(numbers, "phone: 444 888-1234 fax: 555 999-4321")

        // a single element tuple always refers to the entire match (group 0)

        if let area: (String) = numbers["(\\d+) (\\d+)-(\\d+)"] {
            XCTAssertEqual(area, "444 888-1234")
        }

        numbers["(\\d+) (\\d+)-(\\d+)"] = ("444 000-1234")
        XCTAssertEqual(numbers["(\\d+) (\\d+)-(\\d+)"], "444 000-1234")

        // replacements are regex templates and can be specified inline

        XCTAssertEqual(str["(\\w)(\\w*)", "$1-$2"], "S-alut, p-layground")

        // assignment can be from a closure which is passed over all matches

        str["(\\w)(\\w*)"] = {
            (groups: (first: String, rest: String), stop) -> String in
            return groups.first+groups.rest.uppercased()
        }
        XCTAssertEqual(str, "SALUT, pLAYGROUND")

        // parsing a properties file using regex as iterator

        let props = """
            name1 = value1
            name2 = value2
            """

        var params = [String: String]()
        for (name, value): (String, String) in props["(\\w+)\\s*=\\s*(.*)".regexLazy] {
            params[name] = value
        }
        XCTAssertEqual(params, ["name1": "value1", "name2": "value2"])

        // arrays and tuples of String, Substring? and NSRange can be fetched from matches

        if let r: [NSRange] = props["(\\w+)\\s*=\\s*(.*)"] {
            print(r)
        }
        if let r: (Substring?, Substring?) = props["(\\w+)\\s*=\\s*(.*)"] {
            print(r)
        }
        for r: [String] in props["(\\w+)\\s*=\\s*(.*)"] {
            print(r)
        }
        for r: (NSRange, NSRange) in props["(\\w+)\\s*=\\s*(.*)".regexLazy] {
            print(r)
        }

        // exploring use in switch/case

        let match = RegexMatch()
        switch str {
        case match["(\\w)(\\w*)"]:
            let (first, rest): (String, String) = str[match]
            print("\(first)~\(rest)")
        default:
            break
        }

        // previous tests

        var input = "The quick brown fox jumps over the lazy dog."

        XCTAssertEqual(input["quick .* fox"], "quick brown fox", "basic match")

        if input["quick orange fox"] {
            XCTAssert(false, "non-match fail")
        }
        else {
            XCTAssert(true, "non-match pass")
        }

        let rgs: [Range<String.Index>?] = input["the (\\w+)".caseInsensitive, 1]
        XCTAssertEqual(rgs.map { input[$0!] }, ["quick", "lazy"], "range matches")
        XCTAssertEqual(input["quick brown (\\w+)", 1], "fox", "group subscript")
        XCTAssertEqual(input["the (\\w+)".caseInsensitive, 1], ["quick", "lazy"], "group matches")
        XCTAssertEqual(input["(the lazy) (dog)?", 2], "dog", "optional group pass")
        XCTAssertEqual(input["(the lazy) (cat)?", 2], nil, "nil optional group pass")

        input["(the) (\\w+)"] = "$1 very $2"
        XCTAssertEqual(input, "The quick brown fox jumps over the very lazy dog.", "replace pass")

        input["(\\w)(\\w+)"] = {
            (groups: [Substring?], stop) in
            return groups[1]!.uppercased()+groups[2]!
        }

        XCTAssertEqual(input, "The Quick Brown Fox Jumps Over The Very Lazy Dog.", "block pass")

        input["Quick (\\w+)", 1] = "Red $1"

        XCTAssertEqual(input, "The Quick Red Brown Fox Jumps Over The Very Lazy Dog.", "group replace pass")

        var z = "👨‍👩‍👧‍👦👨‍👩‍👧‍👦 👨‍👩‍👧‍👦  👩‍👩‍👦👩‍👩‍👦👩‍👩‍👦 🇭🇺 🇭🇺🇭🇺"

        z["👨‍👩‍👧‍👦"] = "👩‍👩‍👦"
        XCTAssertEqual(z, "👩‍👩‍👦👩‍👩‍👦 👩‍👩‍👦  👩‍👩‍👦👩‍👩‍👦👩‍👩‍👦 🇭🇺 🇭🇺🇭🇺", "emoji pass")

        z["🇭🇺"] = {
            (groups: [Substring?], stop) in
            stop.pointee = true
            return "🇫🇷"
        }
        XCTAssertEqual(z, "👩‍👩‍👦👩‍👩‍👦 👩‍👩‍👦  👩‍👩‍👦👩‍👩‍👦👩‍👩‍👦 🇫🇷 🇭🇺🇭🇺", "emoji pass")

        z["👩‍👩‍👦"] = ["$0", nil, "$0", "👪", "👩‍👧‍👧"]

        XCTAssertEqual(z, "👩‍👩‍👦👩‍👩‍👦 👩‍👩‍👦  👪👩‍👧‍👧👩‍👩‍👦 🇫🇷 🇭🇺🇭🇺", "emoji pass")

        XCTAssertEqual("abcd".firstMatch(of: ".", pos: 2), "c")
        XCTAssertEqual("abcd".allMatches(of: ".", pos: 2), ["c", "d"])
        XCTAssertEqual("abcd".replacing(regex: ".", pos: 2, with: "e"), "abee")
        XCTAssertEqual("abcd".replacing(regex: ".", pos: 2, with: ["e", "f"]), "abef")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            var str = """
                👩‍👩‍👦 Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
                """

            str = str + str
            str = str + str
            str = str + str
            str = str + str
            str = str + str
            str = str + str
            str = str + str
            str = str + str

            var i = 0
            for _: String in str["\\w+"] {
                i += 1
            }
            print(i)

            str["\\w+"] = {
                (groups: [Substring?], stop) in
                return groups[0]!.uppercased()
            }

            str["\\w+"] = ">$0$0<"
//            print(str)
        }
    }
    
}
