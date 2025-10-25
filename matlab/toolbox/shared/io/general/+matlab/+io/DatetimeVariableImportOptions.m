classdef DatetimeVariableImportOptions < matlab.io.VariableImportOptions ...
        & matlab.io.internal.shared.DatetimeVarOptsInputs
    %DATETIMEVARIABLEIMPORTOPTIONS options for importing datetime variables
    %   topts = matlab.io.DatetimeVariableImportOptions(...)
    %
    %   DatetimeVariableImportOptions properties:
    %               Name - The name of the variable on import
    %               Type - The data type of the variable on import
    %          FillValue - A scalar value to fill missing or unconvertible data
    %     TreatAsMissing - Text which is used in a file to represent missing
    %                      data, e.g. 'NA'
    %          QuoteRule - How to treat quoted text.
    %     DatetimeFormat - Output format of the datetime array.
    %        InputFormat - The format to use when importing text as dates
    %     DatetimeLocale - The locale to be used when importing text as dates
    %           TimeZone - The time zone in which the datetime values are
    %                      interpreted.
    %
    %   See also matlab.io.VariableImportOptions, datetime

    % Copyright 2016-2018 The MathWorks, Inc.

    methods
        function obj = DatetimeVariableImportOptions(varargin)
            obj.Type_ = 'datetime';
            obj.FillValue_ = NaT;
            obj.DatetimeLocale = matlab.internal.datetime.getDefaults('locale');
            [obj,otherArgs] = obj.parseInputs(varargin);
            obj.assertNoAdditionalParameters(fields(otherArgs),class(obj));
        end
    end

    methods (Access = protected)
        function [type_specific,group_name] = getTypedPropertyGroup(obj)
            group_name = 'Datetime Options:';
            type_specific.DatetimeFormat = obj.DatetimeFormat;
            type_specific.DatetimeLocale = obj.DatetimeLocale;
            type_specific.InputFormat    = obj.InputFormat;
            type_specific.TimeZone       = obj.TimeZone;
        end

        function tf = compareVarProps(a,b)
            tf = isequaln(a.FillValue,b.FillValue)...
                && strcmp(a.DatetimeFormat,b.DatetimeFormat)...
                && strcmp(a.DatetimeLocale,b.DatetimeLocale)...
                && strcmp(a.InputFormat,b.InputFormat)...
                && strcmp(a.TimeZone,b.TimeZone);
        end
    end

    methods (Access = {?matlab.io.VariableImportOptions})
        function s = addTypeSpecificOpts(opts,s)
            persistent names
            if isempty(names)
                names = setdiff(fieldnames(opts),matlab.io.VariableImportOptions.ProtectedNames);
            end
            for n = names(:)'
                s.(n{:}) = opts.(n{:});
            end
            s.FillValue = datetime.toMillis(s.FillValue);
            s.FillValue(2) = imag(s.FillValue);
            s.FillValue(1) = real(s.FillValue(1));
        end
    end
    
    methods(Static, Access = protected)
        function props = getTypeSpecificProperties()
            % List of properties specific to DatetimeVariableImportOptions
            % to be  set in the loadobj method of ImportOptions.
            props = ["DatetimeFormat", "DatetimeLocale",...
                "InputFormat", "TimeZone"];
        end
    end
end
