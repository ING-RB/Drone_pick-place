classdef ReadCellWithImportOptions < matlab.io.internal.functions.ReadCellText ...
        & matlab.io.internal.functions.ReadCellSpreadsheet ...
        & matlab.io.internal.shared.GetExtensionsFromOpts
    %
    
    %   Copyright 2018-2024 The MathWorks, Inc.
    
    methods
        function [func,supplied,other] = validate(func,varargin)
            [func,varargin] = extractArg(func,"WebOptions",varargin, 2);
            [func,supplied,other] = validate@matlab.io.internal.functions.ExecutableFunction(func,varargin{:});
            matlab.io.internal.functions.parameter.assertNoRowNamesInputs(supplied);
            matlab.io.internal.functions.parameter.assertNoVariableNameInputs(supplied);
        end

        function C = execute(func, supplied)
            if isempty(func.Options.VariableNames)
                func.Options.VariableNames = {'ExtraVar1'};
                func.Options.AddedExtraVar = true;
            end

            % set everything to import char, which will create a cellstr
            func.Options = setvartype(func.Options, 'char');

            if isa(func.Options,'matlab.io.text.TextImportOptions')
                C = func.execute@matlab.io.internal.functions.ReadCellText(supplied);
            else %isa(func.Options,'matlab.io.spreadsheet.SpreadsheetImportOptions')
                C = func.execute@matlab.io.internal.functions.ReadCellSpreadsheet(supplied);
            end
        end
    end
    
end
