classdef CategoricalVariableImportOptions < matlab.io.VariableImportOptions ...
        & matlab.io.internal.shared.CategoricalVarOptsInputs
    %CATEGORICALIMPORTOPTIONS options for importing categorical variables.
    %   topts = matlab.io.CategoricalVariableImportOptions(...)
    %
    %   CategoricalVariableImportOptions properties:
    %               Name - The name of the variable on import
    %               Type - The data type of the variable on import
    %          FillValue - A scalar value to fill missing or unconvertible data
    %     TreatAsMissing - Text which is used in a file to represent missing
    %                      data, e.g. 'NA'
    %          QuoteRule - How to treat quoted text.
    %         Categories - List of expected categories
    %          Protected - Whether the output array is protected
    %            Ordinal - Whether the output array is ordinal
    %
    %   See also matlab.io.VariableImportOptions, categorical

    % Copyright 2016-2018 The MathWorks, Inc.

    methods
        function obj = CategoricalVariableImportOptions(varargin)
            obj.Type_ = 'categorical';
            obj.FillValue_ = '';
            [obj,otherArgs] = obj.parseInputs(varargin);
            obj.assertNoAdditionalParameters(fields(otherArgs),class(obj));
        end
    end

    methods (Access = protected)
        function [type_specific,group_name] = getTypedPropertyGroup(obj)
            group_name = 'Categorical Options:';
            type_specific.Categories = obj.Categories;
            type_specific.Protected  = obj.Protected;
            type_specific.Ordinal    = obj.Ordinal;
        end

        function tf = compareVarProps(a,b)
            tf = isequaln(a.FillValue,b.FillValue)...
                && all(strcmp(a.Categories,b.Categories))...
                && isequal(a.Protected,b.Protected)...
                && isequal(a.Ordinal,b.Ordinal);
        end
    end

    methods (Access = {?matlab.io.VariableImportOptions})
        function s = addTypeSpecificOpts(opts,s)
            persistent names
            if isempty(names)
                names = setdiff(fieldnames(opts),["Name","Type","FillValue"]);
            end
            for n = names(:)'
                s.(n{:}) = opts.(n{:});
            end

            s.FillValue = char(s.FillValue);
            if any(strcmp(s.FillValue,{'<undefined>','<missing>'}))
                s.FillValue = '';
            end
        end
    end
    
    methods(Static, Access = protected)
        function props = getTypeSpecificProperties()
            % List of properties specific to CategoricalVariableImportOptions
            % to be  set in the loadobj method of ImportOptions.
            props = ["Categories", "Protected", "Ordinal"];
        end
    end
end
