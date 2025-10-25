function this = subsasgnDot(this,s,rhs)
%

%SUBSASGNDOT Subscripted assignment to a datetime.

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isScalarText
import matlab.internal.datatypes.throwInstead
import matlab.internal.datatypes.throwUnrecognizedPropertyError
import matlab.internal.datetime.setDateField
import matlab.lang.internal.move

if ~isstruct(s), s = substruct('.',s); end
name = s(1).subs;
if ~isScalarText(name)
    error(message('MATLAB:datetime:InvalidPropertyName'));
end

switch name
case 'Format'
    if ~isscalar(s)
        rhs = builtin('subsasgn',getDisplayFormat(this),s(2:end),rhs);
    end

    try
        this.fmt = verifyFormat(rhs,this.tz,false,true);
    catch ME
        if (this.tz == datetime.UTCLeapSecsZoneID)
            error(message('MATLAB:datetime:InvalidUTCLeapSecsFormatString'));
        else
            rethrow(ME);
        end
    end

case 'TimeZone'
    if ~isscalar(s)
        rhs = builtin('subsasgn',this.tz,s(2:end),rhs);
    end

    % Canonicalize the TZ name. This make US/Eastern ->
    % America/New_York, but it will also make EST -> Etc/GMT-5,
    % because EST is an offset, not a time zone.
    rhs = verifyTimeZone(rhs);
    this.data = timeZoneAdjustment(this.data,this.tz,rhs);
    if (rhs == datetime.UTCLeapSecsZoneID)
        if ~matches(this.fmt,datetime.ISO8601FormatPattern)
            this.fmt = datetime.ISO8601Format; % force this required format
        end
    elseif (this.tz == datetime.UTCLeapSecsZoneID)
        this.fmt = ''; % use default setting
    end
    this.tz = rhs;

case {'Year' 'Month' 'Day' 'Hour' 'Minute' 'Second'}
    if ~isreal(rhs)
        error(message('MATLAB:datetime:InputMustBeReal'));
    end

    try
        rhs = full(double(rhs));
        dateField = datetime.dateFields.(name);
        data = this.data; this.data = []; % DO NOT separate these calls: necessary to avoid shared copy unsharing
        if isscalar(s)
            % In try/catch: use matlab.lang.internal.move to avoid creation
            % of extra shared-copy reference when passing into setDateField
            data = setDateField(move(data), rhs, dateField, this.tz);
        elseif (length(s)==2) && (s(2).type == "()")
            data(s(2).subs{:}) = setDateField(data(s(2).subs{:}), rhs, dateField, this.tz);
        else
            if s(2).type == "{}"
                error(message('MATLAB:cellAssToNonCell'))
            elseif (length(s)>2) || (s(2).type == ".")
                error(message('MATLAB:structAssToNonStruct'));
            end
        end
        this.data = data;
    catch ME
        throwInstead(ME,{'MATLAB:datetime:InputSizeMismatch','MATLAB:badsubscript'},...
            message('MATLAB:datetime:PropertyAssignmentResize',name));
    end

case 'SystemTimeZone'
    error(message('MATLAB:datetime:ReadOnlyProperty',name));

otherwise
    throwUnrecognizedPropertyError(this,name);
end
