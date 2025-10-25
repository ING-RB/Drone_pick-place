classdef DurationVariableImportOptions < matlab.io.VariableImportOptions ...
        & matlab.io.internal.shared.DurationVarOptsInputs
    %DURATIONVARIABLEIMPORTOPTIONS options for importing duration variables
    %   topts = matlab.io.DurationVariableImportOptions(...)
    %
    %   DurationVariableImportOptions properties:
    %               Name - The name of the variable on import
    %               Type - The data type of the variable on import
    %          FillValue - A scalar value to fill missing or unconvertible data
    %     TreatAsMissing - Text which is used in a file to represent missing
    %                      data, e.g. 'NA'
    %          QuoteRule - How to treat quoted text.
    %     DurationFormat - Output format of the duration array.
    %        InputFormat - The format to use when importing text as times.
    %
    %   See also matlab.io.VariableImportOptions, duration

    % Copyright 2017-2018 The MathWorks, Inc.

    methods
        function obj = DurationVariableImportOptions(varargin)
            obj.Type_ = 'duration';
            obj.FillValue_ = seconds(NaN);
            [obj,otherArgs] = obj.parseInputs(varargin);
            obj.assertNoAdditionalParameters(fields(otherArgs),class(obj));
        end
    end

    methods (Access = protected)
        function [type_specific,group_name] = getTypedPropertyGroup(obj)
            group_name = 'Duration Options:';
            type_specific.DurationFormat   = obj.DurationFormat;
            type_specific.InputFormat      = obj.InputFormat;
            type_specific.DecimalSeparator = obj.DecimalSeparator;
            type_specific.FieldSeparator   = obj.FieldSeparator;
        end

        function tf = compareVarProps(a,b)
            tf = isequaln(a.FillValue,b.FillValue)...
                && strcmp(a.DurationFormat,b.DurationFormat)...
                && strcmp(a.InputFormat,b.InputFormat)...
                && strcmp(a.DecimalSeparator,b.DecimalSeparator)...
                && strcmp(a.FieldSeparator,b.FieldSeparator);
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
            s.FillValue = milliseconds(s.FillValue);
        end
    end
    
    methods(Static, Access = protected)
        function props = getTypeSpecificProperties()
            % List of properties specific to DurationVariableImportOptions
            % to be  set in the loadobj method of ImportOptions.
            props = ["DurationFormat", "InputFormat",...
                "DecimalSeparator", "FieldSeparator"];
        end
    end
end
