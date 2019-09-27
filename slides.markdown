## Patterns in Swift’s Standard Library
### Nicholas Lindley

^ Introduce self

^ Title

^ Originally I was going to call this Functional Swift. I didn’t because there are a lot of things I didn’t want to talk about, such as higher-order functions or closures, or laziness. I wanted this to be narrower.

^ I also didn’t want to mention Category Theory because I was afraid I’d scare people off, with functors and applicative functors and monads. But really that’s what I _wanted_ to talk about.

^ Well, let’s get started, and feel free to interrupt me at any time if you have questions.

---

# Motivation

## Optional

^ To explain the motivation for this talk, I’d first like to talk about the Optional type. As you all know, this is a built-in type that may or may not have a value

---

# Optional

^ I was looking through some code at work one day and ran across something that looked like this. Essentially we were needing to transform a value inside of an Optional.

^ Something about this seemed off, but I wasn’t sure immediately why. We have this nice syntax sugar for optional chaining that allows you to safely call a property, method, or subscript, but we aren’t really chaining anything here. But still, why was this so verbose?

^ Everything happening here is really quite reasonable. We want to return `nil` if `imagePath` is `nil`, and we want to transform the value if it exists. We know that `imageEnd` exists here when the question is true, so force unwrapping is safe, although I always feel a little dirty using it.

^ Maybe in some contexts you could replace this with a `guard` or `if let` statement. Maybe we could replace it with a `try?`.

```swift
let imagePath: String?
  = imageEnd != nil
  ? "https://example.com/v1/Images?imagePath=\(imageEnd!)"
  : nil
```

---

# Optional

^ At its most basic, Optional is an enum with two cases, none and some, although you don’t normally hear people say “none,” you hear “nil.”

^ `nil` is syntax sugar.

```swift
@frozen
public enum Optional<Wrapped>: ExpressibleByNilLiteral {
  case none
  case some(Wrapped)
}
```

---

# Optional

> Syntactic sugar causes cancer of the semicolon.
-- Alan Perlis[^1]

[^1]: From ACM's SIGPLAN publication, (September, 1982), Article "Epigrams in Programming", by Alan J. Perlis of Yale University.

^ Already we’ve talked about two examples of syntax sugar. Now I’m not going to argue that you shouldn’t use the syntax sugar. It’s admittedly convenient, and I find it easier to read, but I am going to argue that it helps to understand the type that lies underneath the syntax.

^ In this case `Optional` is just an enum, so that means we can treat it as though it’s nothing special.

---

# Maybe
## Haskell

^ I was familiary with the Optional type from other languages.
^ In Haskell it’s called a Maybe.

```haskell
data Maybe a = Just a | Nothing
    deriving (Eq, Ord)
```

---

# Maybe
## Elm

^ It’s pretty similar in Elm

```elm
type Maybe a
    = Just a
    | Nothing
```

---

# Option
## Rust

^ Rust and OCaml call it `Option`.

^ Here is Rust. If you can look past all these annotations, then you’ll see `None` and `Some` and a generic `T` at the end.

```rust
pub enum Option<T> {
    #[stable(feature = "rust1", since = "1.0.0")]
    None,
    #[stable(feature = "rust1", since = "1.0.0")]
    Some(#[stable(feature = "rust1", since = "1.0.0")] T),
}
```

---

# Option
## OCaml

^ This is is in OCaml. It looks more like Haskell and Elm.

^ But you’ll see this structure in a lot of programming, especially those with some influence from the statically-typed functional world.

^ All right. This structure is familiar, and I let my team know it’s familiar.

```ocaml
type 'a t = 'a option = None | Some of 'a
```

---

# Words

^ I shot off a long message in Slack that went something like:

> Often times you’ll see this presented as the `Maybe` _monad_ (there it is). The reason I mention the “M” word is because a monad is also a _functor_, and a functor is a _map_ between categories. This is a long way of saying optional types are mappable, like so:
-- Me

---

# Monads

^ OK, OK, now I’m off talking about Monads.

> Wadler tries to appease critics by explaining that "a monad is a monoid in the category of endofunctors, what's the problem?"[^1]

[^1]: A Brief, Incomplete, and Mostly Wrong History of Programming Languages, http://james-iry.blogspot.com/2009/05/brief-incomplete-and-mostly-wrong.html

---

# Functor

^ But what I was trying to get at was `map` isn’t reserved for sequences and collections. You’re probably used to seeing `map` used with Arrays like so:

