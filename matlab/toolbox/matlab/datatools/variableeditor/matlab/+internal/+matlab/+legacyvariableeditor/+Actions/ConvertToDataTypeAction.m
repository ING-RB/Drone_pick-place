classdef ConvertToDataTypeAction < internal.matlab.legacyvariableeditor.VEAction
    % This class is unsupported and might change or be removed without
    % notice in a future version.

    %ConvertToDataTypeAction class Converts datatype on a specific column
    % and generates code for the conversion

    % Copyright 2018 The MathWorks, Inc.
    properties (Constant)
        ActionType = 'ConvertToDataTypeAction'
    end

    properties
        Manager;
    end

    methods
        function this = ConvertToDataTypeAction(props, manager)
            props.ID = internal.matlab.legacyvariableeditor.Actions.ConvertToDataTypeAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.legacyvariableeditor.VEAction(props, manager);
            this.Callback = @this.ConvertToDataType;
            this.Manager = manager;
        end

        function ConvertToDataType(this, conversionInfo)
            idx = arrayfun(@(x) isequal(x.DocID, conversionInfo.docID), this.Manager.Documents);
            doc = this.Manager.Documents(idx);
            sh = doc.ViewModel.ActionStateHandler;
         
            columnIndex = conversionInfo.actionInfo.selectedColumn + 1;
            conversionType = conversionInfo.actionInfo.dataType;
            conversionType = char(conversionType);            
            isFilteredProp = sh.ViewModel.getColumnModelProperty(columnIndex, 'IsFiltered');
            isFiltered = ~isempty(isFilteredProp{1}) && isFilteredProp{1};
            
            isNumericFilteringType = false;
            if isfield(conversionInfo.actionInfo, 'isNumericFiltering')
                isNumericFilteringType = conversionInfo.actionInfo.isNumericFiltering;
            end
            
            isTextFilteringType = false;
            if isfield(conversionInfo.actionInfo, 'isTextFiltering')
                isTextFilteringType = conversionInfo.actionInfo.isTextFiltering;
            end
            
            dataTypeOption = '';
            if isfield(conversionInfo.actionInfo, 'dataTypeOption')
                dataTypeOption = conversionInfo.actionInfo.dataTypeOption;
            end
            
            colName = sh.DataModel.Data.Properties.VariableNames{columnIndex};                      
            
            outputDocumentID = conversionInfo.docID;           
            
            filterManagerChannel = strcat('/VE/filter', outputDocumentID);
            mgrs = internal.matlab.legacyvariableeditor.peer.PeerManagerFactory.getManagerInstances; 
            tws = [];
            if ~(any(strcmp(mgrs.keys, filterManagerChannel)) == 0)                
                filterManager = internal.matlab.legacyvariableeditor.peer.PeerManagerFactory.createManager(filterManagerChannel, false);                
                if (filterManager.Workspaces.length > 0)
                    tws = filterManager.Workspaces('filterWorkspace');   
                    % If column has been filtered, reset filtering
                    % NOTE: This is usually done on the client side, but we
                    % want the filtering revert and datatype conversion to
                    % be synchronous, hence dispatch actions from the
                    % server side.
                    if (isFiltered)
                        % clear current filtering
                        filt = tws.(colName);
                        % If the current filter column is of type
                        % Numeric, then reset the filterFigure
                        if (isNumericFilteringType)                             
                            tws.setNumericRange(colName, filt.OriginalMin(1), filt.OriginalMax(1), true);
                            tws.(colName).IncludeMissing(:) = true;
                            actionInfo = struct('index', columnIndex-1);
                            eventData = struct('actionInfo', actionInfo, 'range', conversionInfo.range, 'docID', outputDocumentID);
                            editTextBoxActionArgs = struct('EventData',eventData);
                            this.Manager.ActionManager.ActionDataService.executeAction('EditTextboxAction',editTextBoxActionArgs)
                        % If the current filter column is of type Text, then dispatch SelectAll action 
                        elseif isTextFilteringType                            
                            actionInfo = struct('index', columnIndex-1, 'userAction', 'SelectAll', 'embeddedTableRange', conversionInfo.range);
                            eventData = struct('actionInfo', actionInfo, 'range', conversionInfo.range, 'docID', outputDocumentID);
                            selectAllArgs = struct('EventData',eventData);
                            this.Manager.ActionManager.ActionDataService.executeAction('EditCheckboxAction',selectAllArgs)
                        end
                    end          
                end                
            end         
                        
             % commandArray contains a list of all the interactive commands issued for a output            
            [mCode, executionCode] = this.generateDataTypeConversionCode(sh.Name, colName, conversionType, dataTypeOption, conversionInfo.docID);
            if strcmp(conversionType, 'datetime') || strcmp(conversionType, 'duration')
                sh.DataModel.Data.(colName) = feval(conversionType, sh.DataModel.Data.(colName), 'InputFormat', dataTypeOption);
            else
                sh.DataModel.Data.(colName) = feval(conversionType, sh.DataModel.Data.(colName));
            end
            newData = sh.DataModel.Data;
            if ~isempty(tws)
                tws.updateTableAndResetCache(newData, outputDocumentID); 
            end
            % Update the client with the converted view
            sh.updateClientView(conversionInfo.range);
            sh.CommandArray = [sh.CommandArray, struct('Command', "ConvertTo", 'Index', columnIndex, 'commandInfo', ['docID', conversionInfo.docID],...
                'generatedCode', {mCode}, 'executionCode', {executionCode})];
            sh.getCodegenCommands(columnIndex, "ConvertTo");
            sh.publishCode();

        end
        
        % generates filter code and executionCode(code that runs on
        % undo-redo)
        function [filtCode, executionCode] = generateDataTypeConversionCode(~, varName, columnName, columnClass, dataTypeOption, docID)
            % generate a cleanup command that resets the originalData of
            % the workspace. Since we reset the originalData on every
            % boundary action, we need to do the same on undo-redo.
            handleCleanupCommand = ['internal.matlab.legacyvariableeditor.Actions.ConvertToDataTypeAction.updateFilteredData(''' docID ''',tempDM);'];
            if strcmp(columnClass, 'datetime') || strcmp(columnClass, 'duration')
                filtCode = {[varName '.' columnName ' = ' columnClass '(' varName '.' columnName ',''InputFormat'',''', dataTypeOption ,''');']};                
                executionCode = {['tempDM.' columnName ' = ' columnClass '(' 'tempDM.' columnName ',''InputFormat'',''', dataTypeOption ,''');' handleCleanupCommand]};
            else
                filtCode = {[varName '.' columnName ' = ' columnClass '(' varName '.' columnName ');']};
                executionCode = {['tempDM.' columnName ' = ' columnClass '(' 'tempDM.' columnName ');' handleCleanupCommand]};
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
            mgr = internal.matlab.legacyvariableeditor.peer.PeerManagerFactory.createManager(channel, false);
            % Get the correct workspace
            % This is a private workspace for filtering tables only.
            tws = mgr.Workspaces('filterWorkspace');
            tws.resetOriginalData(val);
        end
    end
    
end

