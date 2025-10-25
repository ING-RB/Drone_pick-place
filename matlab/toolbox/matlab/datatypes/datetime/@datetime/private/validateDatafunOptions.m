function [omitMissing,missingFlag,haveOtherFlag,lookFor] = validateDatafunOptions(option,errIDs,lookFor,isMinMax)
%VALIDATEDATAFUNOPTIONS Validate the missing, linear, and output type flags for datetime datafun methods.
%
%   On input
%      * option is the flag to validate
%      * errIDs is one or three error msg IDs
%      * (optional) lookFor is a scalar struct with a logical scalar in its .missingFlag,
%        .linearFlag, and .outputFlag fields (all required). This is used to control
%        what flags are legal in various cases, and especially when processing the
%        second of two flags.
%
%   * errIDs(1) is thrown for unrecognized flag
%   * Optional errIDs(2) is thrown for missingFlag provided when not expected.
%     All callers accept missingflag, so the only time it is not expected is if
%     it is provided twice
%   * Optional errIDs(3) is thrown for 'linear' provided when not expected,
%     either not accepted by the function, or provided twice
%
%   On output (assuming no error thrown)
%      * omitMissing contains
%        - true, if option was 'omitmissing/nat/nan'
%        - false, if option was 'includemissing/nat/nan'
%        - the default, if option was 'linear' or 'native'/'default'
%      * otherFlag contains
%        - true, if option was 'linear' or 'native'/'default', depending on caller
%        - the default, if option was 'include/omitmissing/nat/nan'
%      * lookFor contains an updated logical scalar in one of its fields, depending on
%        what was found in option. This is used when processing two flags.

%   Copyright 2015-2023 The MathWorks, Inc.

% The default omitMissing for all callers except min/max is false. Those two
% callers need their own true default, and OR the output from here with that.
if nargin == 2 % median, std
    lookFor.missingFlag = true;
    lookFor.linearFlag = false;
    lookFor.outputFlag = false;
    omitMissing = false;
    missingFlag = "includemissing";
    % don't need a default for haveOtherFlag, that's an error for these callers
elseif nargin == 3 || ~isMinMax % mean
    omitMissing = false;
    missingFlag = "includemissing";
    haveOtherFlag = true; % never used anyway
else % isMinMax
    omitMissing = true;
    missingFlag = "omitmissing";
    haveOtherFlag = false;
end

try
    choices = ["omitmissing" "includemissing" "omitnat" "includenat" "omitnan" "includenan" "linear"  "native" "default" "double"];
    aliases = [1 2 1 2 1 2 7 8 8 9];
    choice = matlab.internal.datatypes.getChoice(option,choices,aliases,errIDs(1));
catch ME
    throwAsCaller(ME);
end

if choice <= 2 % "omitXXX" or "includeXXX"
    if ~lookFor.missingFlag % missingFlag provided twice
        errID = errIDs(1 + ~isscalar(errIDs)); % use second err msg if there
        throwAsCaller(MException(message(errID)));
    end
    omitMissing = (choice == 1);
    missingFlag = choices(choice);
    lookFor.missingFlag = false;
elseif choice == 7 % "linear"
    if ~lookFor.linearFlag % either 'linear' is not legal, or provided twice
        errID = errIDs(1 + 2*~isscalar(errIDs)); % use third err msg if there
        throwAsCaller(MException(message(errID)));
    end
    haveOtherFlag = true;
    lookFor.linearFlag = false;
elseif choice == 8 % "native" "default"
    if ~lookFor.outputFlag
        throwAsCaller(MException(message(errIDs(1))));
    end
    haveOtherFlag = true; % never used anyway
    lookFor.outputFlag = false;
else % choice == 9 % "double"
    if ~lookFor.outputFlag
        throwAsCaller(MException(message(errIDs(1))));
    else
        throwAsCaller(MException(message('MATLAB:datetime:InvalidNumericConversion',option)));
    end
end
