classdef ConvertToDataTypeAction < internal.matlab.variableeditor.VEAction
    % This class is unsupported and might change or be removed without
    % notice in a future version.

    %ConvertToDataTypeAction class Converts datatype on a specific column
    % and generates code for the conversion

    % Copyright 2018-2024 The MathWorks, Inc.
    properties (Constant)
        ActionType = 'ConvertToDataTypeAction'
    end

    methods
        function this = ConvertToDataTypeAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.ConvertToDataTypeAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.ConvertToDataType;
        end

        function ConvertToDataType(this, conversionInfo)
            try
                idx = arrayfun(@(x) isequal(x.DocID, conversionInfo.docID), this.veManager.Documents);
                doc = this.veManager.Documents(idx);
                sh = doc.ViewModel.ActionStateHandler;

                columnIndex = conversionInfo.actionInfo.selectedColumn + 1;
                conversionType = conversionInfo.actionInfo.dataType;
                conversionType = char(conversionType);
                % isFilteredProp = sh.ViewModel.getColumnModelProperty(columnIndex, 'IsFiltered');
                dataTypeOption = '';
                if isfield(conversionInfo.actionInfo, 'dataTypeOption')
                    dataTypeOption = conversionInfo.actionInfo.dataTypeOption;
                end
                
                parentIndicesMetaData = doc.ViewModel.getColumnModelProperty(columnIndex, 'ParentIndex');
                parentIndicesMetaData = parentIndicesMetaData{1};
                data = sh.DataModel.Data;
                varName = sh.Name;
                executionVarName = 'tempDM';
                conversionIndex = columnIndex;
                internalSubscript = 'sh.DataModel.Data';
                if ~isempty(parentIndicesMetaData)
                    conversionIndex = doc.ViewModel.getColumnModelProperty(columnIndex, 'ColumnIndex');
                    conversionIndex = str2double(conversionIndex{1});
                    pIndex = parentIndicesMetaData(1);
                    levels = strsplit(pIndex, '__');
                    % Get all levels in a numeric array
                    levelIdx = str2double(strsplit(levels(end), '_'));
                    levelIdx = levelIdx(~ismissing(levelIdx));

                    dotSubscript = varName;
                    executionDotSubscript = executionVarName;
                    for i=1:length(levelIdx)
                        idx = levelIdx(i);
                        tabularDotSubscript = matlab.internal.tabular.generateDotSubscripting(data, idx, '');
                        dotSubscript = [dotSubscript tabularDotSubscript];
                        executionDotSubscript = [executionDotSubscript tabularDotSubscript];
                        internalSubscript = [internalSubscript tabularDotSubscript];
                        data = data.(levelIdx(i));
                    end
                    varName = dotSubscript;
                    executionVarName = executionDotSubscript;
                else
                    [~,conversionIndex] = doc.ViewModel.getHeaderInfoFromIndex(columnIndex);
                end

                outputDocumentID = conversionInfo.docID;

                tws = [];
                filterManagerChannel = strcat('/VE/filter', outputDocumentID);
                filterManager = internal.matlab.variableeditor.peer.VEFactory.createManager(filterManagerChannel, false);
                if (filterManager.Workspaces.length > 0)
                    tws = filterManager.Workspaces('filterWorkspace');
                end

                % if the action information has revertFilters to true then
                % revert all the filtering on the output
                if isfield(conversionInfo.actionInfo, 'revertFilters') && conversionInfo.actionInfo.revertFilters
                    eventData = struct('actionInfo', conversionInfo.actionInfo, 'docID', conversionInfo.docID);
                    clearAllActionArgs = struct('EventData',eventData);
                    action = this.veManager.ActionManager.ActionDataService.getAction('ClearAllFiltersAction');
                    actionInstance = action.Action;
                    actionInstance.ClearAllFilters(eventData);
                end

                 % commandArray contains a list of all the interactive commands issued for a output
                [mCode, executionCode] = this.generateDataTypeConversionCode(varName, executionVarName, data, conversionIndex, conversionType, dataTypeOption, conversionInfo.docID);

                % disable any warnings coming from the datetime
                % constructor. It will try to warn for ambiguous formats
                % which we may not care about
                orig_state = warning('off', 'all');
                revertWarning = onCleanup(@() warning(orig_state));
                % convertedData will be assigned to the DataModel of ActionStateHandler 
                if strcmp(conversionType, 'datetime') || strcmp(conversionType, 'duration')
                    convertedData = feval(conversionType, data.(conversionIndex), 'InputFormat', dataTypeOption);
                else
                    convertedData = feval(conversionType, data.(conversionIndex));
                end
                internalExecution = [internalSubscript '.(' num2str(conversionIndex) ') = convertedData;'];
                eval(internalExecution);

                newData = sh.DataModel.Data;
                if ~isempty(tws)
                    tws.updateTableAndResetCache(newData, outputDocumentID);
                end      
                % Update metadata to reflect the conversion action
                sh.ViewModel.setColumnModelProperty(columnIndex, 'class', conversionType);            
                % Update the client with the converted view
                sh.updateClientView();
                sh.CommandArray = [sh.CommandArray, struct('Command', "ConvertTo", 'Index', columnIndex, 'commandInfo', ['docID', conversionInfo.docID],...
                    'generatedCode', {mCode}, 'executionCode', {executionCode})];
                sh.getCodegenCommands(columnIndex, "ConvertTo");
                sh.publishCode();
            catch ex
                rethrow(ex);
            end
        end

        % generates filter code and executionCode(code that runs on
        % undo-redo)
        function [filtCode, executionCode] = generateDataTypeConversionCode(~, varName, executionVarName, data, index, columnClass, dataTypeOption, docID)
            columnName = data.Properties.VariableNames{index};
            if ~isvarname(columnName)
                [~,~,columnName] = internal.matlab.datatoolsservices.FormatDataUtils.generateVariableNameAssignmentString(columnName, varName, NaN);
                columnName = "(" + columnName + ")";
            end

            % generate a cleanup command that resets the originalData of
            % the workspace. Since we reset the originalData on every
            % boundary action, we need to do the same on undo-redo.
            columnName = char(columnName);
            handleCleanupCommand = ['internal.matlab.variableeditor.Actions.ConvertToDataTypeAction.updateFilteredData(''' docID ''',tempDM);'];
            if strcmp(columnClass, 'datetime') || strcmp(columnClass, 'duration')
                filtCode = {[varName '.' columnName ' = ' columnClass '(' varName '.' columnName ',''InputFormat'',''', dataTypeOption ,''');']};
                executionCode = {[ executionVarName '.' columnName ' = ' columnClass '(' executionVarName '.' columnName ',''InputFormat'',''', dataTypeOption ,''');' handleCleanupCommand]};
            else
                filtCode = {[varName '.' columnName ' = ' columnClass '(' varName '.' columnName ');']};
                executionCode = {[executionVarName '.' columnName ' = ' columnClass '(' executionVarName '.' columnName ');' handleCleanupCommand]};
            end
        end

        function UpdateActionState(this)
            this.Enabled = true;
        end
    end
    
    methods(Static)     
        % Update the filtering workspace's originalData with the value
        % provided.
        function updateFilteredData(docID, val)
            channel = strcat('/VE/filter',docID);
            mgr = internal.matlab.variableeditor.peer.VEFactory.createManager(channel, false);
            % Get the correct workspace
            % This is a private workspace for filtering tables only.
            if mgr.Workspaces.Count > 0
                tws = mgr.Workspaces('filterWorkspace');
                if ~isempty(tws)
                    tws.resetOriginalData(val);
                end
            end
            
            mgr.delete;
        end
    end
end
