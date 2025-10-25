 classdef DefaultInspectorProxyMixin < ...
        internal.matlab.inspector.InspectorProxyMixin
    
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % This class is used by the Inspector when inspecting an object, if the
    % object doesn't already inherit from the InspectorProxyMixin.  It
    % sets up the Proxy Mixin on the fly based on the public properties of
    % the original object.  This class handles array of objects as well.
    
    % Copyright 2015-2023 The MathWorks, Inc.
    
    properties(Hidden = true)
        PropertiesAdded = {};
    end
    
    methods
        % Create a new InspectorProxyMixin instance.
        function this = DefaultInspectorProxyMixin(OriginalObjects, ...
                multiplePropertyCombinationMode, ...
                multipleValueCombinationMode)
            
            this@internal.matlab.inspector.InspectorProxyMixin(...
                OriginalObjects);
            this.OriginalObjects = OriginalObjects;
            
            % Setup MultiplePropertyCombinationMode
            if nargin < 2 || isempty(multiplePropertyCombinationMode)
                this.MultiplePropertyCombinationMode = ...
                    internal.matlab.inspector.MultiplePropertyCombinationMode.getDefault;
            else
                this.MultiplePropertyCombinationMode = ...
                    internal.matlab.inspector.MultiplePropertyCombinationMode.getValidMultiPropComboMode(...
                    multiplePropertyCombinationMode);
            end
            
            % Setup MultipleValueCombinationMode
            if nargin < 3 || isempty(multipleValueCombinationMode)
                this.MultipleValueCombinationMode = ...
                    internal.matlab.inspector.MultipleValueCombinationMode.getDefault;
            else
                this.MultipleValueCombinationMode = ...
                    internal.matlab.inspector.MultipleValueCombinationMode.getValidMultiValueComboMode(...
                    multipleValueCombinationMode);
            end
            
            % Get the property list for the objects, taking into account
            % the multi-property combination mode.  This returns a list of
            % only properties which have GetAccess = public, and are not
            % hidden.
            propertyList = this.getPropertyListForMode(OriginalObjects, ...
                this.MultiplePropertyCombinationMode);
            
            % Create properties on this class for each of the original
            % object's unique properties.
            for j=1:length(OriginalObjects)
                o = internal.matlab.inspector.InspectorProxyMixin.getObjectAtIndex(...
                    OriginalObjects, j);

                m = metaclass(o);
                
                if j>1
                    % The first PreviousData struct was already created by
                    % the InspectorProxyMixin constructor
                    s = warning('off', 'all');
                    this.PreviousData{j} = this.CreateStructFcn(o);
                    warning(s);
                end
                
                metaclassProperties = m.PropertyList;
                metaclassPropNames = {metaclassProperties.Name};
                classProperties = properties(o);
                for i = 1:length(propertyList)
                    idx = strcmp(metaclassPropNames, propertyList{i});
                    if any(idx)
                        % Does this property actually exist in the metadata
                        % for the class?  Prefer to use this, as it has the
                        % other property data (description, type, etc...)
                        prop = metaclassProperties(idx);
                        propName = prop.Name;
                    elseif ismember(propertyList{i}, classProperties)
                        % Some classes use some trickery to have
                        % 'properties'.  Continue, but it won't have all of
                        % the other property data.
                        prop = [];
                        propName = propertyList{i};
                    else
                        % This property isn't defined for this object (this
                        % can happen in the case of arrays of objects)
                        continue;
                    end

                    if ~isvarname(propName)
                        % Ignore any properties which are not valid property
                        % names.  (This can happen by inspecting objects not
                        % constructed in MATLAB directly)
                        continue;
                    end
                    
                    if isempty(findprop(this, propName))
                        % This is the first time we've encountered this
                        % property, add it to this object
                        d = addprop(this, propName);
                        this.PropertiesAdded = [this.PropertiesAdded; propName];
                        
                        % Also add an internal property (with suffix _PI)
                        % to help coordinate changes between the proxy and
                        % the original object
                        internalProp = addprop(this, this.getInternalPropName(propName));
                        internalProp.Hidden = true;
                        
                        try
                            % Set value to the initial value from the
                            % object.  Don't need to set get/set methods on
                            % the property - since these are properties of
                            % this mixin object directly.
                            this.(propName) = o.(propName);

                            
                            % Also set the initial value of the internal
                            % property, and add get/set methods for it
                            this.(this.getInternalPropName(propName)) = o.(propName);
                            
                            if iscategorical(o.(propName))
                                % Save list of categorical properties for
                                % comparison later, to check when categories
                                % are added or removed
                                this.CategoricalProperties{end+1} = propName;
                            end
                        catch
                            % Typically this won't fail, but it can sometimes with
                            % dependent properties that become invalid (for
                            % example, property d is determined by a+b, but b is a
                            % matrix and b is a char array).  Set to empty in this
                            % case.
                            this.(propName) = [];
                            this.(this.getInternalPropName(propName)) = [];
                        end

                        d.SetMethod = @(this, newValue) ...
                            this.setOriginalPropValue(...
                            propName, newValue);
                        d.GetMethod = @(this) this.(this.getInternalPropName(propName));

                        if ~isempty(prop)                            
                            % d.Type = prop.Type;  This is not allowed by
                            % MCOS Store in a map instead
                            % Now the map contains Type and Validation two
                            % kinds of data
                            this.PropertyTypeMap(propName) = internal.matlab.inspector.Utils.getProp(prop);                        
                            this.PropertyValidationMap(propName) = internal.matlab.inspector.Utils.getPropValidationStruct(prop);

                            if ischar(prop.SetAccess) || isstring(prop.SetAccess)
                                % Also retain the SetAccess (so that read-only
                                % properties remain as such)
                                d.SetAccess = prop.SetAccess;
                            else
                                % You can't set the 'SetAccess' of dynamic
                                % properties to friend classes. Consider it
                                % private from the inspectors point of view
                                d.SetAccess = 'private';
                            end
                        else
                            this.PropertyTypeMap(propName) = class(o.(propName));
                            this.PropertyValidationMap(propName) = internal.matlab.inspector.Utils.getPropValidationStruct([]);
                        end
                        d.SetObservable = true;
                        d.GetObservable = true;
                    elseif ~isprop(this, this.getInternalPropName(propName))
                        internalProp = addprop(this, this.getInternalPropName(propName));
                        internalProp.Hidden = true;
                        this.(this.getInternalPropName(propName)) = o.(propName);
                        this.PropertiesAdded = [this.PropertiesAdded; propName];
                    else
                        % For properties which exist on multiple objects,
                        % use the multipleValueCombinationMode setting to
                        % determine what value to store
                        this.InternalPropertySet = true;
                        this.(this.getInternalPropName(propName)) = ...
                            internal.matlab.inspector.InspectorProxyMixin.getCombinedValue(...
                            this.(propName), o.(propName), ...
                            this.MultipleValueCombinationMode);
                        this.InternalPropertySet = false;
                    end
                    
                    if ~isempty(prop) && prop.SetObservable
                        % Create a listener for observable properties
                        this.PropChangedListeners{...
                            length(this.PropChangedListeners)+1,1} = ...
                            event.proplistener(o, prop, 'PostSet', ...
                            @this.multiObjPropChangedCallback);
                    end
                end
            end
        end
        
        % Override fieldnames to return the list of properties which were
        % added - this assures that the order is as expected.
        function f = fieldnames(this)
            f = this.PropertiesAdded;
        end
        
        % Override properties to return the list of properties which were
        % added - this assures that the order is as expected.
        function f = properties(this)
            f = this.PropertiesAdded;
        end
        
        function multiObjPropChangedCallback(this, es, ~)
            propName = es.Name;
            this.InternalPropertySet = true;
            this.updatePropertyForChange(propName);
            this.InternalPropertySet = false;
        end
        
        function updatePropertyForChange(this, propName)
            % Set the value on the mixin object for the value which was set
            % Need to recompare values for all properties, and take into
            % account the Multiple Value Combination Mode.
            
            % This will be reinitialized with all of the values, based on
            % the multiple values combination mode
            tempValue = [];
            
            for i = 1:length(this.OriginalObjects)
                if length(this.OriginalObjects) == 1
                    o = this.OriginalObjects;
                else
                    o = this.OriginalObjects(i);
                end
                
                if ~isa(o, 'handle') || (isa(o, 'handle') && isvalid(o))
                    if this.isPropertyOfObject(o, propName)
                        if isempty(this.(propName))
                            tempValue = o.(propName);
                        else
                            tempValue = ...
                                internal.matlab.inspector.InspectorProxyMixin.getCombinedValue(...
                                tempValue, o.(propName), ...
                                this.MultipleValueCombinationMode);
                        end
                    end
                end
            end
            
            % Only set the actual property once, so any listeners will get
            % the accurate value at the end
            this.(propName) = tempValue;
            
            % Does a property inspector internal property exist?  If
            % so, set this value as well
            if isprop(this, this.getInternalPropName(propName))
                this.(this.getInternalPropName(propName)) = tempValue;
            end
        end
        
        % Returns the property value.  It first tries to access the value
        % directly.  If the result is empty, it checks to see if the
        % OriginalObjects has the property value set.
        function val = getPropertyValue(this, propertyName)
            try
                % Try to access the property directly
                val = this.(propertyName);
            catch
                val = [];
            end
        end
        
        % set the property value
        function status = setPropertyValue(this, varargin)
            status = '';
            propertyName = varargin{1};
            value = varargin{2};
            if nargin > 3
                % Required for value objects
                displayValue = varargin{3};
                varName = varargin{4};
            end

            % Set the property value on all objects which contain that
            % property
            isAnyProperty = false;
            this.InternalPropertySet = true;
            for idx = 1:length(this.OriginalObjects)
                if length(this.OriginalObjects) == 1
                    obj = this.OriginalObjects;
                else
                    obj = this.OriginalObjects(idx);
                end
                isHandleObj = isa(obj, 'handle');
                
                % Check to make sure this property is a property of this
                % object in the array, and that its not read-only, and make
                % sure the object is valid if its a handle object.
                [isProperty, readOnly] = this.isPropertyOfObject(...
                    obj, propertyName);
                if isProperty && ~readOnly && ...
                    ((isHandleObj && isvalid(obj)) || ~isHandleObj)
                    if isHandleObj
                        if iscategorical(obj.(propertyName)) && ...
                                isscalar(obj.(propertyName))
                            % Need to assign scalar categorical by index,
                            % otherwise it will change the type to char
                            obj.(propertyName)(1) = value;
                        else
                            obj.(propertyName) = value;
                        end
                        isAnyProperty = true;
                    else
                        this.setValueObjectProperty(propertyName, ...
                            displayValue, varName);
                        try
                            this.OriginalObjects(idx).(propertyName) = value;
                        catch
                            if length(this.OriginalObjects) == 1
                                % Some objects fail on indexing like above,
                                % so retry. Let this fail and throw the
                                % exception -- it will be caught and the
                                % error will be displayed.
                                this.OriginalObjects.(propertyName) = value;
                            end
                        end
                        this.(propertyName) = value;
                        isAnyProperty = true;
                    end
                end
            end
            
            if isAnyProperty
                this.InternalPropertySet = true;
                % Update the current value for this object, based on the
                % Multiple Object Value Combination Mode.
                this.updatePropertyForChange(propertyName)
            end

            this.InternalPropertySet = false;
        end
        
        function setValueObjectProperty(this, propertyName, ...
                displayValue, varName)
            evalStr = sprintf('%s.%s = %s;', varName, ...
                propertyName, displayValue);
            
            if ischar(this.Workspace)
                internal.matlab.datatoolsservices.executeCmd(evalStr);
            end
        end
    end
    
    methods (Access = protected)
        function propertyAdded = addPropertyToProxy(this, propertyName)
            % Called to see if a property needs to be added to the proxy
            % object (for when dynamic properties are added to the original
            % object).
            propertyAdded = addPropertyToProxy@internal.matlab.inspector.InspectorProxyMixin(...
                this, propertyName);
            if propertyAdded
                this.PropertiesAdded = [this.PropertiesAdded; propertyName];
            end
        end
    end
    
    methods (Access = private)
        function [isProperty, readOnly] = isPropertyOfObject(~, obj, ...
                propertyName)
            
            % Returns true if the propertyName is a property of the given
            % object, obj.  If possible, also returns whether the property
            % is read-only or not.
            readOnly = false;
            
            if isprop(obj, propertyName)
                isProperty = true;
                
                if ismethod(obj, 'findprop')
                    prop = findprop(obj, propertyName);
                else
                    % If findprop is not defined, try to find the property
                    % in the metaclass PropertyList
                    m = metaclass(obj);
                    prop = findobj(m.PropertyList, 'Name', propertyName);
                end
                
                if ~isempty(prop)
                    readOnly = ~strcmp(prop.SetAccess, 'public');
                end
            else
                % Some objects redefine their properties (like timer), so
                % need to handle this case as well
                props = properties(obj);
                isProperty =  ismember(propertyName, props);
            end
        end
    end
end
