% This class is unsupported and might change or be removed without notice in a
% future version.

% This class is a wrapper for allowing structs to show in the Object Browser and
% Property Inspector.  It extends the NonHandleObjWrapper, which presents the
% fields of the struct to the InspectorProxyMixin, to use in the inspector.

% Copyright 2021-2025 The MathWorks, Inc.

classdef JavaObjectWrapper < internal.matlab.inspector.NonHandleObjWrapper

    properties(Constant, Hidden)
        % Skip these properties of a Java object, otherwise it leads to a huge,
        % recursive hierarchy.  Skipping these also makes the object browser
        % more closely resemble the Command Line when you call get() for a java
        % object.
        JAVA_PROPS_TO_SKIP = ["AccessibleContext", "AnnotatedExceptionTypes", "Class", "DeclaredMethods", "DeclaringClass", "GenericReturnType", "Parameters", "ReturnType", "Type"];
    end
    
    methods
        function this = JavaObjectWrapper(obj, varName, workspace, isReadOnly)

            arguments
                obj
                varName (1,1) string
                workspace = "base"
                isReadOnly (1,1) logical = false
            end

            javaStruct = struct;
            javaFields = "";
            pubSetAccessProps = "";

            if ~ismethod(obj, "get")
                % Some java objects have a 'get' method defined on them, but
                % this means that the MATLAB 'get' to get properties won't work.
                % When this happens, show an empty object

                try
                    javaStruct = get(obj);
                    javaFields = fieldnames(javaStruct);
                    if isReadOnly
                        pubSetAccessProps = "";
                    else
                        % Use the 'set' method to see which properties have set
                        % access
                        pubSetAccessStruct = set(obj);
                        pubSetAccessProps = fieldnames(pubSetAccessStruct);
                        if isempty(pubSetAccessProps)
                            pubSetAccessProps = "";
                        end
                    end
                catch
                    % Some java objects error on get().  Show no properties in
                    % this case.
                end
            end

            this@internal.matlab.inspector.NonHandleObjWrapper(javaStruct, ...
                javaFields, varName, workspace, false, pubSetAccessProps);
            this.PropsToSkipInHierarchy = this.JAVA_PROPS_TO_SKIP;
            
            % Initialize class objects based on the java properties and access
            this.PreviousData{1} = matlab.internal.datatoolsservices.createStructForObject(javaStruct);
            this.OrigObjSetAccessNames = pubSetAccessProps;
            this.ObjectRef = obj;
        end

        function v = getPropValue(this, propName)
            arguments
                this
                propName (1,1) string
            end

            if strlength(this.VariableName) == 0
                % When there's no variable name, just use the OriginalObject's value
                v = this.OriginalObjects.(propName);
                return;
            elseif contains(this.VariableName, ".")
                % Build up an expression to call get on the nested hierarchy of
                % java objects, so get(get(...
                varAndProps = split(this.VariableName, ".");
                exp = "get(" + varAndProps(1) + ", '" + varAndProps(2) + "')";
                if length(varAndProps) > 2
                    for idx = 3:length(varAndProps)
                        exp = "get(" + exp + ", '" + varAndProps(idx) + "')";
                    end
                end

                % exp will be something like:
                % get(get(javaObject, 'MaximumSize'), 'Size')
                exp = "get(" + exp + ", '" + propName + "')";
                expression = exp;
            else
                % Call get on the java object's property name
                expression = "get(" + this.VariableName + ", '" + propName + "');";
            end
            v = evalin(this.VariableWorkspace, expression);
        end

        function setPropValue(this, propName, val)
            % SetMethod for when properties are changed.  This is needed to
            % apply the value to the named variable in the specified workspace.

            arguments
                this

                % Name of the property being changed
                propName (1,1) string

                % Value being applied
                val
            end

            if strlength(this.VariableName) == 0
                % When there's no variable name, apply the value to the ObjectRef and OriginalObjects.
                % This may fail for some sub-referencing of objects.
                set(this.ObjectRef, char(propName), val)
                this.OriginalObjects.(propName) = val;
                return;
            end

            % Create an expression that we can call evalin with
            if iscategorical(val) || ischar(val)
                % Example:  set(javaObj, 'Name', "test");
                expression = "set(" + this.VariableName + ", '" + propName + "', """ + string(val) + """);";
            elseif isnumeric(val)
                if ~isscalar(val)
                    % Example:  set(javaObj, 'HorizontalTextPosition', [1  2  3]);
                    expression = "set(" + this.VariableName + ", '" + propName + "', [" + num2str(val) + "]);";
                else
                    % Example:  set(javaObj, 'HorizontalTextPosition', 10);
                    expression = "set(" + this.VariableName + ", '" + propName + "', " + val + ");";
                end
            elseif islogical(val)
                if val
                    % Example:  set(javaObj, 'Enabled', true);
                    expression = "set(" + this.VariableName + ", '" + propName + "', true);";
                else
                    % Example:  set(javaObj, 'Enabled', false);
                    expression = "set(" + this.VariableName + ", '" + propName + "', false);";
                end
            else
                % Create a temporary variable in the workspace to do the
                % assignment, and clear it afterwards
                % Example:  set(jl, 'Background', inspectorAssignedVal);
                assignin(this.VariableWorkspace, "inspectorAssignedVal", val);
                c = onCleanup(@() evalin(this.VariableWorkspace, "clearvars inspectorAssignedVal"));
                expression = "set(" + this.VariableName + ", '" + propName + "', inspectorAssignedVal);";
            end

            if ~isempty(expression)
                evalin(this.VariableWorkspace, expression);
            end
        end
    end

    methods(Access = protected)
        function propertyList = getPublicNonHiddenProps(~, obj)

            arguments
                ~
                obj
            end

            propertyList = fieldnames(obj);
        end
    end
end
