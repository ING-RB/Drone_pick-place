function mustBeInRange(value, lowerBound, upperBound, flag1, flag2)
%MUSTBEINRANGE Validate that value is in the specified range
%   MUSTBEINRANGE(A,LOWER,UPPER) throws an error if any element of A is not
%   within the range defined by LOWER and UPPER. A value is within the
%   range if it is greater than or equal to LOWER, and less than or equal to
%   UPPER.
%
%   MUSTBEINRANGE(A,LOWER,UPPER,BOUNDFLAG1,BOUNDFLAG2) Optional flags
%   BOUNDFLAG1 and BOUNDFLAG2 indicate if upper or lower bound is
%   included in the range. The values of the optional flags must be one of
%   the following:
%      "inclusive"
%      "exclusive"
%      "exclude-lower"
%      "exclude-upper"
%   "inclusive" is the default.
%   Use at most two of these values to indicate whether the lower bound
%   and upper bound should be excluded or included from a range. The only
%   valid combination of these flags are "exclude-lower" and
%   "exclude-upper".
%
%   For example, the following call to mustBeInRange validates that A must
%   be greater than 0, and less than or equal to 100:
%
%   mustBeInRange(A,0,100,"exclude-lower");
%
%   MATLAB calls the lt, gt, le, ge functions when comparing a value with
%   boundary values.
%
%   Class support:
%   All numeric or logical classes
%
%   See also GE, GT, LE, LT.

%   Copyright 2020-2024 The MathWorks, Inc.

if ~isnumeric(value) && ~islogical(value)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeNumericOrLogical'));
end

if ~isreal(value)
    throwAsCaller(MException(message('MATLAB:validators:mustBeReal')));
end

if  ~((isnumeric(lowerBound) && isreal(lowerBound)) || isa(lowerBound, 'logical')) || ~isscalar(lowerBound)
    error(message('MATLAB:validatorUsage:invalidLowerBound', 'mustBeInRange'));
end

if  ~((isnumeric(upperBound) && isreal(upperBound)) || isa(upperBound, 'logical')) || ~isscalar(upperBound)
    error(message('MATLAB:validatorUsage:invalidUpperBound', 'mustBeInRange'));
end

includeLower = true;
includeUpper = true;

if nargin > 3
    lowerSet = false;
    upperSet = false;
    flag = flag1;
    options = ["inclusive","exclusive","exclude-lower","exclude-upper"];

    for i=1:nargin-3
        if i == 2; flag = flag2; end

        if ~(ischar(flag) && isrow(flag)) && ~(isstring(flag) && isscalar(flag))
            % emulate an enum conversion error
            E = matlab.internal.validation.classConversionException([], 'mustBeInRange', [], ...
                i+3, 'inclusiveFlags', 'matlab.internal.validation.BoundInclusivity', false, false, "input", flag);
            throw(E);
        end

        option = startsWith(options,flag,'IgnoreCase',true);
        switch option(1)*8+option(2)*4+option(3)*2+option(4)
            case 8
                if ~lowerSet && ~upperSet
                    lowerSet = true;
                    upperSet = true;
                else
                    option = startsWith(options,flag1,'IgnoreCase',true);
                    error(message('MATLAB:validatorUsage:ConflictingBoundaryOptions', options(option==true), 'inclusive'));
                end
            case 4
                if ~lowerSet && ~upperSet
                    lowerSet = true;
                    upperSet = true;
                    includeLower = false;
                    includeUpper = false;
                else
                    option = startsWith(options,flag1,'IgnoreCase',true);
                    error(message('MATLAB:validatorUsage:ConflictingBoundaryOptions', options(option==true), 'exclusive'));
                end
            case 2
                if ~lowerSet
                    lowerSet = true;
                    includeLower = false;
                else
                    option = startsWith(options,flag1,'IgnoreCase',true);
                    error(message('MATLAB:validatorUsage:ConflictingBoundaryOptions', options(option==true), 'exclude-lower'));
                end
            case 1
                if ~upperSet
                    upperSet = true;
                    includeUpper = false;
                else
                    option = startsWith(options,flag1,'IgnoreCase',true);
                    error(message('MATLAB:validatorUsage:ConflictingBoundaryOptions', options(option==true), 'exclude-upper'));
                end
            otherwise
                % emulate an enum conversion error
                E = matlab.internal.validation.classConversionException([], 'mustBeInRange', [], ...
                    i+3, 'inclusiveFlags', 'matlab.internal.validation.BoundInclusivity', false, false, "input", flag);
                throw(E);
        end
    end
end

if includeLower
    if includeUpper
        if all(value >= lowerBound, 'all') && all(value <= upperBound, 'all')
            return;
        end
        messageID = "MATLAB:validators:LeftClosedRightClosed";
    else
        if all(value >= lowerBound, 'all') && all(value < upperBound, 'all')
            return;
        end
        messageID = "MATLAB:validators:LeftClosedRightOpen";
    end
else
    if includeUpper
        if all(value > lowerBound, 'all') && all(value <= upperBound, 'all')
            return;
        end
        messageID = "MATLAB:validators:LeftOpenRightClosed";
    else
        if all(value > lowerBound, 'all') && all(value < upperBound, 'all')
            return;
        end
        messageID = "MATLAB:validators:LeftOpenRightOpen";
    end
end
lowerBoundStr = matlab.internal.display.numericDisplay(lowerBound, "format", "long");
upperBoundStr = matlab.internal.display.numericDisplay(upperBound, "format", "long");
messageObj = message(messageID, lowerBoundStr, upperBoundStr);
throwAsCaller(MException('MATLAB:validators:mustBeInRange', messageObj));
