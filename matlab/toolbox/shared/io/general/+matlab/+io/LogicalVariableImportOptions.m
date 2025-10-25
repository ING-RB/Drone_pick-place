classdef LogicalVariableImportOptions < matlab.io.VariableImportOptions...
        & matlab.io.internal.shared.LogicalVarOptsInputs
    %LOGICALVARIABLEIMPORTOPTIONS options for importing logical data.
    %   topts = matlab.io.LogicalVariableImportOptions(...)
    %
    %   LogicalVariableImportOptions properties:
    %               Name - The name of the variable on import
    %               Type - The data type of the variable on import
    %          FillValue - A scalar value to fill missing or unconvertible data
    %     TreatAsMissing - Text which is used in a file to represent missing
    %                      data, e.g. 'NA'
    %          QuoteRule - How to treat quoted text.
    %        TrueSymbols - Text to be converted to the logical value true.
    %       FalseSymbols - Text to be converted to the logical value false.
    %      CaseSensitive - Whether or not to consider case when matching
    %                      symbols
    %
    %   See also matlab.io.VariableImportOptions

    % Copyright 2016-2018 The MathWorks, Inc.

    methods
        function obj = LogicalVariableImportOptions(varargin)
            obj.Type_ = 'logical';
            obj.FillValue_ = false;
            [obj,otherArgs] = obj.parseInputs(varargin);
            obj.assertNoAdditionalParameters(fields(otherArgs),class(obj));
        end
    end

    methods (Access = protected)
        function tf = compareVarProps(a,b)
            tf = isequal(a.FillValue,b.FillValue)...
                && all(strcmp(a.TrueSymbols,b.TrueSymbols))...
                && all(strcmp(a.FalseSymbols,b.FalseSymbols))...
                && isequal(a.CaseSensitive,b.CaseSensitive);
        end
    end

    methods (Sealed, Access = protected)
        function [type_specific,group_name] = getTypedPropertyGroup(obj)
            group_name = 'Logical Options:';
            type_specific.TrueSymbols = obj.TrueSymbols;
            type_specific.FalseSymbols = obj.FalseSymbols;
            type_specific.CaseSensitive = obj.CaseSensitive;
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
            % List of properties specific to LogicalVariableImportOptions
            % to be  set in the loadobj method of ImportOptions.
            props = ["TrueSymbols", "FalseSymbols", "CaseSensitive"];
        end
    end
end
