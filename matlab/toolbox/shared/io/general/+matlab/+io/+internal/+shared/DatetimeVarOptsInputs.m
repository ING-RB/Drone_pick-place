classdef DatetimeVarOptsInputs < matlab.io.internal.FunctionInterface ...
    & matlab.io.internal.shared.InputFormatInput
    %
    
    %   Copyright 2018-2024 The MathWorks, Inc.
    properties (Parameter)
        %DATETIMEFORMAT
        %   Variables imported as datetime will have this format.
        %
        %   See also matlab.io.DatetimeVariableImportOptions

        DatetimeFormat = 'preserveinput';
        
        %DATETIMELOCALE
        %   Import uses this locale when reading the month names, day of
        %   week names, etc. When importing from text, if the names do not match
        %   the expected localized names, then the import conversion will fail.
        %
        %   See also matlab.io.DatetimeVariableImportOptions
        DatetimeLocale % system default
               
        %Time zone property for datetime arrays.
        %   The TimeZone property array specifies the time zone used to interpret the
        %   datetimes in the array. Specify the time zone as:
        %
        %      - '' to create "unzoned" datetimes that do not belong to a specific
        %        time zone.
        %      - The name of a time zone region from the IANA Time Zone Database, e.g.
        %        'America/Los_Angeles'. The array obeys the time zone offset and Daylight
        %        Saving Time rules associated with that region.
        %      - An ISO 8601 character vector of the form +HH:MM or -HH:MM.
        %      - 'UTC' to create datetimes in Universal Coordinated Time.
        %      - 'UTCLeapSeconds' to create datetimes in Universal Coordinated Time that
        %        account for leap seconds.
        %
        %   The default value for TimeZone when you create a datetime array is ''.
        %   Datetime arrays with no time zone can not be compared or combined with
        %   arrays that have their TimeZone property set to a specific time zone.
        %
        %   See also matlab.io.DatetimeVariableImportOptions
        TimeZone = '';
    end
    
    methods
        function obj = set.DatetimeFormat(obj,rhs)
            rhs = convertCharsToStrings(rhs);
            if isscalar(rhs) && any(strcmpi(rhs, ["default", "defaultdate", "preserveinput"]))
                obj.DatetimeFormat = convertStringsToChars(lower(rhs));
            else
                % rhs does not match one of the three keywords, try
                % constructing a datetime with the format specified
                try  datetime(0, 0, 0, Format=rhs); catch ME
                    throw(ME);
                end
                obj.DatetimeFormat = convertStringsToChars(rhs);
            end
        end
        
        function obj = set.DatetimeLocale(obj,rhs)
        try
            d = datetime('now');
            cellstr(d,'',rhs);
        catch ME
            if ischar(rhs)
                error(message('MATLAB:textio:io:UnknownLocale',rhs));
            else
                throw(ME)
            end
        end
        obj.DatetimeLocale = convertStringsToChars(rhs);
        end
        
        function obj = set.TimeZone(obj,rhs)
        import matlab.internal.datetime.getCanonicalTZ
        rhs = getCanonicalTZ(rhs,false);
        obj.TimeZone = convertStringsToChars(rhs);
        end
    end
    
    methods (Access = protected)
        function val = setFillValue(~,val)
        try
            val = datetime(val);
            assert(isscalar(val));
        catch
            error(message('MATLAB:textio:io:FillValueType','datetime'));
        end
        end
        
        function val = getFillValue(~,val)
        if isempty(val)
            val = NaT;
        end
        end
        
        function val = setType(obj,val)
        obj.validateFixedType(obj.Name,'datetime',val);
        end
        function val = getType(~,~)
        val = 'datetime';
        end
        function rhs = setInputFormat(~,rhs)
        try
            if ~(strlength(rhs) > 0)
                rhs = '';
            else
                datetime('now','Format',rhs);
            end
        catch ME, throw(ME),
        end
        end
    end
end