```swift
let doubles = [1, 2, 3].map { $0 * 2 }
```

---

# Functor

^ But if we look through the Optional source, we will find a `map` there as well.

^ (code highlights)

^ `map` is a method that takes a transform function that takes in type wrapped by the Optional, and returns an Optional of a potentially different type, but it’s important to note that it is still an Optional and that we have handled all of our cases. Another interesting part is in the `.none` case we return `.none`. The allows us to continue to chain on calls to `map`, and if it is `.none`, all the subsequent call will also be `.none`, which is the same thing as `nil` in Swift.

[.code-highlight: all]
[.code-highlight: 2]
[.code-highlight: 3]
[.code-highlight: 4]
[.code-highlight: 6]
[.code-highlight: 8]
[.code-highlight: 9]
[.code-highlight: all]

```swift
@inlinable
public func map<U>(
  _ transform: (Wrapped) throws -> U
) rethrows -> U? {
  switch self {
  case .some(let y):
    return .some(try transform(y))
  case .none:
    return .none
  }
}
```

---

# Refactor

^ Now we’ll go back to the example above and reimplement it with `map`.

```swift
let imagePath: String?
  = imageEnd != nil
  ? "https://example.com/v1/Images?imagePath=\(imageEnd!)"
  : nil
```

---

# Refactor

^ I’m using the shorthand notation `$0` here because it fits on the slide better, but the more interesting part is we’ve gotten rid of the ternary, we’ve removed the force unwrap, we’re more concise, and we’re still type-safe.

```swift
let imagePath = imageEnd.map { "https://example.com/v1/Images?imagePath=\($0)" }
```

---

# Collection

^ With this in mind, I decided to see where else we could find `map` in the standard libary. Here is the default implementation in the Collection protocol. It looks similar, but you’ll notice this is dealing with iterables since Collection inherits the Sequence protocol.

^ But this is nice because anything that is a Collection should have a `map`.

```swift
extension Collection {
  @inlinable
  public func map<T>(
    _ transform: (Element) throws -> T
  ) rethrows -> [T] {
    let n = self.count
    if n == 0 {
      return []
    }

    var result = ContiguousArray<T>()
    result.reserveCapacity(n)

    var i = self.startIndex

    for _ in 0..<n {
      result.append(try transform(self[i]))
      formIndex(after: &i)
    }

    _expectEnd(of: self, is: i)
    return Array(result)
  }
}
```

---

# Sequence

^ Speaking of Sequence, there’s a map in there, too. Now the implementation is a little different, but the type signature is exactly the same.

```swift
extension Sequence {
  @inlinable
  public func map<T>(
    _ transform: (Element) throws -> T
  ) rethrows -> [T] {
    let initialCapacity = underestimatedCount
    var result = ContiguousArray<T>()
    result.reserveCapacity(initialCapacity)

    var iterator = self.makeIterator()

    for _ in 0..<initialCapacity {
      result.append(try transform(iterator.next()!))
    }

    while let element = iterator.next() {
      result.append(try transform(element))
    }
    return Array(result)
  }
}
```

---

# Functor?

^ If we commit to only using pure functions, then we effectivly have this, and now you should clearly be able to see the abstraction. What we’re looking for is a way to have the outer part be generic. In some languages this is called higher-kinded types.

```swift
// Optional
func map<U>(_ transform: (T) -> U) ->  Optional<U>
// Collection
func map<U>(_ transform: (T) -> U) ->     Array<U>
// Sequence
func map<U>(_ transform: (T) -> U) ->     Array<U>
// Result
func map<U>(_ transform: (T) -> U) -> Result<U, V>
```

---

# Functor?

^ Now, did anybody notice the return type for the default implementations of `map` in Collection and Sequence? Isn’t it a little curious that we are returning an `Array` from each of these? Does anybody know why?

---

# Functor
## Higher-Kinded Type

^ If we really wanted Functor to be generic, then we would have to be able to make the containing type generic, not just the wrapped type. This is a concept known as Higher-Kinded

^ It’s been discussed as an addition to the language and is listed under the “Maybe” section of the Swift repository’s “Generics Manifesto,” but until they have motivating examples of how it would make Swift developers lives better, it sounds like it won’t be added.

^ This is the point where I get a little bummed, but I know there are some other goodies hiding in here, so I go looking for `flatMap` because I know it exists, and I suspect it’s works a lot like the `Monad` thing I mentioned earlier.

