function tX = validateFalse(tX, condition, err)
%validateFalse Possibly deferred check for condition=false
%   TX = validateFalse(TX,CONDITION,ERR)
%   validates that CONDITION is false, capturing the deferred calculation in
%   tX so that an error is thrown if tX is gathered.
%   
%   CONDITION must be a tall or in-memory logical scalar.
%   ERR can be:
%     * A fully constructed error nessage, e.g. message(ERRID,ARG1,...)
%     * An error ID string "ERRID"
%     * A cell array of arguments to pass to message {"ERRID", ARG1, ...}
%     * A nullary function that will throw on call
%
%   Examples:
%   >> tX = tall((10:-1:1)');
%   >> tX = tall.validateFalse(tX, issorted(tX), "bigdata:array:XIsSorted")
%
%   See also: tall/validateTrue.

% Copyright 2018 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
frameMarker = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

narginchk(3, 3);
fcn = matlab.bigdata.internal.util.getErrorFunction(err);

if istall(condition)
    % Use elementfun to defer the check
    inAdap = tX.Adaptor;
    tX = elementfun( @(x,ok) iCheckAndThrow(x, ok, fcn), tX, condition );
    tX.Adaptor = inAdap;
else
    % Call the function immediately
    tX = iCheckAndThrow(tX, condition, fcn);
end

end

function x = iCheckAndThrow(x, ok, errFcn)
% Helper to throw a collective error if data not ok
if ok
    errFcn();
end
end