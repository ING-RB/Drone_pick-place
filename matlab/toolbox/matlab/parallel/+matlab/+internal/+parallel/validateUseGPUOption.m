function useGPUOption = validateUseGPUOption(useGPUOption)
%validateUseGPUOption Validates the value of the name-value argument UseGPU provided
%
%   Use matlab.internal.parallel.validateUseGPUOption to validate the
%   customer-provided value for the name-value argument UseGPU. This
%   name-value argument enables GPU acceleration with Parallel Computing
%   Toolbox.
%
%   useGPUOption =
%   matlab.internal.parallel.validateUseGPUOption(useGPUOption) returns one
%   of the sanitized options ("on", "off", or "auto"), or throws an
%   appropriate error with throwAsCaller.
%
%      Valid values for useGPUOption are:
%         - scalar text with value: "on", "off", "auto"
%         - scalar logical, where TRUE is equivalent to "on", and FALSE
%           equivalent to "off"
%
%   All errors are thrown using throwAsCaller, so wrapping calls to
%   validateUseGPUOption in try/catch is not recommended.
%
%   See also matlab.internal.parallel.resolveUseGPU, canUseGPU, gpuDevice, validateGPU.

%   Copyright 2024 The MathWorks, Inc.


% Validate and resolve the option provided to one of the text values.
if matlab.internal.datatypes.isScalarText(useGPUOption)
    validOptions = ["on", "off", "auto"];
    partialMatch = startsWith(validOptions, useGPUOption, "IgnoreCase", true);
    if sum(partialMatch) > 1
        % Ambiguous option provided
        ME = MException(message("MATLAB:parallel:gpu:UseGPUAmbiguousValue", useGPUOption));
        throwAsCaller(ME);
    elseif sum(partialMatch) == 0
        % Invalid option provided
        ME = MException(message("MATLAB:parallel:gpu:UseGPUInvalidValue"));
        throwAsCaller(ME);
    end
    useGPUOption = validOptions(partialMatch);
elseif isscalar(useGPUOption) ...
        && (islogical(useGPUOption) || (isnumeric(useGPUOption) && (useGPUOption == 0 || useGPUOption == 1)))
    % Convert to string version. Logical values are ONLY allowed for
    % backwards compatibility where true == "on" and false == "off".
    if useGPUOption
        useGPUOption = "on";
    else
        useGPUOption = "off";
    end
else
    ME = MException(message("MATLAB:parallel:gpu:UseGPUInvalidValue"));
    throwAsCaller(ME);
end

end