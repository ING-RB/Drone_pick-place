classdef ReadTableWithImportOptionsXML < matlab.io.internal.functions.ExecutableFunction &...
        matlab.io.internal.functions.AcceptsReadableFilename &...
        matlab.io.internal.functions.AcceptsImportOptions &...
        matlab.io.internal.functions.AcceptsDateLocale &...
        matlab.io.internal.shared.ReadTableInputs
    %

    % Copyright 2020-2024 The MathWorks, Inc.

    methods

        function [T, func] = executeImpl(func,supplied)
            checkWrongParamsWrongType(supplied)

            if any(ismissing(func.Options.VariableSelectors))
                error(message("MATLAB:io:xml:readtable:VariableSelectorMissingString"));
            end

            opts_struct = func.Options.getOptionsStruct();
            
            try
                DocumentObject = func.XMLDocumentObject;
                assert(DocumentObject.IsLoaded == true);
            catch
                DocumentObject = matlab.io.xml.internal.Document(func.Filename);
            end
            
            out = matlab.io.internal.xml.reader.readtable(DocumentObject, opts_struct);
            
            % selectedVarOpts contains only the options for the selected 
            % variables and contains them in their selection order.
            selectedVarOpts = func.Options.getVarOptsStruct(func.Options.selectedIDs);

            missingRule = string(func.Options.MissingRule);
            errorRule = string(func.Options.ImportErrorRule);
            numSelectedVars = numel(func.Options.SelectedVariableNames);
            
            omitvars = false(1, numSelectedVars);
            omitrows = false(0, 1);
            if numel(out.Data) > 0
                omitrows = false(size(out.Data{1}, 1), 1);
            end
            whitespace = sprintf(' \t\n\r');            
            for ii = 1:numel(out.Data)
                selector = func.Options.VariableSelectors(func.Options.selectedIDs(ii));
                [out.Data{ii}, row_info] = matlab.io.text.internal.convertFromText(...
                    selectedVarOpts{ii}, out.Data{ii}, whitespace);
                missingOrPlaceholders = row_info.Placeholders(:, 1);
                [omitrows, omitvars] = processRule(missingOrPlaceholders, missingRule,...
                    omitrows, omitvars, "MATLAB:io:xml:readtable:MissingRuleError", selector, ii);
                [omitrows, omitvars] = processRule(row_info.Errors, errorRule,...
                    omitrows, omitvars, "MATLAB:io:xml:readtable:ImportErrorRuleError", selector, ii);
            end
            
            % process row names
            string_opts = matlab.io.TextVariableImportOptions("Type", "string");
            readRowNames = ~ismissing(func.Options.RowNamesSelector);
            if readRowNames
                [rowNames, row_info] = matlab.io.text.internal.convertFromText(string_opts, out.RowNames, whitespace);
                missing_idx = row_info.Placeholders(:, 1) | row_info.Errors(:, 1);
                row_nums = find(missing_idx);
                rowNames(missing_idx) = compose("Row%d", row_nums);
                rowNames = matlab.lang.makeUniqueStrings(rowNames);
            else
                rowNames = {};
            end
            
            % process variable units
            if ~ismissing(func.Options.VariableUnitsSelector)
                [out.Units, ~] = matlab.io.text.internal.convertFromText(string_opts, out.Units, whitespace);
            end

            % process variable descriptions
            if ~ismissing(func.Options.VariableDescriptionsSelector)
                [out.Descriptions, ~] = matlab.io.text.internal.convertFromText(string_opts, out.Descriptions, whitespace);
            end
            
            % Depending on whether the VariableNames are modified by the
            % user or not, use the original variable names found by
            % detection or use the new names provided by the user in the
            % ImportOptions object.
            if func.Options.namesAreGenerated()
                % Should use the original variable names.
                varnames = func.Options.DetectedVariableNames(func.Options.selectedIDs);
            else
                % Names are provided by the user.
                varnames = func.Options.SelectedVariableNames;
            end

            % remove any omitted variables
            if any(omitvars)
                varnames(omitvars) = [];
                out.Data(:, omitvars) = [];
                if ~isempty(out.Units), out.Units(omitvars) = []; end
                if ~isempty(out.Descriptions), out.Descriptions(omitvars) = []; end
            end

            % remove any omitted rows
            if any(omitrows)
                if ~isempty(rowNames)
                    rowNames(omitrows) = [];
                end
                for ii = 1:numel(out.Data)
                   data = out.Data{ii};
                   data = data(~omitrows, :);
                   if ~iscell(data)
                       data = {data};
                   end
                   out.Data(ii) = data;
                end
            end
            
            %TODO: HANDLE dimension names
            dimNames = matlab.internal.tabular.private.metaDim().labels;
            readVarNames = false;

            T = matlab.io.internal.functions.ReadTable.buildTableFromData(out.Data,...
                varnames, rowNames, dimNames, readVarNames, readRowNames,...
                func.Options.PreserveVariableNames);

            T.Properties.VariableUnits = out.Units;
            
            % VariableDescriptions may have been set to the original
            % variable names, if normalization occured.
            % Avoid overriding those VariableDescriptions if
            % VariableDescriptionsSelector is unset.
            if ~ismissing(func.Options.VariableDescriptionsSelector)
                T.Properties.VariableDescriptions = out.Descriptions;
            end
        end
        
        function T = execute(func, supplied)
            T = func.executeImpl(supplied);
        end
    end
end

%%

function [omitrows, omitvars] = processRule(info, rule, omitrows, omitvars, errMessage, variableSelector, variableIndex)
    if rule == "error" && any(info, 'all')
        [rowIndex, ~] = find(info, 1);
        error(message(errMessage, rowIndex, variableSelector));
    elseif rule == "omitrow" && any(info, 'all')
        omitrows = omitrows | any(info, 2);
    elseif rule == "omitvar" && any(info, 'all')
        omitvars(variableIndex) = true;
    end
end

function checkWrongParamsWrongType(supplied)
persistent params
if isempty(params)
    getParams = @(me) string({me.PropertyList([me.PropertyList.Parameter]).Name});
    params = getParams(?matlab.io.internal.functions.ReadTableWithImportOptionsSpreadsheet);
    params = setdiff(params, [getParams(?matlab.io.internal.shared.ReadTableInputs), ...
                              getParams(?matlab.io.internal.functions.AcceptsReadableFilename)]);
    params = ["Encoding", params];
end
wrongparams = params;
if supplied.Options
    wrongparams = ["ReadVariableNames", "ReadRowNames", "DateLocale", wrongparams];
end
matlab.io.internal.utility.assertUnsupportedParamsForFileType(wrongparams,supplied,'xml')
end
