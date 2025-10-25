function value = subsrefDot(this,s)
%

%SUBSREFDOT Subscripted reference for a datetime.

% Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datetime.getDateFields
import matlab.internal.datatypes.isScalarText
import matlab.internal.datatypes.throwUnrecognizedPropertyError
import matlab.internal.datatypes.tryThrowIllegalDotMethodError

if ~isstruct(s), s = substruct('type','.','subs',s); end
name = s(1).subs;

if ~isScalarText(name)
    error(message('MATLAB:datetime:InvalidPropertyName'));
end

switch name
    case 'Format'
        value = getDisplayFormat(this);
    case 'TimeZone'
        value = this.tz;
    case {'Year' 'Month' 'Day' 'Hour' 'Minute' 'Second'}
        if isscalar(s)
            this_data = this.data;
        else
            this_data = subsref(this.data,s(2:end));
        end
        dateField = datetime.dateFields.(name);
        value = getDateFields(this_data,dateField,this.tz);
        return
    case 'SystemTimeZone'
        value = datetime.getsetLocalTimeZone('uncanonical');
    otherwise
        tryThrowIllegalDotMethodError(this,name,'MethodsWithNoCorrection',this.methodsWithNonDatetimeFirstArgument);
        throwUnrecognizedPropertyError(this,name);
end

% None of the properties can return a CSL, so a single output is sufficient. 
if ~isscalar(s)
    value = subsref(value,s(2:end));
end
