//
//  TupleRegex.swift
//  SwiftRegex5
//
//  Created by John Holdsworth on 13/01/2018.
//  Copyright © 2018 John Holdsworth. All rights reserved.
//
//  Repo: https://github.com/johnno1962/SwiftRegex5
//
//  $Id: //depot/SwiftRegex5/SwiftRegex5.playground/Sources/TupleRegex.swift#7 $
//

import Foundation

/// Regex literal can be suffixed
/// e.g. "[A-Z]+".caseInsensitve
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

/// extensions to String
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

    /// longhand API and bridge to implementation class
    public func containsMatch(of regex: RegexLiteral) -> Bool {
        return RegexImpl<String>(pattern: regex).matchResult(target: self) != nil
    }
    public func firstMatch<T>(of regex: RegexLiteral, group: Int? = nil) -> T? {
        return RegexImpl<T>(pattern: regex).match(target: self, group: group)
    }
    public func allMatches<T>(of regex: RegexLiteral, group: Int? = nil) -> [T] {
        return RegexImpl<T>(pattern: regex).matches(target: self, group: group)
    }
    public func lazyMatches<T>(of regex: RegexLiteral, group: Int? = nil) -> AnyIterator<T> {
        return RegexImpl<T>(pattern: regex).iterator(target: self, group: group)
    }
    public func replacing<T>(regex: RegexLiteral, group: Int? = nil, with template: T) -> String {
        return RegexImpl<T>(pattern: regex).replacing(target: self, group: group, template: template)
    }
    public func replacing<T>(regex: RegexLiteral, group: Int? = nil, with templates: [T]) -> String {
        return RegexImpl<T>(pattern: regex).replacing(target: self, group: group, templates: templates)
    }
    public func replacing<T>(regex: RegexLiteral, group: Int? = nil,
                             exec closure: (T, UnsafeMutablePointer<ObjCBool>) -> String) -> String {
        return RegexImpl<T>(pattern: regex).replacing(target: self, group: group, exec: closure)
    }
}

/// build subscript based shorthand on API
extension String {

    /// plain old string regex pattern matches
    public subscript(pattern: RegexLiteral) -> Bool {
        return containsMatch(of: pattern)
    }

    /// single match and global replace
    public subscript<T>(pattern: RegexLiteral) -> T? {
        get { return firstMatch(of: pattern) }
        set(newValue) { self = replacing(regex: pattern, with: newValue!) }
    }

    /// mutliple match and selective replace
    public subscript<T>(pattern: RegexLiteral) -> [T] {
        get { return allMatches(of: pattern) }
        set(newValues) { self = replacing(regex: pattern, with: newValues) }
    }

    /// operating on individual group
    public subscript(pattern: RegexLiteral, group: Int) -> String? {
        get { return firstMatch(of: pattern, group: group) }
        set(newValue) { self = replacing(regex: pattern, group: group, with: newValue!) }
    }
    public subscript<T>(pattern: RegexLiteral, group: Int) -> [T] {
        get { return allMatches(of: pattern, group: group) }
        set(newValue) { self = replacing(regex: pattern, group: group, with: newValue) }
    }


    /// closure replace
    public subscript<T>(pattern: RegexLiteral) -> (T, UnsafeMutablePointer<ObjCBool>) -> String {
        get { fatalError("Invalid get of closure") }
        set(closure) { self = replacing(regex: pattern, exec: closure) }
    }

    public subscript<T>(pattern: RegexLiteral, group: Int) -> (T, UnsafeMutablePointer<ObjCBool>) -> String {
        get { fatalError("Invalid get of closure") }
        set(closure) { self = replacing(regex: pattern, group: group, exec: closure) }
    }

    /// inplace replace
    public subscript(pattern: RegexLiteral, template: String) -> String {
        return replacing(regex: pattern, with: template)
    }
    public subscript<T>(pattern: RegexLiteral, templates: [T]) -> String {
        return replacing(regex: pattern, with: templates)
    }
    public subscript<T>(pattern: RegexLiteral,
        closure: (T, UnsafeMutablePointer<ObjCBool>) -> String) -> String {
            return replacing(regex: pattern, exec: closure)
    }
    public subscript<T>(pattern: RegexLiteral, group: Int, template: T) -> String {
        return replacing(regex: pattern, group: group, with: template)
    }
    public subscript<T>(pattern: RegexLiteral, group: Int, templates: [T]) -> String {
        return replacing(regex: pattern, group: group, with: templates)
    }
    public subscript<T>(pattern: RegexLiteral, group: Int,
        closure: (T, UnsafeMutablePointer<ObjCBool>) -> String) -> String {
            return replacing(regex: pattern, group: group, exec: closure)
    }

