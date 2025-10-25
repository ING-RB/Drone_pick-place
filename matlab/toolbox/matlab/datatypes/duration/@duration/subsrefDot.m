function value = subsrefDot(this,s)
%

%SUBSREFDOT Subscripted reference for a duration.

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isScalarText
import matlab.internal.datatypes.throwUnrecognizedPropertyError
import matlab.internal.datatypes.tryThrowIllegalDotMethodError

if ~isstruct(s), s = substruct('.',s); end

name = s(1).subs;
switch name
case 'Format'
    value = this.fmt;
otherwise
    if ~isScalarText(name)
        error(message('MATLAB:duration:InvalidPropertyName'));
    end
    tryThrowIllegalDotMethodError(this,name,'MethodsWithNoCorrection',this.methodsWithNonDurationFirstArgument);
    throwUnrecognizedPropertyError(this,name);
end

% None of the properties can return a CSL, so a single output is sufficient. 
if ~isscalar(s)
    value = subsref(value,s(2:end));
end
