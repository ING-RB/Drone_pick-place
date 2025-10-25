classdef DataTypeConversionAction < internal.matlab.variableeditor.VEAction ...
    & internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase    
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class handles datatype conversion on table columns by publishing
    % code.

    % Copyright 2020-2023 The MathWorks, Inc.  
    
    properties (Constant)
        ActionName = 'DataTypeConversionAction';
    end
    
    methods
        function this = DataTypeConversionAction(props, manager)            
            props.ID = internal.matlab.variableeditor.Actions.table.DataTypeConversionAction.ActionName;           
            props.Enabled = true;            
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this@internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase(manager);
        end
        
        function UpdateActionState(~)          
        end
    end
    
    methods(Access='protected')       
        % This method generates cmd to convert datatype for the selected
        % column based on the conversionType. For datetime/duration,
        % dataTypeOption is used to generate the InputFormat attribute.        
        function [cmd, executionCmd] = generateCommandForAction(this, focusedDoc, conversionInfo)
            columnIndex = conversionInfo.actionInfo.selectedColumn + 1;
            executionCmd = '';
            conversionType = conversionInfo.actionInfo.dataType;
            conversionType = char(conversionType);
            if isfield(conversionInfo.actionInfo, 'revertFilters') && conversionInfo.actionInfo.revertFilters
                eventData = struct('actionInfo', conversionInfo.actionInfo, 'docID', conversionInfo.docID);
                action = this.Manager.ActionManager.ActionDataService.getAction('ClearAllFiltersAction');
                actionInstance = action.Action;
                actionInstance.ClearAllFilters(eventData);
            end
            varName = focusedDoc.Name;
            colName = focusedDoc.ViewModel.getHeaderInfoFromIndex(columnIndex);
            if ~isvarname(colName)
                [~,~,colName] = internal.matlab.datatoolsservices.FormatDataUtils.generateVariableNameAssignmentString(colName, varName, NaN);
                colName = ['(' char(colName) ')'];
            end
            if strcmp(conversionType, 'datetime') || strcmp(conversionType, 'duration')
                dataTypeOption = conversionInfo.actionInfo.dataTypeOption;
                cmd = {[varName '.' colName ' = ' conversionType '(' varName '.' colName ',''InputFormat'',''', dataTypeOption ,''');']};                    
            else
                cmd = {[varName '.' colName ' = ' conversionType '(' varName '.' colName ');']};                    
            end
        end       
    end
end


