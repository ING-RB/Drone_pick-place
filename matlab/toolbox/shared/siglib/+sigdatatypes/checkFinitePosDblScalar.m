function checkFinitePosDblScalar(h, prop, value)
%CHECKFINITEPOSDBLSCALAR Check if value is a finite positive double scalar
%   If H is a class handle, then a message that includes property name PROP and
%   class name of H is issued.  If H is a string, then a message that assumes
%   PROP is an input argument to a function or method is issued.

%   Copyright 2019 The MathWorks, Inc.
%#codegen

if ~isscalar(value) || ~isa(value, 'double') || isinf(value) || ...
        isnan(value) || (value <= 0) || ~isreal(value)
    if ischar(h)
        msg = sprintf(['The %s input argument of %s must be a finite '...
            'positive scalar double.'], prop, h);
    else
        msg = sprintf(['The ''%s'' property of ''%s'' must be a finite '...
            'positive scalar double.'], prop, class(h));
    end
    throwAsCaller(MException('MATLAB:datatypes:NotFinitePosDblScalar', msg));
end
%---------------------------------------------------------------------------
% [EOF]