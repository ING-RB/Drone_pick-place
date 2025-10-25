classdef VEInteractionHandler < internal.matlab.variableeditor.peer.plugins.PluginBase

    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % Copyright 2021-2025 The MathWorks, Inc.

    properties(Transient)
        UserDataInteractionListener;
        DataEditListener;
        DataChangeListener;
    end

    properties
        IgnoreUpdate = false;
    end
    
    methods
        function this=VEInteractionHandler(viewModel)
            this@internal.matlab.variableeditor.peer.plugins.PluginBase(viewModel);
            this.setupInteractionListeners();
        end
    end
    
    methods
        function setupInteractionListeners(this)
            % Add UserDataInteraction listener (Sort, Transpose, Delete, etc.)
            if ismember('UserDataInteraction', events(this.ViewModel))
                this.UserDataInteractionListener = addlistener(this.ViewModel, 'UserDataInteraction', @(es,ed) this.handleUserDataInteraction(ed));
            end
            % Add DataEdit listener
            if ismember('DataEditFromClient', events(this.ViewModel))
                this.DataEditListener = addlistener(this.ViewModel, 'DataEditFromClient', @(es,ed) this.handleDataEdit(ed));
            end
            % Add a DataChange cistener to react to any external changes to
            % the variable
            if ismember('DataChange', events(this.ViewModel))
                this.DataChangeListener = addlistener(this.ViewModel, 'DataChange', @(es,ed)this.handleDataChange(ed));
            end
        end

        function handleUserDataInteraction(this, eventData)
            sh = this.ViewModel.ActionStateHandler;
            mCode = eventData.Code;
            if ~iscell(mCode)
                mCode = {mCode};               
            end
            try
                type = 'ToolstripAction';
                if contains(mCode{:}, "sort")
                    type = "Sort";
                end
                commandInfo = type;
                sh.CommandArray = [sh.CommandArray, struct('Command', type, 'Index', eventData.Index, ...
                    'commandInfo', commandInfo, 'generatedCode', {mCode}, 'executionCode', {mCode})];
            catch e
            end
            % Use the IgnoreUpdate Flag to avoid double updates for edit.
            this.IgnoreUpdate = true;
        end

        function handleDataEdit(this, eventData)
            sh = this.ViewModel.ActionStateHandler;
             mCode = eventData.Code;
            if ~iscell(mCode)
                mCode = {mCode};
            end
            try
                sh.CommandArray = [sh.CommandArray, struct('Command', eventData.UserAction, 'Index', eventData.Position.Column, ...
                    'commandInfo', eventData.UserAction, 'generatedCode', {mCode}, 'executionCode', {mCode})];
            catch e
                disp(e);
            end
            % Use the IgnoreUpdate Flag to avoid double updates for edit.
            this.IgnoreUpdate = true;
        end

        % This method is called when the workspace variable is changed via
        % some external action. In this case, the ActionStateHandler needs
        % to be updated and the Undo stack needs to be reset.
        function handleDataChange(this, eventData)
            internal.matlab.datatoolsservices.logDebug("variableeditor::VEInteractionHandler", "handleDataChange: ");
            sh = this.ViewModel.ActionStateHandler;
            if strcmp(eventData.EventSource, 'InternalDmUpdate')
                % This was a result of class update from MLTableDataModel.
                % This is usually followed by DataModel update, do not
                % reset IgnoreUpdate flag or CommandArray
                internal.matlab.datatoolsservices.logDebug("variableeditor::VEInteractionHandler", "handleDataChange internal DM update");
                return;
            end
            if ~this.IgnoreUpdate
                internal.matlab.datatoolsservices.logDebug("variableeditor::VEInteractionHandler", "handleDataChange processing update");
                newVariable = eventData.Source.DataModel.Data;
                if isprop(eventData.Source.DataModel, 'DataI')
                    newVariable = eventData.Source.DataModel.DataI;
                end

                if sh.IsUserInteraction || sh.isUndoRedoAction
                    internal.matlab.datatoolsservices.logDebug("variableeditor::VEInteractionHandler", "handleDataChange user interaction or undo/redo action");
                    sh.IsUserInteraction = false;

                    this.IgnoreUpdate = true;

                    % Check is variable is timetable to prevent and adjust
                    % data if needed.
                    isTimeTable = strcmp(eventData.Source.DataModel.getClassType, 'timetable');
                    events = [];
                    if (isTimeTable)
                         ttData = eventData.Source.DataModel.getCloneData;
                         if (isprop(ttData, 'Events') && ~isempty(ttData.Properties.Events))
                            events = ttData.Properties.Events;
                         end
                         newVariable = table2timetable(newVariable);
                         if ~isempty(events)
                            newVariable.Properties.Events = events;
                         end
                    end
                    % Update the Workspace with the mutated data after n-1
                    % user actions have been executed after an Undo / Redo
                    ws = this.ViewModel.DataModel.Workspace;    
                    internal.matlab.variableeditor.peer.plugins.VEInteractionHandler.getSetDataValue(newVariable);
                    evalStr = sprintf('%s = internal.matlab.variableeditor.peer.plugins.VEInteractionHandler.getSetDataValue();', sh.Name);
                    % Force the dataChange update after evalin
                    this.ViewModel.DataModel.ForceUpdate = true;
                    evalin(ws, evalStr);
                    internal.matlab.datatoolsservices.logDebug("variableeditor::VEInteractionHandler", "handleDataChange evaluating: " + evalStr);
                    % RowMetaData is changing on dataset, emit RowMetaDataChanged event on the DataModel
                    if ~isempty(events)
                        this.ViewModel.DataModel.handleRowMetaDataUpdate(newVariable);
                    end
                    % Clear the persistent value after we are done updating
                    % the workspace.
                    internal.matlab.variableeditor.peer.plugins.VEInteractionHandler.getSetDataValue([]);
                else
                    internal.matlab.datatoolsservices.logDebug("variableeditor::VEInteractionHandler", "handleDataChange possible change from outside VE");

                    % Leaving this code here in case we decide to revisit this.
                    % Previous code cleared the undo/redo stack if change
                    % from outside the VE was detected.  This was fragile
                    % code that caused the stack to get cleared too often
                    % and is for a very edge case use case that isn't
                    % likely what the user intended.
                    % internal.matlab.datatoolsservices.logDebug("variableeditor::VEInteractionHandler", "handleDataChange clearing undo cache");
                    % sh.OrigData = newVariable;
                    % sh.CommandArray = [];
                    % sh.UndoCommandArray = [];
                end
            else
                internal.matlab.datatoolsservices.logDebug("variableeditor::VEInteractionHandler", "handleDataChange ignoring update");

                % Ensure the ForceUpdate flag is reset after the forced
                % update is recieved
                this.ViewModel.DataModel.ForceUpdate = false;
                % DataChange should be ignored for all User Variable Interaction
                % We assume that each user interaction will eventually
                % cause a DataChange event to fire. We can use that
                % assumption to reset the IgnoreUpdate flag so we do not
                % miss any external changes (eg. CMD Window) to respond to.
                this.IgnoreUpdate = false;
            end
        end
    end

    methods (Static)
        % Use this API to ensure we have access to a persistent copy of the
        % data
        function val = getSetDataValue(value)
            mlock;
            persistent lastDataVal;
            if nargin >= 1
                lastDataVal = value;     
            end
            val = lastDataVal;
        end
    end

end

