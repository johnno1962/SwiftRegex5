//
//  TupleRegex.swift
//  SwiftRegex5
//
//  Created by John Holdsworth on 13/01/2018.
//  Copyright © 2018 John Holdsworth. All rights reserved.
//
//  Repo: https://github.com/johnno1962/SwiftRegex5
//
//  $Id: //depot/SwiftRegex4/SwiftRegex5.playground/Sources/TupleRegex.swift#49 $
//

import Foundation

public protocol RegexLiteral {
    var regexPattern: String { get }
    var regexOptions: NSRegularExpression.Options { get }
}

struct RegexOptioned: RegexLiteral {
    public let regexPattern: String
    public let regexOptions: NSRegularExpression.Options
}

extension RegexLiteral {
    func regexOptions(add options: NSRegularExpression.Options) -> RegexLiteral {
        return RegexOptioned(regexPattern: regexPattern, regexOptions: regexOptions.union(options))
    }
    public var caseInsensitive: RegexLiteral {
        return regexOptions(add: [.caseInsensitive])
    }
    public var allowCommentsAndWhitespace: RegexLiteral {
        return regexOptions(add: [.allowCommentsAndWhitespace])
    }
    public var ignoreMetacharacters: RegexLiteral {
        return regexOptions(add: [.ignoreMetacharacters])
    }
    public var dotMatchesLineSeparators: RegexLiteral {
        return regexOptions(add: [.dotMatchesLineSeparators])
    }
    public var anchorsMatchLines: RegexLiteral {
        return regexOptions(add: [.anchorsMatchLines])
    }
    public var useUnixLineSeparators: RegexLiteral {
        return regexOptions(add: [.useUnixLineSeparators])
    }
    public var useUnicodeWordBoundaries: RegexLiteral {
        return regexOptions(add: [.useUnicodeWordBoundaries])
    }
    public var regexLazy: RegexLazy {
        return RegexLazy(literal: self)
    }
}

public struct RegexLazy {
    let literal: RegexLiteral
}

extension String: RegexLiteral {
    public static var regexDefaultOptions: NSRegularExpression.Options = []

    public var regexPattern: String {
        return self
    }
    public var regexOptions: NSRegularExpression.Options {
        return String.regexDefaultOptions
    }

    fileprivate func nsrange(pos: Int = 0) -> NSRange {
        return NSMakeRange(pos, utf16.count - pos)
    }
    fileprivate subscript(range: NSRange) -> Substring? {
        return Range(range, in: self).flatMap { self[$0] }
    }

    /// compiled regex aware literals
    public subscript<T>(regex: Regex<T>) -> T? {
        get {
            return regex.match(target: self)
        }
        set(newValue) {
            self = regex.replacing(target: self, template: newValue!)
        }
    }

    public subscript<T>(regex: Regex<T>) -> [T] {
        get {
            return regex.matches(target: self)
        }
        set(newValues) {
            self = regex.replacing(target: self, templates: newValues)
        }
    }

    public subscript<T>(regex: Regex<T>) -> (T, UnsafeMutablePointer<ObjCBool>) -> String {
        get {
            fatalError("Invalid get of closure")
        }
        set(closure) {
            self = regex.replacing(target: self, exec: closure)
        }
    }

    /// plain old string regex pattern matches
    public subscript(pattern: RegexLiteral) -> Bool {
        return Regex<String>(pattern: pattern).matchResult(target: self) != nil
    }

    /// single match and global replace
    public subscript<T>(pattern: RegexLiteral) -> T? {
        get {
            return Regex<T>(pattern: pattern).match(target: self)
        }
        set(newValue) {
            self = Regex<T>(pattern: pattern).replacing(target: self, template: newValue!)
        }
    }

    /// mutliple match and selective replace
    public subscript<T>(pattern: RegexLiteral) -> [T] {
        get {
            return Regex<T>(pattern: pattern).matches(target: self)
        }
        set(newValues) {
            self = Regex<T>(pattern: pattern).replacing(target: self, templates: newValues)
        }
    }

    /// closure replace
    public subscript<T>(pattern: RegexLiteral) -> (T, UnsafeMutablePointer<ObjCBool>) -> String {
        get {
            fatalError("Invalid get of closure")
        }
        set(closure) {
            self = Regex<T>(pattern: pattern).replacing(target: self, exec: closure)
        }
    }

