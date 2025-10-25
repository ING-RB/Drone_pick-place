classdef MLHandleObjectDataModel < ...
        internal.matlab.variableeditor.MLObjectDataModel & ...
        internal.matlab.variableeditor.TimerBasedDataModel
    % MLHandleObjectDataModel - Data Model for handle objects for the
    % variable editor

    % Copyright 2014-2025 The MathWorks, Inc.

    properties(Access = protected, Transient)

        % Keep track of listeners added to check for properties being
        % added, removed or changed
        PropAddedListener = [];
        PropRemovedListener = [];
        PropChangedListener = [];

    end

    events
        PropertyChanged;
        PropertyAdded;
        PropertyRemoved;
        MetaDataChanged;
    end

    methods(Access = public)
        function this = MLHandleObjectDataModel(name, workspace, useTimer)
            if nargin<3
                useTimer = true;
            end
            this@internal.matlab.variableeditor.MLObjectDataModel(...
                name, workspace);
            this@internal.matlab.variableeditor.TimerBasedDataModel(useTimer);
        end

        % updateData
        function data = updateData(this, varargin)
            newData = varargin{1};
            if ~this.isTimerRunning
                this.updateChangeListeners(newData);
                this.checkUnobservableUpdates(newData);
                % Updating DataModel's Data property in case we
                % received a new instance of the handle object
                this.Data = newData;
                data = newData;
            end
        end

        function delete(this)
            % Remove listeners if the object is destroyed
            this.removeChangeListeners();

            this.delete@internal.matlab.variableeditor.TimerBasedDataModel;
        end

        function evalStr = executeSetCommand(this, setCommand, errorMsg)
            if (nargin < 3)
                errorMsg = [];
            end
            % Call the super class to execute the command, and set the
            % DataChanged flag in the case of a private workspace
            evalStr = this.executeSetCommand@internal.matlab.variableeditor.MLObjectDataModel(...
                setCommand, errorMsg);
            if ~ischar(this.Workspace)
                this.DataChanged = true;
            end
        end
    end

    methods(Access = protected)
        function removeChangeListeners(this)
            % Remove any Property Added listeners which have been added
            if ~isempty(this.PropAddedListener)
                delete(this.PropAddedListener);
                this.PropAddedListener = [];
            end

            % Remove any Property Removed listeners which have been added
            if ~isempty(this.PropRemovedListener)
                delete(this.PropRemovedListener);
                this.PropRemovedListener = [];
            end

            % Remove any Property Changed listeners which have been added
            if ~isempty(this.PropChangedListener)
                if iscell(this.PropChangedListener)
                    cellfun(@(x) delete(x), this.PropChangedListener)
                else
                    delete(this.PropChangedListener);
                end
                this.PropChangedListener = [];
            end

            this.ListenersChecked = false;
        end

        function updateChangeListeners(this, obj)
            this.removeChangeListeners();

            if isa(obj, 'dynamicprops')
                % Add listeners for dynamic properties being added or
                % removed
                this.PropAddedListener = event.listener(obj, ...
                    'PropertyAdded', @this.propAddedCallback);
                this.PropRemovedListener = event.listener(obj, ...
                    'PropertyRemoved', @this.propRemovedCallback);
            end

            m = metaclass(obj);
            p = m.PropertyList;
            observables = findobj(p, 'SetObservable', true);
            if ~isempty(observables)
                % Add listeners for observable Property changes
                this.PropChangedListener = event.proplistener(obj, ...
                    observables, 'PostSet', @this.propChangedCallback);
            end
            this.ListenersChecked = true;
        end

        function propAddedCallback(this, ~, ed)
            % Redisplay the object by setting DataChanged = true
            this.DataChanged = true;

            % Support standard PropertyAdded events, as well as internally
            % generated ones, which are of the type PropertyChangeEventData
            if isa(ed, "internal.matlab.variableeditor.PropertyChangeEventData")
                this.firePropertyAddedEvent(ed.Properties, []);
            else
                this.firePropertyAddedEvent(ed.PropertyName, []);
            end
        end

        function propRemovedCallback(this, ~, ed)
            % Redisplay the object by setting DataChanged = true
            this.DataChanged = true;

            this.firePropertyRemovedEvent(ed.PropertyName, []);
        end

        function propChangedCallback(this, es, ed)
            % Redisplay the object by setting DataChanged = true
            this.DataChanged = true;

            % Support standard PropertyChanged events, as well as internally
            % generated ones, which are of the type PropertyChangeEventData
            if isa(ed, "internal.matlab.variableeditor.PropertyChangeEventData")
                this.firePropertyChangedEvent(ed.Properties, ed.Values);
            else
                if isa(ed.AffectedObject, ...
                        'internal.matlab.inspector.InspectorProxyMixin')
                    this.firePropertyChangedEvent(es.Name, ...
                        get(ed.AffectedObject, es.Name));
                end
            end
        end

        function firePropertyChangedEvent(this, properties, values)
            this.firePropertyEvent('PropertyChanged', properties, values);
        end

        function fireMetaDataChangedEvent(this, properties, values)
            this.firePropertyEvent('MetaDataChanged', properties, values);
        end

        function firePropertyRemovedEvent(this, properties, values)
            this.firePropertyEvent('PropertyRemoved', properties, values);
        end

        function firePropertyAddedEvent(this, properties, values)
            this.firePropertyEvent('PropertyAdded', properties, values);
        end
    end
end