---

# flatMap
## JavaScript

^ In the pre-Swift 4.1 days, `flatMap` was commonly used as `compactMap` is used now. Who all had to change a bunch of their `flatMap` code to `compactMap`? Who is still uses `flatMap`?

^ Well, `flatMap` is also pretty common in libraries across languages.

```javascript
Array.prototype.flatMap ( mapperFunction [ , thisArg ] ) // ES2019
_.flatMap(collection, [iteratee=_.identity]) // lodash
R.chain(fn, list) // Ramda
```

---

# andThen/concatMap
## Elm

```elm
andThen : Maybe a -> (a -> Maybe b) -> Maybe
concatMap : (a -> List b) -> List a -> List b b
```

---

# merged
## Rust

```rust
let words = ["alpha", "beta", "gamma"];
let merged: String = words.iter()
                          .flat_map(|s| s.chars())
                          .collect();
```

---

# >>=
## Haskell

^ In Haskell there’s this funny little operator called bind, or you’ll hear it referred to as Monadic bind. We’ll come back to the Monad part in a minute.

```haskell
(>>=) :: Monad m => m a -> (a -> m b) -> m b
```

---

# flatMap
## Swift

^ The reason we have a `flatMap` as well is to flatten the wrapped type by one level. So let’s say we have a list, and the iterator returns a list, now we have nested list of lists. If we want this to just be list of elements, then we can use flatMap.

```swift
["abc", "def", "ghi"].map { Array($0) }
// [["a", "b", "c"], ["d", "e", "f"], ["g", "h", "i"]]

["abc", "def", "ghi"].flatMap { Array($0) }
// ["a", "b", "c", "d", "e", "f", "g", "h", "i"]
```

---

# Result

^ We glanced at Result earlier, but this is a new enum in Swift 5, and it looks something like this.

^ What interesting about Result is it also has an Error case. In other languages it might be called an `Either` with a `Left` and a `Right` instead of `Success` and `Failure`. You can see that `Failure` has to conform to the `Error` protocol. Fortunately that easy since it doesn’t have any requirements. It appears to be there to communicate intent.

```swift
public enum Result<Success, Failure: Error> {
  /// A success, storing a `Success` value.
  case success(Success)

  /// A failure, storing a `Failure` value.
  case failure(Failure)
}
```

---

# Result
## map

^ Result was pretty popular enum before Swift 5, but since people would often roll their own, it didn’t always have the conviences of `map`, `flatMap`, and the like.

^ Here’s `map`. If you look at the `success` case, you’ll notice it applies the transform and returns another success. If not, it skips the transform and returns the failure as is. This lets us chain together several transformations in a row and only care about the happy path.

```swift
public func map<NewSuccess>(
  _ transform: (Success) -> NewSuccess
) -> Result<NewSuccess, Failure> {
  switch self {
  case let .success(success):
    return .success(transform(success))
  case let .failure(failure):
    return .failure(failure)
  }
}
```

---

# Result
## mapError

^ If you really want to transorm the error, that’s possible, too.

```swift
public func mapError<NewFailure>(
  _ transform: (Failure) -> NewFailure
) -> Result<Success, NewFailure> {
  switch self {
  case let .success(success):
    return .success(success)
  case let .failure(failure):
    return .failure(transform(failure))
  }
}
```

---

# Result
## flatMap

^ Here’s the implementation of flatMap. Since it takes a transform that returns a Result, the success case does not wrap it in a success case. This is how we keep from having nested Results.

^ There’s also a `flatMapErrror` if you find yourself needing that.

```swift
public func flatMap<NewSuccess>(
  _ transform: (Success) -> Result<NewSuccess, Failure>
) -> Result<NewSuccess, Failure> {
  switch self {
  case let .success(success):
    return transform(success)
  case let .failure(failure):
    return .failure(failure)
  }
}
```

---

# Result
## catching body

^ One of my favorite things they did in the standard library implementation of Result was this initializer. This initializer takes a body that could possibly throw. If everything is successful, you see that `self` is assigned to the `success` case, we catch any error, that is we’re not rethrowing, and we’ll assign `self` to the failure case.

^ If, like me, you don’t like dealing with do/catch blocks but you have to deal with code that throws, then this let’s you wrap that up, and then just map over the happy path, handling errors if you’d like, or just allowing them to be returned with the result.

[.code-highlight: all]
[.code-highlight: 3]
[.code-highlight: 4-5]
[.code-highlight: 6-8]
[.code-highlight: all]