    /// operating on individual group
    public subscript(pattern: RegexLiteral, group: Int) -> String? {
        get {
            return Regex<String>(pattern: pattern).match(target: self, group: group)
        }
        set(newValue) {
            self = Regex<String>(pattern: pattern)
                .replacing(target: self, template: newValue!, group: group)
        }
    }

    public subscript<T>(pattern: RegexLiteral, group: Int) -> [T] {
        get {
            return Regex<T>(pattern: pattern).matches(target: self, group: group)
        }
        set(newValue) {
            self = Regex<T>(pattern: pattern)
                .replacing(target: self, templates: newValue, group: group)
        }
    }

    public subscript<T>(pattern: RegexLiteral, group: Int) -> (T, UnsafeMutablePointer<ObjCBool>) -> String {
        get {
            fatalError("Invalid get of closure")
        }
        set(closure) {
            self = Regex<T>(pattern: pattern).replacing(target: self, group: group, exec: closure)
        }
    }

    /// lazy iterators
    public subscript<T>(pattern: RegexLazy) -> AnyIterator<T> {
        return Regex<T>(pattern: pattern.literal).iterator(target: self)
    }
    public subscript<T>(pattern: RegexLazy, group: Int) -> AnyIterator<T> {
        return Regex<T>(pattern: pattern.literal).iterator(target: self, group: group)
    }

    /// inplace replace
    public subscript(pattern: RegexLiteral, template: String) -> String {
        return Regex<String>(pattern: pattern).replacing(target: self, template: template)
    }
    public subscript<T>(pattern: RegexLiteral, templates: [T]) -> String {
        return Regex<T>(pattern: pattern).replacing(target: self, templates: templates)
    }
    public subscript<T>(pattern: RegexLiteral, group: Int, template: T) -> String {
        return Regex<T>(pattern: pattern).replacing(target: self, template: template, group: group)
    }
    public subscript<T>(pattern: RegexLiteral, group: Int, templates: [T]) -> String {
        return Regex<T>(pattern: pattern).replacing(target: self, templates: templates, group: group)
    }

    /// switch/case
    public subscript<T>(match: RegexMatch) -> T {
        return Regex<T>(pattern: "").entuple(match: match.match!, from: self)
    }
    public subscript(match: RegexMatch, group: Int) -> String {
        return Regex<String>(pattern: "").entuple(match: match.match!, from: self, group: group)
    }
}

public typealias Regex = TupleRegex

private var regexCache = [UInt: [String: NSRegularExpression]]()

open class TupleRegex<T>: ExpressibleByStringLiteral {

    fileprivate let literal: RegexLiteral

    fileprivate lazy var regex: NSRegularExpression = {
        let pattern = literal.regexPattern, options = literal.regexOptions
        do {
            if let regex = regexCache[options.rawValue]?[pattern] {
                return regex
            }
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            if regexCache[options.rawValue] == nil {
                regexCache[options.rawValue] = [String: NSRegularExpression]()
            }
            regexCache[options.rawValue]![pattern] = regex
            return regex
        } catch {
            fatalError("Could not parse regex: \(pattern) - \(error)")
        }
    }()

    public init(pattern: RegexLiteral) {
        literal = pattern
    }
    public required init(stringLiteral value: String) {
        literal = value
    }

