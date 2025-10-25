function this = subsasgnDot(this,s,rhs)
%

%SUBSASGNDOT Subscripted assignment to a duration.

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isScalarText
import matlab.internal.datatypes.throwUnrecognizedPropertyError

if ~isstruct(s), s = substruct('.',s); end

name = s(1).subs;
if ~isScalarText(name)
    error(message('MATLAB:duration:InvalidPropertyName'));
end

% For nested subscript, get the property and call subsasgn on it
if ~isscalar(s)
    switch name
    case 'Format'
        value = this.fmt;
    otherwise
        throwUnrecognizedPropertyError(this,name);
    end
    rhs = builtin('subsasgn',value,s(2:end),rhs);
end

% Assign the rhs to the property
switch name
case 'Format'
    this.fmt = verifyFormat(rhs);
otherwise
    throwUnrecognizedPropertyError(this,name);
end
