function x = wrapBoundaryInput(x)
% Make sure the boundary inputs to eraseBetween, extractBetween etc. are
% scalar strings so that they are treated as a single element for elementfun.

% Copyright 2016-2023 The MathWorks, Inc.

if ischar(x)
    % Check for column or matrix char arrays before wrapping
    if ~isempty(x) && ~isrow(x)
        throwAsCaller(iGetError());
    end
    x = string(x);
elseif isa(x, "pattern")
    % Wrap pattern objects as broadcast variables so that we don't need an
    % adaptor for them. For tall they must be scalar (in-memory allows
    % matching size too).
    matlab.bigdata.internal.util.errorIfNonscalarPattern("tall", x);
    x = matlab.bigdata.internal.broadcast(x);
end
end


function err = iGetError()
msg = message('MATLAB:string:MustBeTextNumericOrPattern', ...
    getString(message('MATLAB:string:Boundary')));
err = MException(msg);
end
