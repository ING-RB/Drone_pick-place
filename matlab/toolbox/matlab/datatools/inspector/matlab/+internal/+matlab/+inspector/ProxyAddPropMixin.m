classdef ProxyAddPropMixin < handle
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % ProxyAddPropMixin can be mixed in to classes which implement the
    % InspectorProxyMixin class, to provide additional functionality for proxy
    % classes which want to add/remove dynamic properties, or update enablement
    % of properties.
    %
    % This is needed so that when dynamic properties are added, the inspector
    % doesn't act upon the dynamic property add immediately before other
    % settings for the property can be set (label, tooltip, access, etc...)
    
    % Copyright 2015-2025 The MathWorks, Inc.

    events
        PostPropertyAdded
        PropertyMetadataChanged
        PropertyChanged
    end

    properties(Hidden, Access = protected)
        MetaDataChangedProps;
    end

    properties(Hidden)
        % Can be used to tell the inspector it can skip individual property
        % adds and removes, because a lot of them are happening, and a single
        % update will happen at the end.
        BulkPropertyChange (1,1) logical = false;
    end

    methods
        function addDynamicProp(this, propName, propInfo)
            % Called to add a dynamic property to the InspectorProxyMixin class.
            % The arguments can include the DisplayName, Tooltip,
            % Type, Value, Access, GetMethod and SetMethod.
            
            arguments
                this;
                propName (1,1) string;
                propInfo.DisplayName (1,1) string;
                propInfo.Tooltip (1,1) string;
                propInfo.Type (1,1) string;
                propInfo.Value;
                propInfo.Access (1,1) string;
                propInfo.GetMethod function_handle;
                propInfo.SetMethod function_handle;

                % TODO: These are deprecated, in place of DisplayName and
                % Tooltip, respectively.
                propInfo.Description (1,1) string;
                propInfo.DetailedDescription (1,1) string;
            end
            
            % Only attempt to add the property if it doesn't already exist, and
            % the propName is valid (valid var name and length)
            if ~isprop(this, propName) && isvarname(propName)
                
                if isfield(propInfo, "Type")
                    % Save the type in the type map that has already been set,
                    % since you can't set the 'Type' of a dynamic property.
                    this.PropertyTypeMap(propName)= propInfo.Type;
                end
                
                % Add the dynamic property
                p = addprop(this, propName);
                
                if isfield(propInfo, "DisplayName")
                    % Set the Description, which is used as the label to show in
                    % the inspector
                    this.PropertyDisplayNameMap(propName) = propInfo.DisplayName;
                end

                % TODO: Remove Description, which is replaced with DisplayName
                if isfield(propInfo, "Description")
                    % Set the Description, which is used as the label to show in
                    % the inspector
                    this.PropertyDisplayNameMap(propName) = propInfo.Description;                    
                end
                
                if isfield(propInfo, "Tooltip")
                    % Set the DetailedDescription, which is used as the tooltip
                    % to show in the inspector
                    this.PropertyTooltipMap(propName) = propInfo.Tooltip;
                end

                % TODO: Remove DetailedDescription, which is replaced with
                % Tooltip
                if isfield(propInfo, "DetailedDescription")
                    % Set the DetailedDescription, which is used as the tooltip
                    % to show in the inspector
                    this.PropertyTooltipMap(propName) = propInfo.DetailedDescription;
                end
                
                if isfield(propInfo, "Value")
                    % Set the value of the dynamic property
                    this.(propName) = propInfo.Value;
                    value = propInfo.Value;
                else
                    value = [];
                end
                
                if isfield(propInfo, "GetMethod")
                    % Set the GetMethod of the dynamic property
                    p.GetMethod = propInfo.GetMethod;
                end
                
                if isfield(propInfo, "SetMethod")
                    % Set the SetMethod of the dynamic property
                    p.SetMethod = propInfo.SetMethod;
                end
                
                if isfield(propInfo, "Access")
                    % Set the SetAccess of the dynamic property.  It is assumed
                    % that the GetAccess is public, or there would be no need to
                    % add the dynamic property.
                    p.SetAccess = propInfo.Access;
                end
                
                this.notifyPostPropAdd(propName, value);
            end
        end
        
        function notifyPostPropAdd(this, propName, value)
            % Called to notify of a property being added
            
            arguments
                this
                propName string
                value
            end
            
            if isKey(this.ObjRenderedData, propName)
                try
                    % Remove any cached values that may exist for this property
                    % name (if for example, it is added, removed, and re-added)
                    remove(this.ObjRenderedData, propName);
                    remove(this.ObjectViewMap, propName);
                catch
                end
            end
            
            % Notify using PostPropertyAdded
            e = internal.matlab.variableeditor.PropertyChangeEventData;
            e.Properties = propName;
            e.Values = value;
            this.notify("PostPropertyAdded", e);
        end

        function notifyMetadataChange(this, propName)
            % Called to notify of a property's metadata changing.  Typically
            % this is the SetAccess value.
            
            arguments
                this
                propName string
            end

            props = findprop(this, propName);
            if isempty(this.MetaDataChangedProps)
                this.MetaDataChangedProps = containers.Map;
            end

            propsStruct = matlab.internal.datatoolsservices.createStructForObject(props);
            if isKey(this.MetaDataChangedProps, propName)
                previousPropsStruct = this.MetaDataChangedProps(propName);
                if isequal(propsStruct, previousPropsStruct)
                    return
                end
            end
            this.MetaDataChangedProps(propName) = propsStruct;
            
            if isKey(this.ObjRenderedData, propName)
                try
                    % Remove any cached values that may exist for this property
                    % name (if for example, it is added, removed, and re-added)
                    remove(this.ObjRenderedData, propName);
                    remove(this.ObjectViewMap, propName);
                catch
                end
            end
            
            % Notify using PropertyMetadataChanged
            e = internal.matlab.variableeditor.PropertyChangeEventData;
            e.Properties = propName;
            e.Values = propsStruct;
            this.notify("PropertyMetadataChanged", e);
        end
        
        function notifyPropChange(this, propName, value)
            % Called to notify of a property being changed
            
            arguments
                this
                propName string
                value
            end

            userRichEditorUI = this.getRichEditorUI(propName);
            if ~isempty(userRichEditorUI)
                % If there is a UserRichEditorUI for this property, take the
                % extra step to propagate the new value to it, since the
                % InspectorProxyMixin is the link between the object and the UI.
                if isa(value, "internal.matlab.editorconverters.datatype.UserRichEditorUIType")
                    userRichEditorUI.setValue(value.Value)
                end
            end

            e = internal.matlab.variableeditor.PropertyChangeEventData;
            e.Properties = propName;
            e.Values = value;
            this.notify("PropertyChanged", e);
        end
    end
end
