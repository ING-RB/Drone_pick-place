classdef TextVariableImportOptions < matlab.io.VariableImportOptions ...
        & matlab.io.internal.shared.TextVarOptsInputs
    %TEXTVARIABLEIMPORTOPTIONS options for importing text variables
    %   topts = matlab.io.TextVariableImportOptions(...)
    %
    %   TextVariableImportOptions properties:
    %               Name - The name of the variable on import
    %               Type - The data type of the variable on import
    %          FillValue - A scalar value to fill missing or unconvertible data
    %     TreatAsMissing - Text which is used in a file to represent missing
    %                      data, e.g. 'NA'
    %          QuoteRule - How to treat quoted text
    %     WhitespaceRule - How to treat whitespace surrounding text
    %
    %   See also matlab.io.VariableImportOptions

    % Copyright 2016-2018 The MathWorks, Inc.

    methods
        function obj = TextVariableImportOptions(varargin)
            obj.Type_ = 'char';
            obj.FillValue_ = [];
            %TextVariableImportOptions options for importing text variables.
            [obj,otherArgs] = obj.parseInputs(varargin);
            obj.assertNoAdditionalParameters(fields(otherArgs),class(obj));
        end
    end
    
    methods (Hidden)
        function optStruct = getOptsStruct(obj)
            optStruct = makeOptsStruct(obj);
        end
    end

    methods (Access = protected)
        function [type_specific,group_name] = getTypedPropertyGroup(obj)
            group_name = 'String Options:';
            type_specific.WhitespaceRule = obj.WhitespaceRule;
        end

        function tf = compareVarProps(a,b)
            tf = isequaln(a.FillValue,b.FillValue)...
                && strcmp(a.WhitespaceRule,b.WhitespaceRule);
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
            if s.Type=="string"
                c = s.FillValue;
                if ismissing(c)
                    s.FillValue = string(missing);
                else
                    s.FillValue = char(c);
                end
            end
        end
    end
    
    methods(Static, Access = protected)
        function props = getTypeSpecificProperties()
            % List of properties specific to TextVariableImportOptions
            % to be  set in the loadobj method of ImportOptions.
            props = "WhitespaceRule";
        end
    end
end
