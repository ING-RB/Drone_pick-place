classdef ReadMatrixSpreadsheet < matlab.io.internal.functions.ExecutableFunction ...
        & matlab.io.internal.functions.AcceptsReadableFilename ...
        & matlab.io.internal.functions.AcceptsImportOptions ...
        & matlab.io.internal.shared.ReadTableInputs ...
        & matlab.io.internal.functions.AcceptsSheetNameOrNumber ...
        & matlab.io.internal.functions.AcceptsUseExcel
    %
    
    % Copyright 2018-2023 The MathWorks, Inc.
    methods
        function func = ReadMatrixSpreadsheet()
            func.Options = spreadsheetImportOptions();
        end
    end
    
    methods (Access = protected)
        function [rhs,obj] = setSheet(obj,rhs)
            if ~isa(obj.Options,'matlab.io.spreadsheet.SpreadsheetImportOptions')
                error(message('MATLAB:textio:detectImportOptions:ParamWrongFileType','Sheet','text'))
            end
            obj.Options.Sheet = rhs;
        end
    end
    
    methods
        function A = execute(func,supplied)
            checkWrongParamsWrongType(supplied);
            try
                sheet = func.WorkSheet.SheetObj;
                assert(~isempty(sheet));
            catch
                [S, func] = executeImplCatch(func);
                sheet = S.Sheet;
            end

            if isfield(supplied, "UseExcel") && func.UseExcel && ...
                (func.Options.MergedCellColumnRule ~= "placeleft" || ...
                func.Options.MergedCellRowRule ~= "placetop")
                error(message("MATLAB:spreadsheet:sheet:FeatureOffInUseExcelMode"));
            end

            try
                UseExcel = func.WorkSheet.IsComObject;
            catch
                UseExcel = func.UseExcel;
            end
            A = matlab.io.spreadsheet.internal.readSpreadsheetMatrix(...
                sheet,func.Options,...
                {'ReadVariableNames',func.ReadVariableNames, ...
                'ReadRowNames',func.ReadRowNames, ...
                'Sheet',func.Options.Sheet, ...
                'UseExcel',UseExcel, ...
                'MergedCellColumnRule', char(func.Options.MergedCellColumnRule), ...
                'MergedCellRowRule', char(func.Options.MergedCellRowRule)});
        end
    end
    
end
function checkWrongParamsWrongType(supplied)
persistent params
if isempty(params)
    me = {?matlab.io.internal.functions.AcceptsDateLocale, ...
        ?matlab.io.internal.shared.EncodingInput};
    params = cell(1,numel(me));
    for i = 1:numel(me)
        params{i} = string({me{i}.PropertyList([me{i}.PropertyList.Parameter]).Name});
    end
    params = ["MaxRowsRead" params{:}];
end
matlab.io.internal.utility.assertUnsupportedParamsForFileType(params,supplied,'spreadsheet');
end