```swift
extension Result where Failure == Swift.Error {
  @_transparent
  public init(catching body: () throws -> Success) {
    do {
      self = .success(try body())
    } catch {
      self = .failure(error)
    }
  }
}
```

---

# Result
## Example

[.code-highlight: all]

^ Here’s a pretty simple example of getting taking a URL, fetching it’s contents, decoding it into a struct, and getting the ip property off the JSON response.

[.code-highlight: 4]

^ I am force unwrapping the IP, but I want this app to crash if that’s missing because that should be an exceptional case.

[.code-highlight: 5]
[.code-highlight: 6-9]
[.code-highlight: 10]

^ I try to the get the contents of the URL, wrap that in a Result which lets me map or flatMap over it. I will flatMap over it since the JSON decoding could also fail.

[.code-highlight: 11]

^ On the last line we can use a regular map since we’re passing in a pure function that returns the wrapped type.

[.code-highlight: all]

```swift
struct JsonIpResponse: Decodable {
    let ip: String
}
let url = URL(string: "https://jsonip.com")!
let responseData = Result { try Data(contentsOf: url) }
func decodeJsonIp(_ data: Data) -> Result<JsonIpResponse, Error> {
    let decoder = JSONDecoder()
    return Result { try decoder.decode(JsonIpResponse.self, from: data) }
}
let jsonIpResult = responseData.flatMap(decodeJsonIp)
let ip = jsonIpResult.map { $0.ip }
```

---

# Other Categories?

^ Now that I’ve found a couple of things that look like Functors and Monads, I started looking into some other common categories.

* Monoid
* Semigroup
* Applicative

---

# Monoid?

^ Well, to have a Monoid, we’ll need an empty or zero value.

```haskell
Prelude> :info Monoid
class Semigroup a => Monoid a where
  mempty :: a
  mappend :: a -> a -> a
  mconcat :: [a] -> a
```

---

# Monoid?
## AdditiveArithmetic?

^ Well, I found `zero` in the AdditiveArithmetic protocol, but it certainly isn’t used in any of the other types. Maybe the `+` could act as `mappend` from Haskell? But there’s a lot of stuff we don’t want after that, so I don’t think this will work.

^ Looking for the others, I just wasn’t finding the same, familiar constructs I had with `map` and `flatMap`. As it turns out, and this might surprise you, Swift is not Haskell.

^ And that’s when this presentation got a lot harder to put together. Instead of skimming through the code, looking for the familiar, now I had to look for actual patterns, lest the title of this talk is a lie.

```swift
public protocol AdditiveArithmetic: Equatable {
  static var zero: Self { get }
  static func +(lhs: Self, rhs: Self) -> Self
  static func +=(lhs: inout Self, rhs: Self)
  static func -(lhs: Self, rhs: Self) -> Self
  static func -=(lhs: inout Self, rhs: Self)
}
```

---

^ I started going through all the files in the standard lib. It looks like returning things is pretty popular. It looks like they enjoy talking about Swift quite a bit. Numbers over 4 are less popular. We do have `Element` and `elements`, so that’s kind of interesting. `value` is up there.

![inline fill](wordcloud-stdlib.svg)

---

^ I had also been pulling making notes of a lot of the protocol implemenations, structs, enums, and so on, and this is probably a little more interesting.

^ `class` is up there, but it’s much smaller than `struct` or `value`. Mostly you’ll find the word class in the comments, not the implementation. You’ll also find them for the ocassional internal implementation or when bridging to Objective C code. For the most part you’ll see structs and enums.

![inline fill](wordcloud-notes.svg)

---

# Structs

^ These are a few of the data structures implemented with structs. By the way, when I saw Zip in the source, I was hoping to find an Applicative, but if it’s in there my eyes weren’t keen enough to spot it.

^ Even String is in there, although you’ll have to scroll past about 300 lines of comments to get to the implementation.

* Array
* Bool
* Dictionary
* Range
* Set
* String
* Zip2Sequence

---

# Enums

^ You will see enums used, too, but mostly you’ll work with Optional and Result, which we’ve already discussed. But if you’re wondering why I keep going on about them, it’s because they provide a mechanism for what is known in some languages as tagged unions or discriminated unions or variants.

* Optional
* Result

---

# Classes

^ Here are the classes you’re likely to use. If you’re working with Cocoa, you will end up writing a lot of classes because many APIs expect a subclass of NSObject. But you might see how far you can get without them at least until you reach your presentation layer.

