classdef ReadTableWithImportOptionsSpreadsheet < matlab.io.internal.functions.ExecutableFunction &...
        matlab.io.internal.functions.AcceptsReadableFilename &...
        matlab.io.internal.functions.AcceptsImportOptions &...
        matlab.io.internal.functions.AcceptsSheetNameOrNumber &...
        matlab.io.internal.shared.ReadTableInputs &...
        matlab.io.internal.functions.AcceptsUseExcel &...
        matlab.io.internal.shared.HasOmitted

    %
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    methods
        function func = ReadTableWithImportOptionsSpreadsheet()
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
        function [T,func] = executeImpl(func,supplied)
            rowNamesID = 0; rowNamesAsVariable = 0;
            if supplied.ReadRowNames && func.ReadRowNames && ~func.usingRowNames()
                % User didn't define a rownamesColumn, but called readtable with ReadRowNames
                func.Options.RowNamesRange = 1;
                [rowNamesID,rowNamesAsVariable] = deselectRowNames(func);
            elseif supplied.ReadRowNames && ~func.ReadRowNames && func.usingRowNames()
                % User specified a RowNamesColumn, but asked readtable not to import it.
                % set the RowNames back to default
                func.Options.RowNamesRange = '';
            end
            
            checkWrongParamsWrongType(supplied);
            
            if ~supplied.ReadVariableNames ...
                    && func.Options.namesAreGenerated() ...
                    && (isnumeric(func.Options.VariableNamesRange)...
                    || func.Options.VariableNamesRange ~= "")
                func.ReadVariableNames = true;
                supplied.ReadVariableNames = true;
            end
            
            try
                sheet = func.WorkSheet.SheetObj;
                assert(~isempty(sheet));
            catch
                [S, func] = executeImplCatch(func);
                sheet = S.Sheet;
            end
            readingRowNames = rowNamesAsVariable||~isempty(func.Options.RowNamesRange);
            readingVarNames = supplied.ReadVariableNames && func.ReadVariableNames;
            
            if func.UseExcel && (func.Options.MergedCellColumnRule ~= "placeleft" || ...
                    func.Options.MergedCellRowRule ~= "placetop")
                error(message("MATLAB:spreadsheet:sheet:FeatureOffInUseExcelMode"));
            end
            try
                UseExcel = func.WorkSheet.IsComObject;
            catch
                UseExcel = func.UseExcel;
            end

            rssArgs = {'ReadVariableNames',readingVarNames, ...
                'ReadRowNames',readingRowNames, ...
                'Sheet',func.Options.Sheet, ...
                'UseExcel',UseExcel, ...
                'FixVariableNames',false, ...
                'MergedCellColumnRule', char(func.Options.MergedCellColumnRule), ...
                'MergedCellRowRule', char(func.Options.MergedCellRowRule)
                };
            
            if isfield(supplied,'TreatAsMissing') && supplied.TreatAsMissing
                rssArgs = [rssArgs,{'TreatAsMissing',func.TreatAsMissing}];
            end
            
            [data,metadata,func.Omitted] = matlab.io.spreadsheet.internal.readSpreadsheet(...
                sheet, func.Options, rssArgs);
            
            dimNames = matlab.internal.tabular.private.metaDim().labels;
            
            if rowNamesAsVariable && rowNamesID > 0
                % added the row names to the import variables, now take
                % it out.
                dimNames{1} = metadata.VariableNames{rowNamesID};
                metadata.VariableNames(rowNamesID) = [];
                data(rowNamesID) = [];
            elseif readingVarNames && readingRowNames
                % Row Names Range was distinct from varnames, look at the
                % intersecting cell
                dimNamesCell(1) = string(func.Options.RowNamesRange);
                dimNamesCell(2) = string(func.Options.VariableNamesRange);
                % get the first cell, if there's more than one cell
                dimNamesCell(contains(dimNamesCell,':')) = extractBefore(dimNamesCell(contains(dimNamesCell,':')),':');
                % take the column from RowNames, and the row from
                % VariableNames and find the intersecting cell
                dimNamesCell(1) = regexprep(dimNamesCell(1),'\d','');
                dimNamesCell(2) = regexprep(dimNamesCell(2),'\D','');
                try  % This range might be bad, or the data might not be a name
                    range = [str2double(dimNamesCell{2}), ...
                        matlab.io.spreadsheet.internal.columnNumber(dimNamesCell{1}), ...
                        1, ...
                        1];
                    d = sheet.readStrings(range);
                    assert(~isempty(d{1}));
                    dimNames{1} = d{1};
                catch
                    % Ignore failures
                end
            end
            
            T = matlab.io.internal.functions.ReadTable.buildTableFromData( ...
                data, ...
                metadata.VariableNames, ...
                metadata.RowNames, ...
                dimNames, ...
                readingVarNames, ...
                readingRowNames, ...
                func.Options.PreserveVariableNames);
            T.Properties.VariableUnits = metadata.VariableUnits;

            if ~isempty(func.Options.VariableDescriptionsRange)
                % Only set VariableDescriptions if the
                % VariableDescriptionsRange property is nonempty. Do so to
                % ensure that the original VariableNames stored in the
                % VariableDescriptions are not unnecessarily overwritten.
                T.Properties.VariableDescriptions = metadata.VariableDescriptions;
            end
        end
        
        function T = execute(func,supplied)
            T = func.executeImpl(supplied);
        end
    end
    
    
    methods (Access=private)

        function [rowNamesID,rowNamesAsVariable] = deselectRowNames(func)
            dataRng = func.Options.DataRange;
            rnRng = func.Options.RowNamesRange;
            
            if ischar(dataRng)
                [~,d] = matlab.io.spreadsheet.internal.validateRange(dataRng);
                dataRngID = d(2);
            else
                dataRngID = dataRng;
            end
            
            if ischar(rnRng) && ~isempty(rnRng)
                % the first letter of the RowNamesRange
                [~,d] = matlab.io.spreadsheet.internal.validateRange(rnRng);
                rowNamesID = 1 + dataRngID - d(2);
            elseif isnumeric(rnRng)
                rowNamesID = rnRng;
            else
                rowNamesID = 0;
            end
            [rowNamesAsVariable,rowNamesID] = deselectSelectedRownames(func,rowNamesID);
        end
        
        function [rowNamesAsVariable,rowNamesID] = deselectSelectedRownames(func, rowNamesID)
            rowNamesAsVariable = ~(func.ReadRowNames && rowNamesID > 0 && ~ismember(func.Options.VariableNames(rowNamesID),func.Options.SelectedVariableNames));
            if ~rowNamesAsVariable
                func.Options.SelectedVariableNames = [func.Options.VariableNames(rowNamesID),func.Options.SelectedVariableNames];
                rowNamesID = 1;
            end
        end
        
        function tf = usingRowNames(func)
            if isnumeric(func.Options.RowNamesRange)
                tf = (func.Options.RowNamesRange > 0);
            else
                tf = ~strcmp('',func.Options.RowNamesRange);
            end
        end
        
    end

end

function checkWrongParamsWrongType(supplied)
persistent params
if isempty(params)
    getParams = @(me) string({me.PropertyList([me.PropertyList.Parameter]).Name});
    params = getParams(?matlab.io.internal.functions.ReadTableWithImportOptionsText);
    params = setdiff(params, [getParams(?matlab.io.internal.shared.ReadTableInputs), ...
                              getParams(?matlab.io.internal.functions.AcceptsReadableFilename)]);
end
matlab.io.internal.utility.assertUnsupportedParamsForFileType(params,supplied,'spreadsheet');
end
