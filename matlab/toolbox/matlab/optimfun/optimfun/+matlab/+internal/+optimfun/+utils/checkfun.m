function f = checkfun(x, userfcn, caller, varargin)
    % Objective function wrapper to check for NaN/complex values
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2023 The MathWorks, Inc.

    % Call user function
    f = userfcn(x, varargin{:});

    % Check for NaN or complex. Note, we do not check for Inf as the
    % solvers handle them naturally.
    if isnan(f)
        nestedThrowError("NaN");
    elseif ~isreal(f)
        nestedThrowError("Complex");
    end

    function nestedThrowError(errorType)

        % Convert userfcn to a character vector for printing
        if ischar(userfcn)
            charfcn = userfcn;
        elseif isstring(userfcn) || isa(userfcn, "inline")
            charfcn = char(userfcn);
        elseif isa(userfcn, "function_handle")
            charfcn = func2str(userfcn);
        else
            try
                charfcn = char(userfcn);
            catch
                charfcn = getString(message("MATLAB:optimfun:commonMessages:NameNotPrintable"));
            end
        end

        % Default message catalog id and args
        id = errorType + "Fval";
        args = {charfcn, upper(caller)};

        % If the point is scalar, also pass to message catalog
        if isscalar(x)
            id = id + "AtPoint";
            args = [args(1), {sprintf("%g", x)}, args(2)];
        end

        % Error
        error("MATLAB:" + caller + ":checkfun:" + errorType + "Fval",...
            getString(message("MATLAB:optimfun:commonMessages:" + id, args{:})));
    end
end
