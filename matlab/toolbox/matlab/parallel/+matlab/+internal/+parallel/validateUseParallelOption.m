function parallelSupportRequested = validateUseParallelOption(parallelSupportRequested)
% validateUseParallelOption Validate the UseParallel argument from the user
%
%     Use matlab.internal.parallel.validateUseParallelOption to validate the
%     customer-provided value for the name-value argument UseParallel. This
%     name-value argument enables CPU parallelization with parallel pools
%     and Parallel Computing Toolbox.
%
%     parallelSupportRequested =
%       matlab.internal.parallel.validateUseParallelOption(parallelSupportRequested)
%     returns one of the sanitized options ("on", "off", or "auto"), or throws 
%     an appropriate error using throwAsCaller.
%
%     Valid values for parallelSupportRequested are:
%       - scalar text with value: "on", "off", "auto"
%       - scalar logical, where TRUE is equivalent to "auto", and FALSE
%         equivalent to "off"
%
%     All errors are thrown using throwAsCaller, so wrapping calls to
%     validateUseParallelOption in try/catch is not recommended.
%
%    See also matlab.internal.parallel.resolveUseParallel, parallel.Pool, parpool.

% Copyright 2024 The MathWorks, Inc.

if matlab.internal.datatypes.isScalarText(parallelSupportRequested)
    validOptions = ["on", "off", "auto"];
    partialMatch = startsWith(validOptions, parallelSupportRequested, "IgnoreCase", true);
    if sum(partialMatch) == 1
        parallelSupportRequested = validOptions(partialMatch);
    else
        throwAsCaller(MException(message('MATLAB:parallel:pool:InvalidUseParallel')));
    end
elseif isscalar(parallelSupportRequested) && (islogical(parallelSupportRequested) || ...
        (isnumeric(parallelSupportRequested) && (parallelSupportRequested == 0 || parallelSupportRequested == 1)))
    % Convert to string version.
    if parallelSupportRequested
        % Here is where we decree that UseParallel=true means the same as UseParallel="auto".
        parallelSupportRequested = "auto";
    else
        parallelSupportRequested = "off";
    end
else
    throwAsCaller(MException(message('MATLAB:parallel:pool:InvalidUseParallel')));
end
