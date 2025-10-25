classdef MLInspectorDataModel < ...
        internal.matlab.variableeditor.MLHandleObjectDataModel
    
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % DataModel for the Property Inspector.  Overrides the
    % MLObjectDataModel so the setData can be short-circuited for handle
    % objects (and objects which implement the InspectorProxyMixin
    % interface).
    
    % Copyright 2015-2025 The MathWorks, Inc.
    
    properties(Hidden = true)
        ChangedProperties;
        MetaDataHandler {mustBe_internal_matlab_inspector_InspectorMetaData}
        VariableName string = strings(0);
        VariableWorkspace string = strings(0);
    end
    
    properties(Access = private)
        PropertiesUpdatedListener = [];
        PropForceChangeListener = [];
        PropMetadataChangedListener = [];
    end
    
    events
        PropertiesUpdated
        PropertyMetadataChanged
    end
    
    methods
        % Constructor - creates a new MLInspectorDataModel for a variable
        % with the specified name and workspace
        function this = MLInspectorDataModel(name, workspace, useTimer)
            if nargin<3
                useTimer = true;
            end
            this@internal.matlab.variableeditor.MLHandleObjectDataModel(...
                name, workspace, useTimer);
            
            % The inspector doesn't require the workspace listener.  It uses a
            % combination of event listeners and timers to check for object
            % updates.
            % internal.matlab.datatoolsservices.WorkspaceListener's removeListener is fired.
            this.removeListeners();
        end
        
        % Called to set the data on the object.  varargin is the Property
        % Name and Value.
        function varargout = setData(this, varargin)
            index = find(strcmp(properties(this.Data), varargin{1}));
            if isa(this.Data, 'handle')
                setPropertyValue(this.Data, ...
                    varargin{1}, ...  % Property Name
                    varargin{2});     % New value
                varargout = {};
                
                % Trigger DataChange event
                eventdata = ...
                    internal.matlab.variableeditor.DataChangeEventData;
                eventdata.Range = [index, 1];
                eventdata.Values = varargin{2};
                this.notify('DataChange', eventdata);
            else
                % set name and call super method
                varargout{1} = ...
                    setData@internal.matlab.variableeditor.MLObjectDataModel(...
                    this, varargin{2}, index, [], []);
            end
        end
        
        function data = updateData(this, varargin)
            s = warning('off', 'all');
            data = varargin{1};
            
            if ~isa(data, 'handle')
                d = this.PreviousData;
                if ~isempty(d)
                    % Compare as a struct, just as a way to compare the
                    % the old and new data
                    dataStruct = ...
                        matlab.internal.datatoolsservices.createStructForObject(...
                        data);
                    
                    if ~isequaln(d, dataStruct)
                        this.DataChanged = true;
                        
                        props1 = fieldnames(d);
                        props2 = fieldnames(dataStruct);
                        if isequal(sort(props1), sort(props2))
                            changedIdx = cellfun(@(x) ~isequaln(...
                                d.(x), dataStruct.(x)), props1);
                            changedProps = props1(changedIdx);
                            this.ChangedProperties = changedProps;
                            this.DataChanged = true;
                            for i = 1:length(changedProps)
                                propName = changedProps{i};
                                dispValue = ...
                                    internal.matlab.datatoolsservices.FormatDataUtils.getDisplayEditValue(...
                                    data.(propName));
                                
                                this.Data.setPropertyValue(propName, ...
                                    data.(propName), ...
                                    dispValue, this.Name);
                            end
                        else
                            this.ChangedProperties = setdiff(...
                                sort(props2), sort(props1));
                        end
                    end
                    this.PreviousData = dataStruct;
                else
                    this.PreviousData = ...
                        matlab.internal.datatoolsservices.createStructForObject(...
                        data);
                end
            end
            warning(s);
        end
        
        
        function checkForUnobservableUpdates(this)
            % Checks to see if any properties have changed between the
            % original object and the proxy object (this can happen with
            % non-observable properties).  If any changes are detected,
            % then the proxy object's properties are re-initialized with
            % the current values from the original object
            if isa(this.Data, 'internal.matlab.inspector.InspectorProxyMixin')
                
                % See if there were any changes, and what properties
                % changed
                [changed, changedProps, changedProxyProps] = ...
                    OrigObjectChange(this.Data);
                if changed
                    % Reinitialize the properties from the original object
                    reinitializeFromOrigObject(this.Data, changedProps, ...
                        changedProxyProps);
                    this.DataChanged = true;
                    if ~isempty(changedProxyProps)
                        this.ChangedProperties = unique([changedProps(:)' changedProxyProps(:)']);
                    else
                        this.ChangedProperties = changedProps;
                    end
                end
            end
        end
        
        function handleUpdateTimer(this)   
            % Timer callback is called asynchronously to ensure that all the graphics is up to date to prevent excuting the callback in the middle of 
			% MATLAB graphics code
             matlab.graphics.internal.drawnow.callback(@(e,d)this.timerClb()); 
        end
        
        function timerClb(this)
             internal.matlab.datatoolsservices.logDebug('ve::timer', "- timerClb() start");
             tStart = tic;

            if ~isvalid(this) 
                % Early return if timerClb is called on the deleted object.
                % This can happen because this callback can be called
                % asynchronously
                internal.matlab.datatoolsservices.logDebug('ve::timer', "Early return from timerClb, ~isvalid!");
                return
            end
            
            if ~isobject(this.Data) || ~isvalid(this.Data)
                % Stop the timer if the object has been deleted
                internal.matlab.datatoolsservices.logDebug('ve::timer', "Stopping timer, data is not valid");
                this.stopTimer;
            else
                try
                    % Check to see if any SetObservable=false properties have
                    % changed
                    this.checkForUnobservableUpdates;

                    % check if there is a change in metadata
                    if ~isempty(this.MetaDataHandler) && this.MetaDataHandler.hasDataChanged()
                        this.metaDataChanged();
                    end

                    if this.DataChanged
                        % If the data has changed, fire an event
                        if ~isempty(this.ChangedProperties)
                            props = properties(this.getData);
                            for idx=1:length(this.ChangedProperties)
                                % Typically only one property changes at a time,
                                % but it can be multiple if there are dependent
                                % properties.  But this is rare, so firing an event
                                % for each property should be ok.
                                propName = this.ChangedProperties{idx};
                                if ismember(propName, props)
                                    value = this.getData.(propName);

                                    % Fire property changed event
                                    this.firePropertyChangedEvent(propName, value);
                                elseif ~isprop(this.getData, propName)
                                    % Fire property removed event if it isn't a
                                    % property of data (it may be a hidden
                                    % property, which we shouldn't report as
                                    % being removed)
                                    this.firePropertyRemovedEvent(propName, '');
                                end
                            end
                        end
                        % Reset the DataChanged and Changed Properties flags
                        this.DataChanged = false;
                        this.ChangedProperties = {};
                    end

                    tElapsed = toc(tStart);
                    if tElapsed > this.MAX_AUTO_REFRESH_DELAY
                        internal.matlab.datatoolsservices.logDebug('ve::timer', "PI TimerCallbackDelay TOO LONG = " + tElapsed);
                        this.stopTimer;
                        this.fireAutoRefreshChanged(false);
                    else
                        this.TimerCallbackDelay = max(1, ceil(tElapsed));
                        internal.matlab.datatoolsservices.logDebug('ve::timer', "PI TimerCallbackDelay = " + this.TimerCallbackDelay);
                        this.startTimer;
                    end
                catch ex
                    if isvalid(this)
                        this.stopTimer;
                    end
                end
            end
            internal.matlab.datatoolsservices.logDebug('ve::timer', "timerClb() end");
        end
        
        function s = getSize(this)
            % Override getSize from ObjectDataModel to handles cases where the
            % object may have been deleted, but there's one last call from the
            % client to update the data (and the first step is to check the
            % size).  Always assume 4 columns, like the ObjectDataModel.
            s = [0, 4];
            try
                hdl = all(ishandle(this.Data));
                if ~hdl || all(isvalid(this.Data))
                    s = [length(properties(this.Data)) 4];
                end
            catch
            end
        end
        
        function restartTimer(this)
            % Override the restartTimer method to make sure it is named properly
            name = this.Name;
            this.Name = 'inspector';
            this.stopTimer;
            this.TimerState = internal.matlab.variableeditor.ObjectTimerState.START_REQUESTED;
            this.startTimer;
            this.Name = name;
        end
        
        function updateListeners(this, obj)
            % Add listeners for dynamic properties being added or
            % removed
            this.removeChangeListeners();
            
            if isa(obj, "internal.matlab.inspector.ProxyAddPropMixin")
                % Handle property added and changed separately for these mixins
                % which add/remove/change dynamic properties
                this.PropAddedListener = event.listener(obj, ...
                    'PostPropertyAdded', @this.propAddedCallback);
                this.PropForceChangeListener = event.listener(obj, ...
                    'PropertyChanged', @this.propChangedCallback);
                this.PropMetadataChangedListener = event.listener(obj, ...
                    'PropertyMetadataChanged', @this.propMetadataChangedCallback);
            else
                this.PropAddedListener = event.listener(obj, ...
                    'PropertyAdded', @this.propAddedCallback);
            end
            this.PropRemovedListener = event.listener(obj, ...
                'PropertyRemoved', @this.propRemovedCallback);
            this.PropertiesUpdatedListener = event.listener(obj, ...
                'PropertiesUpdated', @this.propsUpdatedListener);
        end
        
        function delete(this)
            this.stopTimer;
            if ~isempty(this.PropertiesUpdatedListener)
                delete(this.PropertiesUpdatedListener);
            end
        end

        function metaDataChanged(this)
            this.fireMetaDataChangedEvent('MetaDataChanged', this.MetaDataHandler.getData());
        end

        function flagDataChanged(this, changedProps)
            % Called to notify the DataModel that one or more properties
            % changed
            this.DataChanged = true;
            this.ChangedProperties = changedProps;
        end
    end
    
    methods(Access = protected)
        function propsUpdatedListener(this, ~, ed)
            % Propagate the event out
            this.notify("PropertiesUpdated", ed);
        end

        function propMetadataChangedCallback(this, ~, ed)
            % Propogate the event out
            this.notify("PropertyMetadataChanged", ed)
        end
    end
end


function mustBe_internal_matlab_inspector_InspectorMetaData(input)
    if ~isa(input, 'internal.matlab.inspector.InspectorMetaData') && ~isempty(input)
        throwAsCaller(MException('MATLAB:type:PropSetClsMismatch','%s',message('MATLAB:type:PropSetClsMismatch','internal.matlab.inspector.InspectorMetaData').getString));
    end
end