    /// matching
    func matchResult(target: String) -> NSTextCheckingResult? {
        return regex.firstMatch(in: target, options: [], range: target.nsrange())
    }
    open func match(target: String, group: Int? = nil) -> T? {
        return matchResult(target: target).flatMap {
            group != nil && $0.range(at: group!).location == NSNotFound ? nil :
            entuple(match: $0, from: target, group: group)
        }
    }
    open func matches(target: String, group: Int? = nil) -> [T] {
        var out = [T]()
        regex.enumerateMatches(in: target, options: [], range: target.nsrange()) {
            (match: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
            out.append(entuple(match: match!, from: target, group: group))
        }
        return out
    }

    lazy var tupleTypeDescription = "\(T.self)"
    func entuple(match: NSTextCheckingResult, from target: String, group: Int? = nil) -> T {
        if let match = match as? T {
            return match
        }

        func tuple<E>(from array: inout [E]) -> T? {
            if let tuple = array as? T ?? array[0] as? T {
                return tuple
            }
            if MemoryLayout<E>.stride * (array.count - 1) == MemoryLayout<T>.stride &&
                tupleTypeDescription.contains("\(E.self),") {
                return array.withUnsafeBufferPointer {
                    ($0.baseAddress! + 1).withMemoryRebound(to: T.self, capacity: 1) { $0[0] }
                }
            }
            return nil
        }

        let ats = group != nil ? group! ..< group!+1 : 0 ..< match.numberOfRanges
        var ranges: [NSRange] = ats.map { match.range(at: $0) }
        if let ranges = tuple(from: &ranges) {
            return ranges
        }

        var substrs: [Substring?] = ranges.map { target[$0] }
        if let substrs = tuple(from: &substrs) {
            return substrs
        }

        var groups: [String] = substrs.map { String($0 ?? "") }
        if let groups = tuple(from: &groups) {
            return groups
        }

        fatalError("Cannot entuple type \(T.self) from \(groups[1...])")
    }

    /// replacing
    func detuple(newValue: T) -> [String?] {
        let children = Mirror(reflecting: newValue).children
        return children.count != 0 ? children.map { $0.value as? String } : [newValue as? String]
    }
    func groupRange(match: NSTextCheckingResult, replacements: [String?]) -> CountableRange<Int> {
        return replacements.count == 1 ? 0 ..< 1 :
            (match.numberOfRanges == 1 ? 0 : 1) ..< min(match.numberOfRanges, replacements.count + 1)
    }

    open func replacing(target: String, template: T, group: Int? = nil) -> String {
        return replacing(target: target, templates: [template], group: group, global: true)
    }
    open func replacing(target: String, templates: [T], group forceGroup: Int? = nil, global: Bool = false) -> String {
        var out = [Substring]()
        var pos = 0, matchno = 0

        regex.enumerateMatches(in: target, options: [], range: target.nsrange()) {
            (match: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
            guard let match = match else { return }
            let replacements = detuple(newValue: global ? templates[0] : templates[matchno])

            matchno += 1
            if !global && matchno == templates.count {
                stop.pointee = true
            }

            for group in forceGroup != nil ? forceGroup! ..< forceGroup! + 1 :
                    groupRange(match: match, replacements: replacements) {
                let range = match.range(at: group)
                if range.location != NSNotFound && range.location >= pos,
                    let replacement = replacements[forceGroup != nil ? 0 : max(0, group - 1)] {
                    out.append(target[NSMakeRange(pos, range.location - pos)] ?? "Invalid range 1")
                    out.append(Substring(regex.replacementString(for: match, in: target, offset: 0,
                                                                 template: replacement)))
                    pos = NSMaxRange(range)
                }
            }
        }

        out.append(target[target.nsrange(pos: pos)] ?? "Invalid range 2")
        return out.joined()
    }
    open func replacing(target: String, group: Int = 0, exec closure: (T, UnsafeMutablePointer<ObjCBool>) -> String) -> String {
        var out = [Substring]()
        var pos = 0

        regex.enumerateMatches(in: target, options: [], range: target.nsrange()) {
            (match: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
            guard let match = match else { return }
            let range = match.range(at: group)
            out.append(target[NSMakeRange(pos, range.location - pos)] ?? "Invalid range 3")
            out.append(Substring(closure(entuple(match: match, from: target), stop)))
            pos = NSMaxRange(range)
        }

        out.append(target[target.nsrange(pos: pos)] ?? "Invalid range 4")
        return out.joined()
    }

    /// interating
    private struct TupleIterator: IteratorProtocol {
        let regex: Regex<T>
        let target: String
        let group: Int?
        var pos: Int

        public mutating func next() -> T? {
            if let match = regex.regex.firstMatch(in: target, options: [], range: target.nsrange(pos: pos)) {
                pos = NSMaxRange(match.range)
                return regex.entuple(match: match, from: target, group: group)
            }
            return nil
        }
    }
    open func iterator(target: String, group: Int? = nil) -> AnyIterator<T> {
        var iterator = TupleIterator(regex: self, target: target, group: group, pos: 0)
        return AnyIterator {
            iterator.next()
        }
    }
}

/// use in switch
public class RegexMatch {
    var match: NSTextCheckingResult?
    public init() {}
}

extension RegexLiteral {
    public func regex(capture: RegexMatch?) -> RegexPattern {
        return RegexPattern(literal: self, capture: capture)
    }
}

public struct RegexPattern {
    let literal: RegexLiteral
    let capture: RegexMatch?
    public static func ~= (pattern: RegexPattern, value: String) -> Bool {
        if let match = Regex<String>(pattern: pattern.literal).matchResult(target: value) {
            pattern.capture?.match = match
            return true
        }
        return false
    }
}