^ I think you’ll find your code easier to reason about since you’re dealing with copies and one function can’t change the data out from under you in an outer function. You’ll also greater thread safety, if you’re mostly reading values, then copy-on-write semantics can give you blazing fast performance, and if you’re not storing pointers to reference types inside your value types, you don’t need to worry about memory leaks since instances of value types are created on the stack—at least that’s my understanding.

* ???

---

# Algebraic Data Types

^ The combination of enums and structs gives you the two most common algebraic data types, i.e. the sum type and the product type, which allows you to cover a lot of ground.

^ We aren’t really going to get into these here, but I wanted you to at least be able to have some search terms in case you wanted to look more into it more.

* sum type - enums
* product type - structs, tuples, classes

---

^ Going back to my notes, we see Collection, BidirectionalCollection, Element, elements, LazyFilterCollection, RangeReplaceableCollection, Array—a lot of things that sound collectiony.

^ We also have Sequence, Range, ClosedRange, CountableClosedRange, Bound, Strideable, Iterator—a lot of things that sound kind of sequency.

^ Array might have been bigger, but we have the syntax sugar which keeps the word Array from showing up as often.

![inline fill](wordcloud-notes.svg)

---

# Collection

^ I’d like to look through some of the protocol implementations from a variety of structs. Collection seems like a good place to start.

^ I chose set because it doesn’t have any other protocols implemented in the same extension.

^ The first thing I see is we start with a getter for start index. You’ll see this `_variant` quite a bit. That was defined on the Set struct, so it’s available for our use in the extensions.

```swift
// Set.swift
extension Set: Collection {
  @inlinable
  public var startIndex: Index {
    return _variant.startIndex
  }
}
```

---

# Collection

^ Then we have another getter for `endIndex`, which is one _greater than_ the last valid subscript argument. In an empty collection this should be the same as `startIndex`.

```swift
extension Set: Collection {
  @inlinable
  public var endIndex: Index {
    return _variant.endIndex
  }
}
```

---

# Collections

^ There are a couple more getters for `count` and `isEmpty`.

^ The thing I’m starting to notice here is the stdlib authors are not afraid of getters. I actually found this a little surprising because I’ve become somewhat averse to them. You will notice however, the implementations of this protocol seems to mostly be passing through arguments to this _variant variable. This seems pretty wise since we don’t want to surprise the users and this should feel more or less like plain-old property access. It would be quite shocking if this called random or made a network request.

```swift
extension Set: Collection {
  @inlinable
  public var count: Int {
    return _variant.count
  }

  /// A Boolean value that indicates whether the set is empty.
  @inlinable
  public var isEmpty: Bool {
    return count == 0
  }
}
```

---

# Collection

^ Then we have subscript. At first I misread this and thought it was a regular function declaration, but `subscript` is a reserverd keyword in Swift. Subscripts can be read-write, or read-only, so you could add a setter to the subscript in your implementation.

^ `subscript` is what makes this work with the square-bracket syntax.

```swift
extension Set: Collection {
  @inlinable
  public subscript(position: Index) -> Element {
    get {
      return _variant.element(at: position)
    }
  }
}
```

---

# Collection

^ Here is our first function for getting and element after an index.

```swift
extension Set: Collection {
  @inlinable
  public func index(after i: Index) -> Index {
    return _variant.index(after: i)
  }
}
```

---

# Collection

^ Here’s `formIndex`. Again, the implementation is on this _variant, and we’re just calling out to it.

```swift
extension Set: Collection {
  @inlinable
  public func formIndex(after i: inout Index) {
    _variant.formIndex(after: &i)
  }
}
```

---

# Collection

^ This one flips the script a bit and finds the index of the element in the Set.

```swift
extension Set: Collection {
  @inlinable
  public func firstIndex(of member: Element) -> Index? {
    return _variant.index(for: member)
  }
}
```

---

# Collection

^ This is kind of weird that we return an Optional of an Optional. The inner Optional is whether or not the member of the Set was found, and the outer Optional is to tell the caller whether or not a linear search should be attempted. Since this is a Set, and we think we can do better than linear time, then we return `.some` instead of `.none` for the outer Optional.

^ There is a default implementation that just return `nil` and attempts a linear search.

```swift
extension Set: Collection {
  @inlinable
  @inline(__always)
  public func _customIndexOfEquatableElement(
     _ member: Element
    ) -> Index?? {
    return Optional(firstIndex(of: member))
  }
}
```

