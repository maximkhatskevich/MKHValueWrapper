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
enum ValidationError: Error
{
    case mandatoryValueIsNotSet(
        origin: String,
        report: (title: String, message: String)
    )

    case valueIsNotValid(
        origin: String,
        value: Any,
        failedConditions: [String],
        report: (title: String, message: String)
    )

    indirect
    case nestedValidationFailed(
        origin: String,
        value: Any,
        failedConditions: [String],
        builtInValidationIssues: [ValidationError],
        report: (title: String, message: String) // from current level
    )

    indirect
    case entityIsNotValid(
        origin: String,
        issues: [ValidationError],
        report: (title: String, message: String)
    )

    //---

    public
    var origin: String
    {
        switch self
        {
            case .mandatoryValueIsNotSet(let result, _):
                return result

            case .valueIsNotValid(let result, _, _, _):
                return result

            case .nestedValidationFailed(let result, _, _, _, _):
                return result

            case .entityIsNotValid(let result, _, _):
                return result
        }
    }

    public
    var report: (title: String, message: String)
    {
        switch self
        {
            case .mandatoryValueIsNotSet(_, let result):
                return result

            case .valueIsNotValid(_, _, _, let result):
                return result

            case .nestedValidationFailed(_, _, _, _, let result):
                return result

            case .entityIsNotValid(_, _, let result):
                return result
        }
    }

    public
    var hasNestedIssues: Bool
    {
        switch self
        {
            case .nestedValidationFailed:
                return true

            case .entityIsNotValid:
                return true

            default:
                return false
        }
    }
}
