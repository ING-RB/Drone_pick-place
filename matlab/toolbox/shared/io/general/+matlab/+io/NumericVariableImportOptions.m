classdef NumericVariableImportOptions < matlab.io.VariableImportOptions ...
        & matlab.io.internal.shared.NumericVarOptsInputs

    %NUMERICVARIABLEIMPORTOPTIONS options for importing numeric variables
    %   topts = matlab.io.NumericVariableImportOptions(...)
    %
    %   NumericVariableImportOptions properties:
    %               Name - The name of the variable on import
    %               Type - The data type of the variable on import
    %          FillValue - A scalar value to fill missing or unconvertible data
    %     TreatAsMissing - Text which is used in a file to represent missing
    %                      data, e.g. 'NA'
    %          QuoteRule - How to treat quoted text.
    %  ExponentCharacter - Character which should be treated as exponents when
    %                      converting text
    %   DecimalSeparator - Character used to separate the integer part of a
    %                      number from the decimal part of the number
    % ThousandsSeparator - Character used to separate the thousands place digits
    % TrimNonNumeric     - Logical used to specify that all prefixes and
    %                      suffixes must be removed leaving only the numeric part
    %       NumberSystem - Read a number using 'decimal', 'hex' or 'binary'
    %                      as the number system. 'decimal' is the default setting.
    %
    %   See also matlab.io.VariableImportOptions

    % Copyright 2016-2019 The MathWorks, Inc.

    methods
        function obj = NumericVariableImportOptions(varargin)
            obj.Type_ = 'double';
            obj.FillValue = NaN;
            [obj,otherArgs] = obj.parseInputs(varargin);
            obj.assertNoAdditionalParameters(fields(otherArgs),class(obj));
        end
    end

    methods (Access = protected)
        function [type_specific,group_name] = getTypedPropertyGroup(obj)
            group_name = 'Numeric Options:';
            type_specific.ExponentCharacter = obj.ExponentCharacter;
            type_specific.DecimalSeparator = obj.DecimalSeparator;
            type_specific.ThousandsSeparator = obj.ThousandsSeparator;
            type_specific.TrimNonNumeric = obj.TrimNonNumeric;
            type_specific.NumberSystem = obj.NumberSystem;
        end

        function tf = compareVarProps(a,b)
            tf = isequaln(a.FillValue,b.FillValue)...
                && strcmp(a.ExponentCharacter,b.ExponentCharacter)...
                && strcmp(a.DecimalSeparator,b.DecimalSeparator)...
                && isequal(a.TrimNonNumeric,b.TrimNonNumeric);
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
        end
    end
    
    methods(Static, Access = protected)
        function props = getTypeSpecificProperties()
            % List of properties specific to NumericVariableImportOptions
            % to be  set in the loadobj method of ImportOptions.
            props = ["ExponentCharacter", "DecimalSeparator",...
                "ThousandsSeparator", "TrimNonNumeric", "NumberSystem"];
        end
    end
end