---

# Collection

^ This is like the last one where we have an Optional of an Optional, but we’re trying to return the last element.

^ Similarly, there is a default implementation that just returns `nil`. Also, you may have noticed the word `Equatable` in this one and the last one, and that’s because these are applicable only when dealing with collections of `Equatable` elements.


```swift
extension Set: Collection {
  @inlinable
  @inline(__always)
  public func _customLastIndexOfEquatableElement(
     _ member: Element
    ) -> Index?? {
    return _customIndexOfEquatableElement(member)
  }
}
```

---

# Complexity

^ Speaking of complexity, it’s mentioned 274 times in the standard library.

```swift
/// - Complexity: O(*n*), where *n* is the length of the collection.
/// - Complexity: O(1)
```

^ This is used both in the implementations and the protocols, so this is important to keep in mind whenever implementing a protocol, because users or your implementation will expect certain performance characteristics.

^ If you have shared libraries, you might also consider adding this to your comments to help other members of your team know what they can expect.

^ Now there was something else on every single one of these that I haven’t talked about. Did anybody notice what it was?

---

# @inlinable

^ From the documentation:

Apply this attribute to a function, method, computed property, subscript, convenience initializer, or deinitializer declaration to expose that declaration’s implementation as part of the module’s public interface. The compiler is allowed to replace calls to an inlinable symbol with a copy of the symbol’s implementation at the call site.

^ And there’s some more details in Swift Reference.

---

# @inlinable

^ But `@inlinable` is by far the most commonly used attribute, followed by @inline and @usableFromInline.

^ I would skip `@inline` since it’s not documented, but `@inlinable` and `@usableFromInline` both arrived in Swift 4.2.

* 2422 @inlinable
*  852 @inline
*  621 @usableFromInline
*  527 @_transparent
*  232 @_effects
*  213 @available
*  195 @frozen
*  159 @objc
*  125 @_semantics
*   82 @testable
*   82 @_silgen_name
*   71 @nonobjc
*   67 @_alwaysEmitIntoClient
*   62 @discardableResult
*   49 @_specialize
*   29 @escaping
*   24 @_fixed_layout
*   20 @convention
*   17 @autoclosure
*    8 @specializable
*    7 @opaque
*    6 @_swift_native_objc_runtime_base
*    6 @_nonoverride
*    5 @_borrowed
*    4 @warn_unqualified_access
*    4 @SPI
*    3 @unsafe_no_objc_tagged_pointer
*    3 @_objc_non_lazy_realization
*    2 @_objcRuntimeName
*    2 @_implements
*    2 @_alignment
*    1 @useableFromInline
*    1 @unknown
*    1 @swift_native_objc_runtime_base
*    1 @pointeronly
*    1 @moveonly
*    1 @benchmarkable
*    1 @_show_in_interface
*    1 @_cdecl

---

# @inlinable

^ What `@inlinable` does is exports the body of the function as part of the module’s interface allow the compiler to optimize code across module boundaries. Chances are the apps you’re writing are mostly in one module, or the cost of not having inlined code is negligible compared to the rest of the work that is happening.

^ In something like the standard library where you’d rather be able to specialize generics or eliminate higher-order functions at compile time, these are really handy.

^ But should you use it? Probably not.

^ If you want to read more about these, I would go to this really long URL.

https://github.com/apple/swift-evolution/blob/master/proposals/0193-cross-module-inlining-and-specialization.md

---

# Other

^ There are other things we didn’t really talk about because what they’re using is what you’re using. Hashable and Equatable, which you can often get for free now, Encodable and Decodable, typealiases. Really, it’s mostly just Swift.

^ I say mostly because if you do decide to dig into the Swift standard library, then you’ll find some of these .swift.gyb files, which is just a templating system written in Python. If you want to see how those look, you might start in Codable.swift.gyb.

^ They use a lot of extensions. Extensions are used for organization, implementing protocols, implementing protocols on structures _in other files_.

^ But I didn’t find anything that really left me scratching my head, so I guess what I really want you to get out of this is that the code is quite approachable, it’s much better documented than any code I’ve ever written, and you will also find the occasional FIXME or TODO because it is still a work in progress.

* extension
* Hashable
* Equatable
* Codable
* typealias
* GYB - _Generate Your Boilerplate_
* FIXME/TODO

---

# Questions?

---

# Thank You
