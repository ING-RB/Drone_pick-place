function initialize(isOutputSuppressed)
% This is an undocumented function and may be removed in a future release.

% Copyright 2018 The MathWorks, Inc.
    narginchk(1,1);

    persistent isInitialized
    persistent suppressedOutput
    if isInitialized
        % This could have been previously called with suppressed output.
        % We want to display that output now if it is no longer suppressed.
        dispOutputIfNotSuppressed
    else
        try
            suppressedOutput = evalc('builtin(''groot'');');
            dispOutputIfNotSuppressed
            isInitialized = true;
        catch e
            if ~isOutputSuppressed
                rethrow(e)
            end
        end
    end

    function dispOutputIfNotSuppressed
        if ~isOutputSuppressed && ~isempty(suppressedOutput)
            disp(suppressedOutput)
            suppressedOutput = '';
        end
    end
end

