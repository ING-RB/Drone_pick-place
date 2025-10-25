classdef DataTypesActionBase < handle
    % This class is unsupported and might change or be removed without notice in
    % a future version.
    
    % This abstract class handles actions for all array like datatypes. On
    % Actioncallback, the generated command is published on the codepublish
    % service.
    
    % Copyright 2020-2025 The MathWorks, Inc.

    properties (Access = 'protected', WeakHandle)
        Manager internal.matlab.variableeditor.MLManager;
    end

    properties
        SupportedInInfintieGrid = false;
    end
    
    properties(Constant, Hidden=true)
        DefaultObjDataTypes = ["table", "timetable", "datetime", "duration", ...
            "calendarDuration", "string", "categorical", "ordinal", "nominal"];
    end
    
    methods
        function this = DataTypesActionBase(manager)
            this.Manager = manager;
            this.Callback = @this.handleDataTypesActionCallback;
        end
        
        function UpdateActionState(this)
            focusedDoc = this.Manager.FocusedDocument;
            % Check for ArrayView in order to update Enabled based on
            % selection. When view is unsupported and focusedDoc update
            % forces an UpdateActionState, we shortcircuit.
            if ~isempty(focusedDoc)
                if isa(focusedDoc.ViewModel, 'internal.matlab.variableeditor.ArrayViewModel')
                    focusedView = focusedDoc.ViewModel;   
                    selection = focusedView.getSelection;  
                    sz = focusedView.getTabularDataSize();
                    [rowRange, colRange] = this.getNumericSelectionRange(selection, sz);                
                    % If the rows and/or columns selected are fully outside the range of the data
                    % we will get back empty rows and/or columns.  If we support infinite grids
                    % then this action should be enabled, otherwise it won't be.
                    emptyRange = isempty(rowRange) || isempty(colRange);

                    hasUnclippedSelection = (~isempty(focusedView.UnclippedSelectedRows) ...
                            || ~isempty(focusedView.UnclippedSelectedColumns)) && emptyRange;

                    if (hasUnclippedSelection)
                        isEnabled = this.SupportedInInfintieGrid;
                    else
                        isEnabled = true;
                    end
                    this.toggleEnabledState(isEnabled);
                elseif isa(focusedDoc.ViewModel, 'internal.matlab.variableeditor.MLUnsupportedViewModel')
                    this.toggleEnabledState(false);
                end
            end
        end
        
        % API to toggle the enabled state. Sub-actions can use this as
        % baseline to add any overriding behavior.
        function toggleEnabledState(this, isEnabled)   
            this.Enabled = isEnabled;
        end
        
        function isObjArray = isObjectArray(~, data)
            isObjArray =  ~ismember(class(data), ...
                internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase.DefaultObjDataTypes);
        end
        
        function delete(this)
            if ~isempty(this.Manager)
                this.Manager = [];
            end
        end
    end
    
    methods(Access='protected')
        % This class handles action callback for all table actions. generateCommandForAction
        % only when view is of type tableViewModel.
        % actionInfo: struct(menuID: <>)
        function handleDataTypesActionCallback(this, actionInfo)
            internal.matlab.datatoolsservices.logDebug("variableeditor::DataTypesActionBase", "handleDataTypesActionCallback: " + class(this));
            focusedDoc = this.Manager.FocusedDocument;
            if isa(focusedDoc.ViewModel, 'internal.matlab.variableeditor.ArrayViewModel')
                [cmd, postExecutionCode] = this.generateCommandForAction(focusedDoc, actionInfo);
                internal.matlab.datatoolsservices.logDebug("variableeditor::DataTypesActionBase", "handleDataTypesActionCallback cmd:[" + cmd + "]  postExecutionCode:[" + postExecutionCode +"]");
                if ~isempty(cmd)
                    % Pass along codepublishingChannel that exists in
                    % DataModel. This is manager channel + doc.DocID.
                    this.publishCode(focusedDoc.DataModel.CodePublishingDataModelChannel, cmd, postExecutionCode, actionInfo);
                end
            end
        end
        
        % Publishes code by accpepting channelSuffix and code to be
        % executed. postExecutionCode is also piped in to be executed once
        % cmd is executed successfully.
        function publishCode(this, codePublishingChannel, cmd, postExecutionCode, actionInfo)
            arguments
                this
                codePublishingChannel
                cmd
                postExecutionCode
                actionInfo = struct
            end
            import internal.matlab.variableeditor.Actions.ActionUtils;
            ActionUtils.publishCode(codePublishingChannel, cmd, postExecutionCode);
            
            % Publish to any MATLAB listeners on the View
            eventdata = internal.matlab.variableeditor.VariableInteractionEventData;
            eventdata.UserAction = '';
            eventdata.Index = this.getColIndex(actionInfo);
            if ~iscell(cmd)
                cmd = {cmd};
            end
            eventdata.Code = cmd;
            this.notifyUserInteraction(eventdata);
        end

        function idx = getColIndex(this, actionInfo)
            idx = '';
        end

        function notifyUserInteraction(this, eventdata)
            focusedDoc = this.Manager.FocusedDocument;
            focusedDoc.ViewModel.notify('UserDataInteraction', eventdata);

            % Broadcast workspaceUpdated because the workspace is a private
            % workspace that doesn't notify of data changed events so we
            % need to manually trigger it.
            % g2885514
            ws = focusedDoc.ViewModel.DataModel.Workspace;
            if (~ischar(ws) && ~isstring(ws) &&...
                ~isa(ws, 'matlab.internal.datatoolsservices.AppWorkspace') && ...
                ~isa(ws, 'internal.matlab.variableeditor.MLWorkspace'))
                focusedDoc.ViewModel.DataModel.workspaceUpdated;
            end
        end
        
        % Takes in table.Properties.VariableNames and a
        % columnSelectionRange for Eg: [[2,3],[6,8]] returns varNames
        % ={'Var2','Var3','Var6','Var7','Var8'} and concatenatedNames = '{'Var2', 'Var3', 'Var6', 'Var7', 'Var8'}'
        function [varNames, concatenatedNames] = getSelectedColumnVariableNames(~, variableNames, colSelection)
            varNames = {};
            for col = colSelection.'
                varNames = [varNames, variableNames(unique(col(1): col(2)))];
            end
            concatenatedNames = ['''' strjoin(varNames, "', '") ''''];
            if length(varNames) > 1
                concatenatedNames = ['{' concatenatedNames '}'];
            end
        end
        
        % Returns numeric selection Range for indexing into table
        % for E.g {[1,2]},{[2,3]} will return rowRange as '1:2' colRange as
        % '2:3'
        function [rowRange, colRange] = getNumericSelectionRange(~, selection, sz)
            [rowRange, colRange] = internal.matlab.variableeditor.BlockSelectionModel.getSelectionRange(selection, sz);
        end
    end
    
    % Abstract API that all table actions must implement.
    methods(Access='protected', Abstract=true)
        [cmd, postExecutionCode] = generateCommandForAction(this, focusedDoc, actionInfo);
    end
end

