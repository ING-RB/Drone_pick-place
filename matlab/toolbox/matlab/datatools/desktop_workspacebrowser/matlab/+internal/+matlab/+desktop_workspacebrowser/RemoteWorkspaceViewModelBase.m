classdef RemoteWorkspaceViewModelBase < handle
    % RemoteWorkspaceViewModelBase is the base view model for
    % WorkspaceBrowser view models.
    % This class encapsulates common functionalities for two WorkspaceBrowser
    % view models.
    
    % Copyright 2023-2024 The MathWorks, Inc.

    properties(SetObservable=false, SetAccess='protected', GetAccess='protected', Dependent=false, Hidden=true, Transient)
        VariablesAddedListener;
        VariablesRemovedListener;
        VariablesChangedListener;
    end
    
    properties(Constant)
        VisibleObjValuesMap = struct("Value", "DisplayValue", "Size", "DisplaySize", ...
            "Class", "DisplayClass");
    end

    methods
        function this = RemoteWorkspaceViewModelBase(variable)
            this.VariablesAddedListener = event.listener(variable.DataModel, 'VariablesAdded', @(es,ed)this.sendVariableEvent('VariablesAdded',ed.Variables));
            this.VariablesRemovedListener = event.listener(variable.DataModel, 'VariablesRemoved', @(es,ed)this.sendVariableEvent('VariablesRemoved',ed.Variables));
            this.VariablesChangedListener = event.listener(variable.DataModel, 'VariablesChanged', @(es,ed)this.sendVariableEvent('VariablesChanged',ed.Variables));
        end

        function delete(this)
            delete(this.VariablesAddedListener);
            delete(this.VariablesRemovedListener);
            delete(this.VariablesChangedListener);
            this.VariablesAddedListener = [];
            this.VariablesRemovedListener = [];
            this.VariablesChangedListener = [];
        end

        function sendVariableEvent(this, type, Variables)
            viewKey = this.parentID + "_" + this.viewID; %#ok<*MCNPN>
            peerNode = this.Provider.ViewMap(viewKey);
            if isvalid(peerNode)
                data = struct('Variables', Variables);
                peerNode.dispatchEvent(type, data);
            end
        end

        function subVarName = getSubVarName(~, ~, varName)
            % Generates the name string for a sub-variable expression
            subVarName = varName;
        end
    end

    methods(Access = protected)
     
        % Override from RemoteStructViewModel to provide
        % WorkspaceFieldSettings as WorkspaceBrowser has a separate
        % settings file.
        function fieldSettings = getFieldSettingsInstance(~)
            fieldSettings = internal.matlab.desktop_workspacebrowser.FieldColumns.WorkspaceFieldSettings.getInstance;           
        end

        % WSB does not have any server side plugins, do not initialize
        % widgetRegistry to save on startup.
        function initializePlugins(~)
        end

        function bytesCol = createBytesCol(this, settingsController)
            bytesCol = internal.matlab.desktop_workspacebrowser.FieldColumns.BytesCol();
            if ~isempty(settingsController)
                 bytesCol.SettingsController = settingsController;
                 bytesCol.Workspace = this.DataModel.Workspace;
            end
            this.addFieldColumn(bytesCol);
            this.DataModel.BytesColDisplayed = true; %#ok<MCNPR>
        end

        function result = evaluateClientSetData(this, ~, ~, ~)
            % Return the previously evaluated value, because evalin
            % 'caller' from the superclasses won't be correct
            result = this.evaluatedSetValue;
        end
        
        function classStr = getClassName(~)
            classStr = 'internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModelBase';
        end
        
        % whenever a variable is renamed in the workspaceBrowser, execute
        % set command and also emit a propertyChanged event. If the
        % variable has views elsewhere (Like Variable Editor), we need to
        % notify those views.
        function renameCmd = handleFieldNameEdit(this, data, row, ~)
            names = fieldnames(this.DataModel.Data);
            if ~isempty(this.SortedIndices)
                names = names(this.SortedIndices);
            end
            
            if any(strcmp(names, data))
                msg = message('MATLAB:codetools:structArray:VariableExists', data);
                ex = MException('WorkspaceBrowser:VariableExists', msg);
                throw(ex);
            end
            
            renameCmd = sprintf('%s=%s; builtin("clear", "%s");', data, names{row}, names{row});
            this.DataModel.executeSetCommand(renameCmd);   
            propertyChangedEvent = internal.matlab.variableeditor.PropertyChangeEventData;
            propertyChangedEvent.Properties = 'VariableRenamed';
            propertyChangedEvent.Values = struct('OldValue', names{row}, 'NewValue', data);
            try
                this.notify('PropertyChange', propertyChangedEvent);
            catch e
                internal.matlab.datatoolsservices.logDebug("workspacebrowser::RemoteWorkspaceViewModelBase", "notifyPropertyChange failed: " + e.message);
            end
        end
        
        function msg =  getErrorOnInvalidRename(~, rawData)
            varName = internal.matlab.datatoolsservices.VariableUtils.getTruncatedIdentifier(rawData);
            msg = message('MATLAB:codetools:structArray:InvalidRenameVarOnEdit', varName);
        end

        % Checks if the value is an ObjectValueSummary and updates if necessary
        function b = updateIfObjectValueSummary(this, currentValue, row, column)
            if isa(currentValue, 'internal.matlab.workspace.ObjectValueSummary')
                if (ismember(currentValue.DisplayClass,internal.matlab.desktop_workspacebrowser.MLWorkspaceDataModel.DefaultObjDataTypes) || ...
                    (internal.matlab.datatoolsservices.VariableUtils.isNumericObject(currentValue.RawValue)))
                    currentValue = currentValue.RawValue;
                else
                    % If this is an ObjectValueSummary and we do not have a
                    % RawValue, update the dataStore
                    internal.matlab.variableeditor.peer.RemoteArrayViewModel.updateDataForRange(this, row, column);
                    b = true;
                    return;
                end
            end
            % Default return false if no update is necessary
            b = false; 
        end
    end 

    methods(Static)
        function hName = getHeaderName(fcol)
            hName = "";
            if ~isempty(fcol)
                hName = fcol.HeaderName;
            end
        end
    end
end
