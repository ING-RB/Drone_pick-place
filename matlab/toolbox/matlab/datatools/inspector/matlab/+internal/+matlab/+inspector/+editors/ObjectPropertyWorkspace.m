classdef ObjectPropertyWorkspace < matlab.internal.datatoolsservices.AppWorkspace
    % Represents a workspace that can access the property of an object,
    % this workspace can then be used in the variable editor and the
    % property can be accessed like a named variable.

    % Copyright 2020-2024 The MathWorks, Inc.

    properties (Access = protected)
        InspectedObjectI
        PropertyNameI

        PropertyChangeListener = event.proplistener.empty;
    end

    properties
        % Function to be called if there is an error applying property value
        % changes.  Arguments to the function will be the property name, and the
        % MException that was encountered.
        ErrorCallbackFcn = function_handle.empty;
    end

    properties (Dependent)
        InspectedObject
        PropertyName
        PropertyData  % TODO: remove once uivariableeditor supports changing of variable names
    end

    methods
        function val = get.InspectedObject(this)
            val = this.InspectedObjectI;
        end

        function set.InspectedObject(this, obj)
            this.InspectedObjectI = obj;
            this.updatePropertyInWorkspace(obj, this.PropertyName, this.PropertyName);
        end

        function val = get.PropertyName(this)
            val = this.PropertyNameI;
        end

        function set.PropertyName(this, newProp)
            oldProp = this.PropertyNameI;
            this.PropertyNameI = newProp;
            this.updatePropertyInWorkspace(this.InspectedObject, oldProp, newProp);
        end

        function val = get.PropertyData(this)
            val = [];
            if ~isempty(this.PropertyName) && strlength(this.PropertyName) > 0
                val = this.getValue(this.PropertyName);
            end
        end

        function set.PropertyData(this, val)
            this.assignin(this.PropertyName, val);
            this.InspectedObject.(this.PropertyName) = val;
        end
    end

    methods
        function this = ObjectPropertyWorkspace(NVPairs)
            arguments
                NVPairs.InspectedObject = []
                NVPairs.PropertyName string = string.empty
            end

            this.setObjectAndProperty(NVPairs.InspectedObject, NVPairs.PropertyName);
        end

        function setObjectAndProperty(this, obj, newProp)
            oldProp = this.PropertyName;
            this.InspectedObjectI = obj;
            this.PropertyNameI = newProp;
            this.updatePropertyInWorkspace(obj, oldProp, newProp);
        end

        function o = evalin(this, cmd)
            % TODO: Remove once uivariableeditor supports changing
            % variables.  This is needed to allow editing to work properly
            isError = false;
            currVal = this.PropertyData;
            updatedCmd = strrep(cmd, 'PropertyData', this.PropertyNameI);
            o = {};

            containsEquals = contains(updatedCmd, "=");
            if ~containsEquals || (containsEquals && ~startsWith(cmd, "PropertyData"))
                % Without an assignment, this is just to evaluate the user entered value,
                % or to evaluate the current value.  (The 2nd check is to make sure if
                % the user enters text with an equal sign, it isn't treated as an assignment)
                o = this.evalin@matlab.internal.datatoolsservices.AppWorkspace(updatedCmd);

                % Return if there is no assignment being done
                return;
            end

            % No outputs on assignments
            this.evalin@matlab.internal.datatoolsservices.AppWorkspace(updatedCmd);

            % Get the value.  If there is an array of objects being
            % inspected, then value is an array of values, where the first
            % one is the one we've applied.  Otherwise for a single object,
            % values could be an array, but it is the entire value.
            values = this.getValue(this.PropertyName);

            for idx = 1:length(this.InspectedObject)
                inspectedObj = this.InspectedObject(idx);
                if this.isvariable(this.PropertyName) && ~isequaln(this.getValue(this.PropertyName), inspectedObj.(this.PropertyName))
                    try
                        inspectedObj.(this.PropertyName) = values;
                    catch ex
                        if ~isempty(this.ErrorCallbackFcn)
                            try
                                % Call the ErrorCallbackFcn if it is defined
                                this.ErrorCallbackFcn(this.PropertyName, ex)
                            catch
                                % Ignore errors from the user callback
                            end
                        end
                        isError = true;
                    end
                end
            end

            if isError
                % Revert the property data value if an error was encountered
                this.PropertyData = currVal;
            elseif isa(inspectedObj, "internal.matlab.inspector.ProxyAddPropMixin")
                % Notify of the change.  This may not get picked up
                % automatically for dynamic properties which don't exist on
                % the original object.
                inspectedObj.notifyPropChange(this.PropertyName, this.getValue(this.PropertyName));
            end
        end

        function delete(this)
            if ~isempty(this.PropertyChangeListener)
                delete(this.PropertyChangeListener);
            end
        end
    end

    %% Methods for RedefinesDot
    methods (Access=protected)
        function this = dotAssign(this, indexOp, varargin)
            this = this.dotAssign@matlab.internal.datatoolsservices.AppWorkspace(indexOp, varargin{:});
            varName = indexOp(1).Name;

            if (strcmp(varName, this.PropertyNameI) || strcmp(varName, 'PropertyData'))
                this.InspectedObject.(this.PropertyName) = varargin{1};
            end
        end
    end


    methods (Access = protected)
        function updatePropertyInWorkspace(this, obj, oldProp, newProp)
            if ~isempty(oldProp) && isvariable(this, oldProp)
                this.evalin(sprintf("clear %s;", oldProp));
            end

            if ~isempty(this.PropertyChangeListener)
                delete(this.PropertyChangeListener);
            end

            if ~isempty(obj) && ~isempty(newProp) && ~isvariable(this, newProp)
                % Only assign the last object's properties in the
                % workspace.  Previously we assigned in the array of
                % values, but that made it impossible to pull apart when
                % they were numeric arrays to begin with. The evalin
                % function in this class makes sure assignments apply to
                % all the objects being inspected.
                this.assignin(newProp, obj(end).(newProp));

                if isa(obj, "handle")
                    for idx = 1:length(obj)
                        inspectedObj = obj(idx);

                        origProp = findprop(inspectedObj, newProp);
                        if origProp.SetObservable
                            this.PropertyChangeListener(end+1) = addlistener(inspectedObj, newProp, ...
                                'PostSet', @(e,d)assignin(this, newProp, inspectedObj.(newProp)));
                        end
                    end
                end
            end

            this.notify('VariablesChanged');
        end
    end
end

