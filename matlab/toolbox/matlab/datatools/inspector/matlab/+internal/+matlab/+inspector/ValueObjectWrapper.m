% This class is unsupported and might change or be removed without notice in a
% future version.

% This class is a wrapper for allowing value objects to show in the Object
% Browser and Property Inspector.  It extends the NonHandleObjWrapper, which
% presents the fields of the value object to the InspectorProxyMixin, to use in
% the inspector.

% Copyright 2021-2025 The MathWorks, Inc.

classdef ValueObjectWrapper < internal.matlab.inspector.NonHandleObjWrapper

    methods
        function this = ValueObjectWrapper(obj, varName, workspace, isReadOnly)
            % Creates a ValueObjectWrapper for the given value object

            arguments
                % The value object being inspected
                obj

                % The variable name of the object
                varName string

                % The workspace the object is in.  May be text (like "base"), or
                % a workspace-like object
                workspace

                % Whether this object's properties should be read-only or not.
                isReadOnly logical = false
            end

            props = internal.matlab.inspector.ValueObjectWrapper.getPropertiesOfValueObj(obj);
            this@internal.matlab.inspector.NonHandleObjWrapper(obj, props, varName, workspace, isReadOnly);
            this.CreateStructFcn = @internal.matlab.inspector.ValueObjectWrapper.createStructForObject;

            % Initialize the PreviousData property with the struct data.  This
            % is used by comparison later to, to see if values have changed
            % outside the inspector.
            if length(obj) == 1
                % If there is a single object, access it directly.  (Some ML
                % objects error when accessed by index)
                this.PreviousData{1} = this.CreateStructFcn(obj);
            else
                for idx = 1:length(obj)
                    this.PreviousData{idx} = this.CreateStructFcn(obj(idx));
                end
            end
        end
    end

    methods(Static)
        function props = getPropertiesOfValueObj(obj)
            % Consolidate the properties in a similar way as is done in
            % InspectorProxyMixin's getPropertyListForMode for the default
            % MultiplePropertyCombinationMode (INTERSECTION)
            props = {};
            for i = 1:length(obj)
                objAtIdx = obj(i);

                p = properties(objAtIdx);
                if isempty(props)
                    props = p;
                else
                    props = intersect(props, p, "stable");
                end
            end
        end

        function st = createStructForObject(obj)
            % Used to get the struct for a value object. 
            props = internal.matlab.inspector.ValueObjectWrapper.getPropertiesOfValueObj(obj);   
            st = matlab.internal.datatoolsservices.createStructForObject(obj, props);
        end
    end
end
