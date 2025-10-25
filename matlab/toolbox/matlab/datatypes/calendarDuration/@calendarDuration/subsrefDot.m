function value = subsrefDot(this,s)
%

%SUBSREFDOT Subscripted reference for a calendarDuration.

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isCharString
import matlab.internal.datatypes.throwUnrecognizedPropertyError
import matlab.internal.datatypes.tryThrowIllegalDotMethodError

if ~isstruct(s), s = substruct('.',s); end

name = convertStringsToChars(s(1).subs);
if ~isCharString(name)
    error(message('MATLAB:calendarDuration:InvalidPropertyName'));
end

switch name
case 'Format'
    value = this.fmt;
otherwise
    tryThrowIllegalDotMethodError(this,name,'MethodsWithNoCorrection',"cat");
    throwUnrecognizedPropertyError(this,name);
end

% None of the properties can return a CSL, so a single output is sufficient.
if ~isscalar(s)
    value = subsref(value,s(2:end));
end
