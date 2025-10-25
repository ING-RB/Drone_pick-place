classdef UIComponentProxy < internal.matlab.inspector.InspectorProxyMixin
    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % This class is a wrapper for the UIComponentProxy classes that are used for
    % UIComponents.  Its purpose is to add in properties and/or change the type
    % of properties that are defined in the AppDesigner proxy view for the
    % components.
    %
    % For example, AppDesigner may not show certain properties like Parent or
    % Children, or may define the types of properties differently to force a
    % certain editor in the AppDesigner inspector.  But because these views are
    % reused in the Desktop Property Inspector, this class adds in the missing
    % properties from the view, or sets up the type correctly.
    
    % Copyright 2020-2024 The MathWorks, Inc.

    properties(Hidden = true)
        % The InspectorProxyMixin class that this is the wrapper for
        ProxyClass
        
        % The properties added or modified by the UIComponentProxy class
        AddedProps string = strings(0);

        RemovedProps string = strings(0);
        
        ObjDelListener = [];
    end
    
    properties (Constant)
        % These are the set of properties that this class considers adding
        % and/or updating the type
        PropsToAdd = ["ContextMenu", "Parent", "Children", "Colormap", "NextPlot", "Type"];

        PLOTTING_GROUP = "MATLAB:ui:propertygroups:PlottingGroup";
        PARENT_CHILD_GROUP = "MATLAB:ui:propertygroups:ParentChildGroup";
        IDENTIFIERS_GROUP = "MATLAB:ui:propertygroups:IdentifiersGroup";

        PropsToAddGroups = [ ...
            internal.matlab.inspector.UIComponentProxy.PARENT_CHILD_GROUP, ...
            internal.matlab.inspector.UIComponentProxy.PARENT_CHILD_GROUP, ...
            internal.matlab.inspector.UIComponentProxy.PARENT_CHILD_GROUP, ...
            internal.matlab.inspector.UIComponentProxy.PLOTTING_GROUP, ...
            internal.matlab.inspector.UIComponentProxy.PLOTTING_GROUP, ...
            internal.matlab.inspector.UIComponentProxy.IDENTIFIERS_GROUP, ...
        ];
    end
    
    methods
        function this = UIComponentProxy(proxy)
            % Create a UIComponentProxy for the proxy class argument.
            
            % Need to call the superclass constructor, but pass in [], because
            % we don't want a proxy created for this class' properties.
            this = this@internal.matlab.inspector.InspectorProxyMixin([]);
            this.ProxyClass = proxy;
            this.OriginalObjects = proxy.OriginalObjects;
            this.PropertyTypeMap = proxy.PropertyTypeMap;
            
            % Get the groups (and properties) from the ProxyClass
            groups = this.ProxyClass.getGroups();
            groupedProps = [groups.PropertyList];
            
            % For each property we consider adding or changing the type of
            for idx = 1:length(this.PropsToAdd)
                propName = this.PropsToAdd(idx);
                
                % If this property is a property of the original object
                if isprop(this.ProxyClass.OriginalObjects, propName)
                    this.AddedProps(end + 1) = propName;
                    
                    % If this isn't a property of the proxy class, add it in
                    % (for example, "Parent" may not be in the proxy, but is a
                    % property of the original object).
                    if ~isprop(this.ProxyClass, propName)
                        addprop(this.ProxyClass, propName);
                        this.ProxyClass.(propName) = this.ProxyClass.OriginalObjects.(propName);
                    end
                    
                    % Add the property to this class, and set its type
                    % (currently all supported are 'Graphics' objects
                    addprop(this, propName);

                    p = findprop(this.ProxyClass.OriginalObjects(1), propName);
                    this.PropertyTypeMap(propName) = p.Type;
                    this.(propName) = this.ProxyClass.OriginalObjects.(propName);
                    
                    if ~any(strcmp(groupedProps, propName))
                        % If the property isn't in a group, add it in.
                        % (Currently all properties are added to the ParentChild
                        % group)
                        group = groups(strcmp({groups.Title}, this.PropsToAddGroups(idx)));
                        group.addProperties(char(propName));
                    end
                end
            end
            
            % Need to assign getters/setters to the proxy class properties, so
            % that calling UIComponentProxy.<propertyName> works
            props = properties(this.ProxyClass);
            m = metaclass(this);
            allProps = string({m.PropertyList.Name});
            allProps = [allProps internal.matlab.inspector.UIComponentProxy.PropsToAdd];
            for idx = 1:length(props)
                propName = props{idx};
                if ~any(allProps == propName)
                    if startsWith(propName, "AD_")
                        this.RemovedProps(end + 1) = propName;
                    else
                        p = addprop(this, propName);
                        p.GetMethod = @(t) getPropertyValue(t, propName);
                        p.SetMethod = @(t,v) setPropertyValue(t, propName, v);
                    end
                end
            end
            
            % Listen for the original proxy being destroyed
            this.ObjDelListener = event.listener(...
                this.ProxyClass, 'ObjectBeingDestroyed', ...
                @this.deletionCB);
            
            this.PropAddedListeners{end+1} = event.listener(this.ProxyClass, ...
                "PropertyAdded", @this.proxyPropAddedCallback);
            this.PropRemovedListeners{end+1} = event.listener(this.ProxyClass, ...
                "PropertyRemoved", @this.proxyPropRemovedCallback);
        end
        
        function delete(this)
            % Delete the object deletion listener, and delete the proxy class
            % when this class is deleted
            delete(this.ObjDelListener);
            delete(this.ProxyClass);
        end
        
        function deletionCB(this, varargin)
            % When the original proxy class is deleted, delete this proxy class
            delete(this);
        end
        
        %
        %
        % The remaining functions are public functions overridden from the
        % InspectorProxyMixin class.  They are needed so that calls on this
        % class, the UIComponentProxy, are pass-throughs to the this.ProxyClass
        % methods.  The only exceptions are some functions dealing with specific
        % properties, in which case we need to make sure the right
        % representation of the property is used for any properties we may have
        % added.
        %
        %
        
        function propChangedCallback(this, ed, es)
            this.ProxyClass.propChangedCallback(ed, es)
        end
        
        function val = getPropertyValue(this, propertyName)
            if any(strcmp(this.AddedProps, propertyName))
                val = this.(propertyName);
            else
                val = this.ProxyClass.getPropertyValue(propertyName);
            end
        end
        
        function val = get(this, propertyName)
            if any(contains(this.AddedProps, propertyName))
                val = this.(propertyName);
            else
                val = this.ProxyClass.get(propertyName);
            end
        end
        
        function status = setPropertyValueInternal(this, varargin)
            status = this.ProxyClass.setPropertyValue(varargin{:});
        end
        
        function status = setSinglePropertyValueInternal(this, propertyName, idx, value)
            if any(contains(this.AddedProps, propertyName))
                % Need to set the property on the actual object, and not the
                % proxy object, because it may be a different type
                status = [];
                this.(propertyName) = value;
                this.ProxyClass.OriginalObjects.(propertyName) = value;
            else
                status = this.ProxyClass.setSinglePropertyValueInternal(propertyName, idx, value);
            end
        end
        
        function revertPropertyOnFailure(this, prop, propertyName, origValue)
            this.ProxyClass.revertPropertyOnFailure(prop, propertyName, origValue);
        end
        
        function status = setPropertyValue(this, varargin)
            status = this.ProxyClass.setPropertyValue(varargin{:});
        end
        
        function [status, prop] = setPropValueOnProxyAndObject(this, ...
                obj, propertyName, value, origPropValue, varargin)
            [status, prop] = this.ProxyClass.setPropValueOnProxyAndObject(obj, propertyName, value, origPropValue, varargin{:});
        end
        
        function status = setOriginalPropValue(this, propertyName, value, varargin)
            status = this.ProxyClass.setOriginalPropValue(propertyName, value, varargin{:});
        end
        
        function updateInternalPropValue(this, propertyName, value, setMethod)
            this.ProxyClass.updateInternalPropValue(propertyName, value, setMethod);
        end
        
        function set(this, propertyName, value)
            this.ProxyClass.set(propertyName, value);
        end
        
        function group = createGroup(this, groupID, groupTitle, groupDescription)
            group = this.ProxyClass.createGroup(groupID, groupTitle, groupDescription);
        end
        
        function groups = getGroups(this)
            groups = this.ProxyClass.getGroups;
        end
        
        function expandAllGroups(this)
            this.ProxyClass.expandAllGroups();
        end
        
        function setWorkspace(this, workspace)
            this.ProxyClass.setWorkspace(workspace);
        end
        
        function [changed, changedProperties, changedProxyProperties] = OrigObjectChange(this)
            [changed, changedProperties, changedProxyProperties] = this.ProxyClass.OrigObjectChange();
        end
        
        function reinitializeFromOrigObject(this, changedProperties, changedProxyProperties)
            changedOverriden = contains(changedProperties, this.AddedProps);
            if any(changedOverriden)
                % Special handling for any properties added by the
                % UIComponentProxy class
                changedProperties = changedProperties(~changedOverriden);
                for idx = 1:length(this.AddedProps)
                    propName = this.AddedProps(idx);
                    this.(propName) = this.ProxyClass.OriginalObjects.(propName);
                end
            end
            this.ProxyClass.reinitializeFromOrigObject(changedProperties, changedProxyProperties);
        end
        
        function obj = getOriginalObjectAtIndex(this, idx)
            obj = this.ProxyClass.getOriginalObjectAtIndex(idx);
        end
        
        function f = properties(this)
            f = properties(this.ProxyClass);
            f = cellstr(setdiff(f, this.RemovedProps));
        end
        
        function f = fieldnames(this)
            f = fieldnames(this.ProxyClass);
            f = cellstr(setdiff(f, this.RemovedProps));
        end
        
        function prop = findprop(this, propName)
            prop = findprop(this.ProxyClass, propName);
        end

        function displayName = getPropertyDisplayName(this, propertyName)
            arguments
                this
                propertyName (1,1) string
            end

            displayName = this.ProxyClass.getPropertyDisplayName(propertyName);
        end

        function tooltip = getPropertyTooltip(this, propertyName)
            arguments
                this
                propertyName (1,1) string
            end

            tooltip = this.ProxyClass.getPropertyTooltip(propertyName);
        end
    end
    
    methods(Access = protected)
        function proxyPropAddedCallback(this, ~, ed)
            this.propertyAddedToProxy(ed.PropertyName);
        end
        
        function proxyPropRemovedCallback(this, ~, ed)
            this.propertyRemovedFromProxy(ed.PropertyName);
        end
        
        function propertyAdded = propertyAddedToProxy(this, propertyName)
            propertyAdded = false;
            try
                p = addprop(this, propertyName);
                p.GetMethod = @(t) getPropertyValue(t, propertyName);
                p.SetMethod = @(t,v) setPropertyValue(t, propertyName, v);
                propertyAdded = true;
            catch
                % Ignore exceptions
            end
        end
        
        function propertyRemoved = propertyRemovedFromProxy(this, propertyName)
            propertyRemoved = false;
            if isprop(this, propertyName)
                p = findprop(this, propertyName);
                delete(p);
                propertyRemoved = true;
            end
        end
    end
end
