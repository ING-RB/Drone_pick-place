function x = wrapPositionInput(x, argIdx)
% Make sure the position inputs to insertBefore, extractAfter etc. are
% scalar strings so that they are treated as a single element for elementfun.

% Copyright 2016-2023 The MathWorks, Inc.

if ischar(x)
    % Check for column or matrix char arrays before wrapping
    if ~isempty(x) && ~isrow(x)
        if argIdx == 2
            % x is position
            msg = message('MATLAB:string:MustBeTextNumericOrPattern', ...
                getString(message('MATLAB:string:Position_UpperCase')));
        else
            % argIdx == 3, x is insert value
            msg = message('MATLAB:string:InvalidInsertValue');
        end
        throwAsCaller(MException(msg));
    end
    x = string(x);
elseif isa(x, "pattern")
    % Wrap pattern objects as broadcast variables so that we don't need an
    % adaptor for them. They must be height 1.
    if isempty(x) || size(x,1)>1
        msg = message('MATLAB:string:InvalidArgumentSize', ...
            getString(message('MATLAB:string:Position_UpperCase')));
        throwAsCaller(MException(msg));
    end
    x = matlab.bigdata.internal.broadcast(x);
end
end
