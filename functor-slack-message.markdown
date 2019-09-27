Incoming Swift post not specific to Apple TV…
I noticed a piece of code (not for _redacted_) that looks like

```swift
let imagePath: String? = imageEnd != nil ? "https://example.com/v1/Images?imagePath=\(imageEnd!)" : nil
```

While this gets the job done, it raises something that’s not immediately obvious. First, `nil` is sugar for `Optional.none`, and `Optional` has the following enum:

```swift
public enum Optional<Wrapped> : ExpressibleByNilLiteral {

    /// The absence of a value.
    ///
    /// In code, the absence of a value is typically written using the `nil`
    /// literal rather than the explicit `.none` enumeration case.
    case none

    /// The presence of a value, stored as `Wrapped`.
    case some(Wrapped)
}
```

You can open the Swift REPL and type `Optional.none == nil` if you don’t believe me. Often times you’ll see this presented as the `Maybe` _monad_ (there it is). The reason I mention the “M” word is because a monad is also a _functor_, and a functor is a _map_ between categories. This is a long way of saying optional types are mappable, like so:

```swift
let imagePath = imageEnd.map { "https://example.com/v1/Images?imagePath=\($0)" }
```

We’ve dropped the type annotation, the nil-check/ternary, and the forced unwrap.
