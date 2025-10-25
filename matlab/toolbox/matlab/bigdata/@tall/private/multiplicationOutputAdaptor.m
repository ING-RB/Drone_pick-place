function out = multiplicationOutputAdaptor(methodName, x, y)
%multiplicationOutputAdaptor calculate output adaptor for TIMES and MTIMES

% Copyright 2016-2022 The MathWorks, Inc.

% Now that we support maths on tables we need to deal with those
% recursively.
if istabular(x) || istabular(y)
    out = determineAdaptorForTabularMath( ...
        @(varargin) multiplicationOutputAdaptor(methodName, varargin{:}), methodName, x, y);
    return
end

cX = tall.getClass(x);
cY = tall.getClass(y);

% Fix for g1372184 - the only 'strong' types that supports TIMES are
% categorical, duration, and calendarDuration. The result is always the strong
% type.
typeToPropagate = intersect({'categorical', 'duration', 'calendarDuration'}, {cX, cY});
isString = strcmp({cX, cY}, 'string');
if ~isempty(typeToPropagate)
    % If we get more than 1 type to propagate, trouble will ensue later
    cZ = typeToPropagate{1};
elseif any(isString)
    % TIMES does not support string inputs when the other input is not a
    % categorical.
    throwAsCaller(MException('MATLAB:bigdata:array:UnsupportedArgumentType', ...
        message('MATLAB:bigdata:array:UnsupportedArgumentType', find(isString, 1), 'TIMES', 'string')));
else
    % Preserve type, but logical/char -> double
    cZ = calculateArithmeticOutputType(cX, cY);
end
out = matlab.bigdata.internal.adaptors.getAdaptorForType(cZ);
end
