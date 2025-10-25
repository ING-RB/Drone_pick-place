% This class is unsupported and might change or be removed without notice in a
% future version.

% This class is a wrapper for allowing non-handle objects to show in the Object
% Browser and Property Inspector.  It presents the fields of a non-handle object
% to the InspectorProxyMixin, to use in the inspector.

% It requires the variable name and workspace in order to set values.

% Copyright 2021-2022 The MathWorks, Inc.

classdef NonHandleObjWrapper < internal.matlab.inspector.InspectorProxyMixin & internal.matlab.inspector.ProxyAddPropMixin

    properties(Hidden = true)
        % Variable name, workspace, and class
        VariableName string
        VariableWorkspace
        VariableClass string

        % Keep a reference to the value object being inspected
        ObjectRef = []

        % Whether to access properties with get(obj, 'prop'), of if we can just
        % do obj.prop
        RegWithGetSet = false
    end

    methods
        function this = NonHandleObjWrapper(obj, props, varName, workspace, isReadOnly, publicSetAccessProps)
            arguments
                % The non-handle object being inspected
                obj

                % The properties (or fields) of the non-handle object being
                % inspected
                props

                % The variable name of the non-handle object being inspected
                varName string

                % The workspace the non-handle object being inspected is in.
                % May be text (like "base"), or a workspace-like object
                workspace

                % Whether this object's properties should be read-only or not.
                isReadOnly logical = false

                % Allow passing in the properties with public set access
                publicSetAccessProps string = strings(0);
            end

            this@internal.matlab.inspector.InspectorProxyMixin(obj);

            this.VariableWorkspace = workspace;
            this.VariableName = varName;
            this.VariableClass = class(obj);
            this.ObjectRef = obj;

            for idx = 1:length(props)

                % For each of the properties in the object, create a dynamic
                % property in the ProxyView, and assign its value
                propName = props{idx};
                if isempty(propName)
                    continue
                end

                m = metaclass(obj);
                propInfo = m.PropertyList(strcmp({m.PropertyList.Name}, propName));
                if isReadOnly
                    % If the isReadOnly flag is set, then all of the properties
                    % should be shown as read-only.  Do this by setting the set
                    % access to private.
                    setAccess = "private";
                elseif isempty(propInfo)
                    if ~isempty(publicSetAccessProps)
                        if any(contains(publicSetAccessProps, propName))
                            setAccess = "public";
                        else
                            setAccess = "private";
                        end
                    else
                        % If there's no metaclass info, assume the property should
                        % be shown as public
                        setAccess = "public";
                    end
                else
                    setAccess = propInfo.SetAccess;
                end

                % Get the current value of the property from the original object
                try
                    currValue = obj.(propName);
                catch
                    currValue = get(obj, propName);
                    this.RegWithGetSet = true;
                end
                setMethod = @(t,v)setPropValue(t, propName, v);
                getMethod = @(t)getPropValue(t, propName);

                this.addDynamicProp(propName, ...
                    "DisplayName", propName, ...
                    "Value", currValue, ...
                    "Type", class(currValue), ...
                    "Access", setAccess, ...
                    "SetMethod", setMethod, ...
                    "GetMethod", getMethod);
            end
        end

        function setPropValue(this, propName, val)
            % SetMethod for when properties are changed.  This is needed to
            % apply the value to the named variable in the specified workspace.

            arguments
                this

                % Name of the property being changed
                propName string

                % Value being applied
                val
            end

            % Create an expression that we can call evalin with
            if iscategorical(val) || ischar(val)
                rhs =  """" + string(val) + """";
            elseif isnumeric(val)
                if ~isscalar(val)
                    rhs =  "[" + num2str(val) + "]";
                else
                    rhs =  val;
                end
            elseif islogical(val)
                if val
                    rhs = "true";
                else
                    rhs = "false";
                end
            end

            numObjects = length(this.ObjectRef);
            for idx = 1:numObjects
                % Create the expression, which will be something like:
                % obj.('prop') = 1;  OR obj(2).('prop') = 1; OR
                % set(obj, 'prop', 1); OR set(obj(2), 'prop', 1);

                varName = this.VariableName;
                if numObjects > 1
                    varName = varName + "(" + idx + ")";
                end
                expression = this.getExpressionStart("set", propName, varName, rhs);

                if ~isempty(expression)
                    if ~isempty(this.getObjectInWS(this.VariableWorkspace))
                        evalin(this.VariableWorkspace, expression);
                    elseif ~isempty(this.getObjectInWS("base"))
                        evalin("base", expression);
                    else
                        this.ObjectRef.(propName) = val;
                    end
                end
            end
        end

        function v = getPropValue(this, propName)
            % GetMethod for properties.  This is needed in order to get the
            % value from the variable in the workspace.

            arguments
                this

                % Name of the property being retrieved
                propName string
            end

            % Create the expression, which will be something like:
            % obj.('prop');  OR
            % get(obj, 'prop');
            expression = this.getExpressionStart("get", propName, this.VariableName);

            try
                v = evalin(this.VariableWorkspace, expression);
            catch ex
                try
                    if ~isempty(this.getObjectInWS("base"))
                        v = evalin("base", expression);
                    else
                        v = this.ObjectRef.(propName);
                    end
                catch
                    rethrow(ex)
                end
            end
        end

        function obj = getOriginalObjectAtIndex(this, idx)
            % Override the function to get to the original object

            arguments
                this

                % Index of the object to retrieve
                idx
            end

            if isempty(this.VariableName) || strlength(this.VariableName) == 0
                % During construction
                obj = getOriginalObjectAtIndex@internal.matlab.inspector.InspectorProxyMixin(this, idx);
            else
                % Once construction is over, get the original object from the
                % workspace
                try
                    obj = evalin(this.VariableWorkspace, this.VariableName);
                catch ex
                    obj = this.getObjectInWS("base");
                    if isempty(obj)
                        obj = this.ObjectRef;
                    end

                    if isempty(obj)
                        rethrow(ex)
                    end
                end
                obj = obj(idx);
            end
        end
    end

    methods(Hidden)
        function objInWS = getObjectInWS(this, workspace)
            % Called to see if the object specified with this.VariableName
            % exists in the workspace, and is of type this.VariableClass.  For
            % example, does object "x" exist in workspace "base"?  Returns the
            % object if it is found, otherwise returns [].
            objInWS = [];
            try
                objInWS = evalin(workspace, this.VariableName);
            catch
                if ~isempty(objInWS) && ~isequal(class(objInWS), this.VariableClass)
                    objInWS = [];
                end
            end
        end

        function expression = getExpressionStart(this, fcn, propName, varName, rhs)
            arguments
                this
                fcn string
                propName string
                varName string
                rhs string = strings(0)
            end
            if this.RegWithGetSet
                expression = fcn + "(" + varName + ", '" + propName;
            else
                expression = varName + ".('" + propName;
            end

            if strcmp(fcn, "get")
                expression = expression + "');";
            else
                if this.RegWithGetSet
                    expression = expression +  "', " + rhs + ");";
                else
                    expression = expression + "') = " + rhs + ";";
                end
            end
        end
    end
end
