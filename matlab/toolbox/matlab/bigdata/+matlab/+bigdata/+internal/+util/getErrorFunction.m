function fcn = getErrorFunction(err, default)
%getErrorFunction Convert an error argument input to a throwing function.
% 
%   FCN = getErrorFunction(ERR) interprets the error input ERR and returns
%   a nullary function that will throw the relevant error when called. This
%   is used by various tall.validateXXX helpers.
%   
%   FCN = getErrorFunction(ERR,DEFAULT) provides a default for when ERR is
%   empty.
%
%   ERR can be:
%     * A fully constructed error nessage, e.g. message(ERRID,ARG1,...)
%     * An error ID string, e.g. "ERRID"
%     * A cell array of arguments to pass to message {"ERRID",ARG1,...}
%     * A function that will throw on call. Different validators may call
%       with different input arguments that are context dependent.

% Copyright 2018 The MathWorks, Inc.

if nargin >= 2 && isempty(err)
    err = default;
end

if matlab.internal.datatypes.isScalarText(err)
    fcn = @(varargin) error(message(err));

elseif iscell(err)
    % Make sure that none of the inputs are tall
    assert(~any(cellfun(@istall, err)), ...
        'Error specifiers must not contain tall arrays.');
    fcn = @(varargin) error(message(err{:}));

elseif isa(err, "message")
    fcn = @(varargin) error(err);

else
    assert(isa(err, "function_handle"), ...
        "ERR must be a message, string, cell, or function handle.")
    fcn = err;
end

end
