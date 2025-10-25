function checkIsA(h, prop, value, type)
%CHECKISA Check if value is of expected type
%   If H is a class handle, then a message that includes property name PROP and
%   class name of H is issued.  If H is a string, then a message that assumes
%   PROP is an input argument to a function or method is issued.

%   Copyright 2008 The MathWorks, Inc.

if ~isempty(value) && ~isa(value, type)
    if ischar(h)
        msg = sprintf('The %s input argument of %s must be of type ''%s''.', ...
            prop, h, type);
    else
        msg = sprintf('The ''%s'' property of ''%s'' must be of type ''%s''.',...
            prop, class(h), type);
    end
    throwAsCaller(MException('MATLAB:datatypes:TypeMismatch', msg));
end
%---------------------------------------------------------------------------
% [EOF]