    /// lazy iterators
    public subscript<T>(pattern: RegexLazy) -> AnyIterator<T> {
        return lazyMatches(of: pattern.literal)
    }
    public subscript<T>(pattern: RegexLazy, group: Int) -> AnyIterator<T> {
        return lazyMatches(of: pattern.literal, group: group)
    }

    /// future compiler-aware regex literals...
    public subscript<T>(regex: RegexImpl<T>) -> T? {
        get { return regex.match(target: self) }
        set(newValue) { self = regex.replacing(target: self, template: newValue!) }
    }
    public subscript<T>(regex: RegexImpl<T>) -> [T] {
        get { return regex.matches(target: self) }
        set(newValues) { self = regex.replacing(target: self, templates: newValues) }
    }
    public subscript<T>(regex: RegexImpl<T>) -> (T, UnsafeMutablePointer<ObjCBool>) -> String {
        get { fatalError("Invalid get of closure") }
        set(closure) { self = regex.replacing(target: self, exec: closure) }
    }
}

extension String {
    /// explicit versions if you prefer
    public subscript(pattern: RegexLiteral, group group: Int) -> String? {
        get { return firstMatch(of: pattern, group: group) }
        set(newValue) { self = replacing(regex: pattern, group: group, with: newValue!) }
    }
    public subscript<T>(pattern: RegexLiteral, group group: Int) -> [T] {
        get { return allMatches(of: pattern, group: group) }
        set(newValue) { self = replacing(regex: pattern, group: group, with: newValue) }
    }
    public subscript<T>(pattern: RegexLiteral, group group: Int) -> (T, UnsafeMutablePointer<ObjCBool>) -> String {
        get { fatalError("Invalid get of closure") }
        set(closure) { self = replacing(regex: pattern, group: group, exec: closure) }
    }
    public subscript<T>(pattern: RegexLiteral, substitute template: T) -> String {
        return replacing(regex: pattern, with: template)
    }
    public subscript<T>(pattern: RegexLiteral, substitute templates: [T]) -> String {
        return replacing(regex: pattern, with: templates)
    }
    public subscript<T>(pattern: RegexLiteral,
        substitute closure: (T, UnsafeMutablePointer<ObjCBool>) -> String) -> String {
            return replacing(regex: pattern, exec: closure)
    }
    public subscript<T>(pattern: RegexLiteral, group group: Int, substitute template: T) -> String {
        return replacing(regex: pattern, group: group, with: template)
    }
    public subscript<T>(pattern: RegexLiteral, group group: Int, substitute templates: [T]) -> String {
        return replacing(regex: pattern, group: group, with: templates)
    }
    public subscript<T>(pattern: RegexLiteral, group group: Int,
        substitute closure: (T, UnsafeMutablePointer<ObjCBool>) -> String) -> String {
            return replacing(regex: pattern, group: group, exec: closure)
    }
}

/// interface to Regex engine in use
public typealias RegexImpl = TupleRegex

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

        // https://stackoverflow.com/questions/24746397/how-can-i-convert-an-array-to-a-tuple
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

    open func replacing(target: String, group: Int? = nil, template: T) -> String {
        return replacing(target: target, group: group, templates: [template], global: true)
    }
    open func replacing(target: String, group forceGroup: Int? = nil, templates: [T], global: Bool = false) -> String {
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
    open func replacing(target: String, group: Int? = nil,
                        exec closure: (T, UnsafeMutablePointer<ObjCBool>) -> String) -> String {
        var out = [Substring]()
        var pos = 0

        regex.enumerateMatches(in: target, options: [], range: target.nsrange()) {
            (match: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
            guard let match = match else { return }
            let range = match.range(at: group ?? 0)
            out.append(target[NSMakeRange(pos, range.location - pos)] ?? "Invalid range 3")
            out.append(Substring(closure(entuple(match: match, from: target), stop)))
            pos = NSMaxRange(range)
        }

        out.append(target[target.nsrange(pos: pos)] ?? "Invalid range 4")
        return out.joined()
    }

    /// interating
    private struct TupleIterator: IteratorProtocol {
        let regex: RegexImpl<T>
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
extension String {
    public subscript<T>(match: RegexMatch) -> T {
        return RegexImpl<T>(pattern: "").entuple(match: match.match!, from: self)
    }
    public subscript(match: RegexMatch, group: Int) -> String {
        return RegexImpl<String>(pattern: "").entuple(match: match.match!, from: self, group: group)
    }
}

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
        if let match = RegexImpl<String>(pattern: pattern.literal).matchResult(target: value) {
            pattern.capture?.match = match
            return true
        }
        return false
    }
}
