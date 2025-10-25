classdef ReplaceEmptyAction < internal.matlab.variableeditor.VEAction ...
    & internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class handles replacing empty value data for array-like
    % datatypes.

    % Copyright 2020-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionName = 'VariableEditor.delete'
    end  
    
    methods
        function this = ReplaceEmptyAction(props, manager)            
           props.ID = internal.matlab.variableeditor.Actions.dataTypes.ReplaceEmptyAction.ActionName;           
           props.Enabled = true;
           this@internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase(manager);
           this@internal.matlab.variableeditor.VEAction(props, manager);
        end
    end
    
    methods(Access='protected')
        
        % generates command for table sort action based on whether it was a 
        % sortAscending or sortDescending action.
        function [cmd, executionCmd] = generateCommandForAction(this, focusedDoc, actionInfo)
            %% TODO: Remove
            % This is tech debt. that we are introducing to enable sorting
            % via the header menu for tables in the MOTW VE. Remove this
            % once the ADS is switched to Mf0 and the contract to send
            % information across is established.
            if isfield(actionInfo, 'actionInfo')
                menuID = actionInfo.actionInfo.menuID;
                actionInfo = struct('menuID', menuID);
            end
            focusedView = focusedDoc.ViewModel; 
            executionCmd = '';
            selection = focusedView.getSelection;            
            data = focusedView.DataModel.Data;
            slice = '';
            if isprop(focusedDoc.DataModel, 'DataI')
                data = focusedDoc.DataModel.DataI;
            end
            if ~ismatrix(data)
                slice = focusedDoc.DataModel.Slice;
            end
            
            variableName = focusedDoc.Name;
            cmd = '';
            if isstring(data)
                cmd = internal.matlab.array.StringArrayVariableEditorAdapter.variableEditorClearDataCode(...
                    data, variableName, selection{1}, selection{2});
            elseif isstruct(data)
                cmd = internal.matlab.array.StructArrayVariableEditorAdapter.variableEditorClearDataCode(...
                     data, variableName, selection{1}, selection{2});
            elseif (isnumeric(data) || islogical(data) || iscell(data))
                % If menuIDs are present, replace with specific replacement
                % values, default to 0|[] values replacements in else clause.
                if strcmp(actionInfo.menuID, 'ReplaceWithNaNNumeric')
                    cmd = internal.matlab.variableeditor.Actions.dataTypes.BaseTypesVariableEditorAdapter.variableEditorClearDataCode(...
                         data, variableName, selection{1}, selection{2}, 'NaN', slice); 
                elseif strcmp(actionInfo.menuID, 'ReplaceWithConstantNumeric')
                    this.replaceWithConstant();
                else
                    cmd = internal.matlab.variableeditor.Actions.dataTypes.BaseTypesVariableEditorAdapter.variableEditorClearDataCode(...
                         data, variableName, selection{1}, selection{2}, '0', slice);
                end
            elseif ischar(data)
                cmd = sprintf('%s = '''';', variableName);
            elseif istabular(data)
                cmd = internal.matlab.variableeditor.Actions.dataTypes.BaseTypesVariableEditorAdapter.variableEditorClearTableCode(...
                         data, variableName, selection{1}, selection{2}, focusedView.getGroupedColumnCounts);
            else
                cmd  = variableEditorClearDataCode(data, variableName, selection{1}, selection{2});
            end
        end
        
        function replaceWithConstant(this)
            DTDlgHandler = internal.matlab.datatoolsservices.DTDialogHandler.getInstance;
            msg = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:REPLACE_CONSTANT_MESSAGE'));
            title = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:REPLACE_CONSTANT_TITLE'));
            replaceButtonText = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:REPLACE_BUTTON_TXT'));
            cancelButtonText = string(getString(message('MATLAB:uistring:popupdialogs:Cancel')));
            replaceButton = struct('type', "DoIt", 'text', replaceButtonText);
            cancelButton = struct('type', "DontDoIt", 'text', cancelButtonText);
            DTDlgHandler.showInputDialog(msg, title, Source=this.ID, DialogButtons=[replaceButton, cancelButton], ...
                CallbackFcn=@this.replaceWithUserProvidedConstant, DialogType="modal");

        end

        function replaceWithUserProvidedConstant(this, dlgResponse)           
            if strcmp(dlgResponse.src, this.ID)
                if (dlgResponse.response)
                    % proceed with replacement
                    % If user hits cancel, replacementValue will be empty
                    if ~isempty(dlgResponse.value)
                        focusedDoc = this.Manager.FocusedDocument;
                        focusedView = focusedDoc.ViewModel; 
                        selection = focusedView.getSelection;
                        try
                            valueToReplace = evalin(focusedDoc.Workspace, dlgResponse.value);
                        catch e
                            focusedView.dispatchEventToClient(struct( ...
                            'type', 'actionError', ...
                            'status', 'error', ...
                            'message', e.message, ...
                            'source', 'server'));
                            return;
                        end
                        cmd = internal.matlab.variableeditor.Actions.dataTypes.BaseTypesVariableEditorAdapter.variableEditorClearDataCode(...
                            focusedView.getTabularDataSize(), focusedDoc.Name, selection{1}, selection{2}, sprintf('%d', valueToReplace), '');
                        this.publishCode(focusedDoc.DataModel.CodePublishingDataModelChannel, cmd, '');
                    end
                end
            end
        end
    end
end

