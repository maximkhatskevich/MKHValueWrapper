/*

 MIT License

 Copyright (c) 2016 Maxim Khatskevich (maxim@khatskevi.ch)

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.

 */

public
protocol ValidatableValue: Validatable, Codable, Equatable
{
    associatedtype RawValue: Codable, Equatable
    associatedtype Validator: ValueValidator where Validator.Input == RawValue
    associatedtype ValidValue

    //---

    init()

    /**
     This property can be freely modified at any point of time.
     This is the value that is pretending to end up as final value
     if it satisfies all conditions.
     */
    var draft: RawValue? { get set }

    /**
     Supposed to evaluate 'draft' against all conditions and
     return a valid value or throw an error if any of the conditions
     is not satisfied.
     */
    func valueIfValid() throws -> ValidValue
}

// MARK: - Automatic 'Codable' conformance

public
extension ValidatableValue
{
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.singleValueContainer()
        try container.encode(draft)
    }

    init(from decoder: Decoder) throws
    {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(RawValue.self)

        //---

        self.init()
        self.draft = value
    }
}

// MARK: - Automatic 'Validatable' conformance

public
extension ValidatableValue
{
    func validate() throws
    {
        _ = try valueIfValid()
    }
}

// MARK: - Convenience helpers

public
extension ValidatableValue
{
    /**
     Convenience initializer that assigns provided value
     as draft, does NOT check its validity.
     */
    init(
        initialValue: RawValue
        )
    {
        self.init()
        self.draft = initialValue
    }

    /**
     Convenience initializer useful for setting a 'let' value,
     that only should be set once during initialization. Assigns
     provided value and validates it right away.
     */
    init(
        const value: RawValue
        ) throws
    {
        self.init()
        try self.set(value)
    }

    /**
     Set new value and validate it in single operation.
     */
    mutating
    func set(_ newValue: RawValue?) throws
    {
        draft = newValue
        try validate()
    }

    /**
     Validate a given value without actually setting it to current value.
     */
    func validate(value: RawValue?) throws
    {
        var tmp = self
        try tmp.set(value)
    }
}
