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
extension ValueWrapper
    where
    Self: WithSpecification & AutoValidatable
{
    func validate() throws
    {
        try type(of: self).check(value)
    }

    func validValue(
        ) throws -> Self.Value
    {
        try validate()

        //---

        return value
    }

    /**
     Validates and returns 'value' regardless of its validity,
     puts any encountered validation errors in the 'collectError'
     array. Any unexpected occured error (except 'ValidationError')
     will be thrown immediately.
     */
    func validValue(
        _ collectError: inout [ValidationError]
        ) throws -> Self.Value
    {
        do
        {
            try validate()
        }
        catch let error as ValidationError
        {
            collectError.append(error)
        }
        catch
        {
            // an unexpected error should be thrown to the upper level
            throw error
        }

        //---

        return value // return value regardless of its validity!
    }
}

// MARK: - Private validation helpers

private
extension ValueWrapper
    where
    Self: WithSpecification & AutoValidatable
{
    static
    func check(_ valueToCheck: Value) throws
    {
        let failedConditions = try Specification
            .collectFailedConditions(valueToCheck)

        //---

        if
            let validatableValue = valueToCheck as? Validatable,
            Specification.performBuiltInValidation
        {
            try checkNestedValidatable(
                value: validatableValue,
                failedConditions: failedConditions
            )
        }
        else
        {
            try justCheckFailedConditions(
                failedConditions,
                with: valueToCheck
            )
        }
    }

    static
    func justCheckFailedConditions(
        _ failedConditions: [String],
        with checkedValue: Value
        ) throws
    {
        if
            !failedConditions.isEmpty
        {
            throw ValidationError.valueIsNotValid(
                origin: displayName,
                value: checkedValue,
                failedConditions: failedConditions,
                report: Specification.prepareReport(
                    value: checkedValue,
                    failedConditions: failedConditions,
                    builtInValidationIssues: [],
                    suggestedReport: Specification.defaultValidationReport(
                        with: failedConditions
                    )
                )
            )
        }
    }

    static
    func checkNestedValidatable(
        value validatableValueToCheck: Validatable,
        failedConditions: [String]
        ) throws
    {
        do
        {
            try validatableValueToCheck.validate()
        }
        catch ValidationError.entityIsNotValid(_, let issues, let report)
        {
            throw reportNestedValidationFailed(
                checkedValue: validatableValueToCheck,
                failedConditions: failedConditions,
                builtInValidationIssues: issues,
                builtInReport: report
            )
        }
        catch let error as ValidationError
        {
            throw reportNestedValidationFailed(
                checkedValue: validatableValueToCheck,
                failedConditions: failedConditions,
                builtInValidationIssues: [error],
                builtInReport: nil
            )
        }
        catch
        {
            // an unexpected error, just throw it right away
            throw error
        }
    }

    static
    func reportNestedValidationFailed(
        checkedValue: Validatable,
        failedConditions: [String],
        builtInValidationIssues: [ValidationError],
        builtInReport: (title: String, message: String)?
        ) -> ValidationError
    {
        let baseReport = Specification
            .defaultValidationReport(with: failedConditions)

        let finalReport = builtInReport
            .map{(
                title: baseReport.title,
                message: """
                \(baseReport.message)
                ———
                \($0.message)
                ———
                """
                )}
            ?? baseReport

        //---

        return .nestedValidationFailed(
            origin: displayName,
            value: checkedValue,
            failedConditions: failedConditions,
            builtInValidationIssues: builtInValidationIssues,
            report: Specification.prepareReport(
                value: checkedValue,
                failedConditions: failedConditions,
                builtInValidationIssues: builtInValidationIssues,
                suggestedReport: finalReport
            )
        )
    }
}
