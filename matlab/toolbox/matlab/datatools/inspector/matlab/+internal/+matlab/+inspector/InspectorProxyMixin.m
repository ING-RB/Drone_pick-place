classdef (Abstract) InspectorProxyMixin < ...
        dynamicprops & matlab.mixin.CustomDisplay & ...
        matlab.graphics.mixin.internal.GraphicsDataTypeContainer

    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % Inspector Proxy Mixin class.  Classes which wish to provide a custom
    % view in the Property Inspector may extend this mixin, and define the
    % properties that should be displayed.  It acts as a proxy between the
    % original object and the inspector classes which introspect the
    % object.

    % Copyright 2015-2025 The MathWorks, Inc.

    properties(Hidden = true)
        % Keep a reference to the original object
        OriginalObjects;

        % The list of defined groups
        GroupList;

        % Property change listeners created
        PropChangedListeners = {};

        % Track the property types in a map, since they cannot be set on a
        % dynamic object
        PropertyTypeMap;
        PropertyValidationMap;

        NonOrigProperties = {};

        Workspace;

        PreviousData = {};

        % Specifies how to handle properties when multiple objects are
        % selected
        MultiplePropertyCombinationMode internal.matlab.inspector.MultiplePropertyCombinationMode = ...
            internal.matlab.inspector.MultiplePropertyCombinationMode.FIRST;

        % Specifies how to handle values when multiple objects are selected
        MultipleValueCombinationMode internal.matlab.inspector.MultipleValueCombinationMode = ...
            internal.matlab.inspector.MultipleValueCombinationMode.LAST

        InternalPropertySet = false;

        CategoricalProperties = {};

        AllGroupsExpanded = false;

        DeletionListeners = {};
        PropRemovedListeners = {};
        PropAddedListeners = {};

        % This is used to create a list of properties which we need to assure
        % are sent to the server as a property change.  Sometimes quick updates
        % in succession can get lost in the periodic comparisons done by the
        % functions called by the timer, and we need to assure the changes get
        % propagated.
        ForcePropertyChange = strings(0);

        % The following are used to store data used for rendering the object.
        % They are filled in when the object is inspected, and reused when the
        % object is inspected again.
        CurrRenderedData cell;
        CurrRenderedGroupData cell;
        OrigObjSetAccessNames string;
        OrigObjectPropNames string;
        ObjRenderedData containers.Map
        ObjectViewMap containers.Map;

        % Whether read-only properties will be shown as labels, or as their
        % default display (typically as disabled text fields)
        UseLabelForReadOnly (1,1) logical = false;

        SupportsPopupWindowEditor (1,1) logical = true;

        ShowInspectorToolstrip (1,1) logical = true;

        CheckForRecursiveChildren (1,1) logical = true;

        % Whether to show the class name in the object browser hierarchy or not.
        % When not shown, just the property name is displayed.  Default is true,
        % to show the class name along with the property name.
        ShowClassInHierarchy logical = true;

        % Whether to use the variable name as the top of the object browser
        % hierarchy or not.  Default is false, so that the top of the hierarchy
        % is the class name.
        UseVarNameAsHierarchyTop logical = false;

        % Function called to create a struct for a given object, which is used
        % for comparison of objects.  Can be overridden for additional
        % functionality.
        CreateStructFcn function_handle = @matlab.internal.datatoolsservices.createStructForObject;

        % Mapping between Property Name and the displayed property name
        PropertyDisplayNameMap containers.Map;

        % Mapping between the Property Name and the tooltip for that property
        PropertyTooltipMap containers.Map;

        % Mapping between a Property Name and a UserRichEditorUI class which
        % will be used for editing that property as a popup rich editor
        UserRichEditorUIMap containers.Map;

        % Allow clients to specify properties to skip in the object browser
        % hierarchy.  They still show up in the inspector, but are not shown in
        % the object browser so there is no way to drill down into them.
        PropsToSkipInHierarchy string = strings(0);

        % Store the help search term.  Typically this is the class name, but
        % can differ for objects which appear in different contexts (for
        % example, graphics objects in Java figures vs uifigures may have
        % different property values)
        HelpSearchTerm string = strings(0);

        PropsForHoverOver string = strings(0);
        PropsForValueChanging string = strings(0);
    end

    properties(Constant, Access = private)
        UNTITLED_GROUP_NAME = '_UNTITLEDGROUP';
        LIMITING_PROPS = "Toolbar";
    end

    events
        PropertiesUpdated
    end

    methods
        % Create a new InspectorProxyMixin instance.
        function this = InspectorProxyMixin(OriginalObject, ...
                multiplePropertyCombinationMode, ...
                multipleValueCombinationMode)

            this.OriginalObjects = OriginalObject;

            % Initialize these when an InspectorProxyMixin is created, they will
            % be filled by the View Model when the object is viewed in the
            % inspector.
            this.CurrRenderedData = {};
            this.CurrRenderedGroupData = {};
            this.OrigObjSetAccessNames = strings(0);
            this.OrigObjectPropNames = strings(0);
            this.ObjRenderedData = containers.Map;
            this.ObjectViewMap = containers.Map;
            this.UserRichEditorUIMap = containers.Map;

            this.PropertyDisplayNameMap = containers.Map;
            this.PropertyTooltipMap = containers.Map;

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

            this.PropertyTypeMap = containers.Map;
            this.PropertyValidationMap = containers.Map;
            m = metaclass(this);
            p = m.PropertyList;

            % Create properties on this class for each of the original
            % object's unique properties.
            for j=1:length(OriginalObject)
                o = this.getOriginalObjectAtIndex(j);

                if isa(OriginalObject, 'handle')
                    this.DeletionListeners{end+1} = event.listener(o, ...
                        'ObjectBeingDestroyed', @this.deletionCallback);

                    if isa(OriginalObject, "dynamicprops")
                        % Add listeners for dynamic properties being added or
                        % removed
                        this.PropAddedListeners{end+1} = event.listener(o, ...
                            "PropertyAdded", @this.propAddedCallback);
                        this.PropRemovedListeners{end+1} = event.listener(o, ...
                            "PropertyRemoved", @this.propRemovedCallback);
                    end
                end

                lerr = lasterror; %#ok<*LERR>
                for i = 1:length(p)
                    prop = p(i);

                    % For each property not defined by the one of the inspector
                    % classes themselves
                    if ~endsWith(prop.DefiningClass.Name, "InspectorProxyMixin")
                        if j == 1
                            internalProp = addprop(this, this.getInternalPropName(prop.Name));
                            internalProp.Hidden = true;

                            if isprop(o, prop.Name) && ~any(strcmp(prop.Name, this.LIMITING_PROPS))
                                try
                                    % Assign the initial value of the property to that
                                    % of the original object, if they are the same
                                    if isempty(prop.GetMethod)
                                        if isempty(prop.SetMethod)
                                            origObjValue = this.OriginalObjects.(prop.Name);
                                            if ischar(origObjValue) && internal.matlab.inspector.Utils.isEnumeration(prop) %~isempty(enumeration(this.(prop.Name)))
                                                try
                                                    % Although the property we got
                                                    % from the original object
                                                    % above is char, the property
                                                    % type is an enumeration, so we
                                                    % should try to convert it.  If
                                                    % it fails, that's ok too, as
                                                    % many of the HG properties
                                                    % accept char values
                                                    origObjValue = eval([internal.matlab.inspector.Utils.getPropDataType(prop) '.' origObjValue]);
                                                catch
                                                end
                                            end

                                            this.(prop.Name) = origObjValue;
                                        end

                                        if strcmp(internal.matlab.inspector.Utils.getPropDataType(prop), 'categorical')
                                            % Save list of categorical properties for
                                            % comparison later, to check when categories
                                            % are added or removed
                                            this.CategoricalProperties{end+1} = prop.Name;
                                        end

                                        this.(this.getInternalPropName(prop.Name)) = origObjValue;
                                    else
                                        internalProp.GetMethod = prop.GetMethod;
                                    end
                                catch
                                    % Its possible the types are different
                                    % (redefining a string as an enumerated value,
                                    % for example).  Don't worry about setting the
                                    % value and assume its done already
                                    internal.matlab.datatoolsservices.logDebug( ...
                                        "pi", "InspectorProxyMixin, caught error setting initial value for: " + prop.Name);
                                end

                                % Assign a PostSet listener to the original
                                % object, so that the values can be kept in sync
                                originalProp = findprop(o, ...
                                    prop.Name);
                                if originalProp.SetObservable
                                    this.PropChangedListeners{...
                                        length(this.PropChangedListeners)+1,1} = ...
                                        event.proplistener(o, ...
                                        originalProp, 'PostSet', ...
                                        @this.propChangedCallback);
                                end

                                if j == 1
                                    if ~isequal(internal.matlab.inspector.Utils.getPropDataType(prop), 'any')
                                        % The mixin class has redefined a property type
                                        % to be more restrictive/different than the
                                        % original type (for example, the original type
                                        % may be text while the new type is an
                                        % enumeration), so use this definition
                                        this.PropertyTypeMap(prop.Name) = internal.matlab.inspector.Utils.getProp(prop);
                                        this.PropertyValidationMap(prop.Name) = internal.matlab.inspector.Utils.getPropValidationStruct(prop);
                                    else
                                        % Otherwise, use the original property's type
                                        % definition
                                        this.PropertyTypeMap(prop.Name) = internal.matlab.inspector.Utils.getProp(originalProp);
                                        this.PropertyValidationMap(prop.Name) = internal.matlab.inspector.Utils.getPropValidationStruct(originalProp);
                                    end
                                end
                            elseif ~prop.Hidden && ~any(strcmp(prop.Name, this.LIMITING_PROPS))
                                this.NonOrigProperties{end+1} = prop.Name;
                                this.PropertyTypeMap(prop.Name) = internal.matlab.inspector.Utils.getProp(prop);
                                this.PropertyValidationMap(prop.Name) = internal.matlab.inspector.Utils.getPropValidationStruct(prop);
                                internalProp.GetMethod = @(this)this.(prop.Name);
                            end
                        else
                            if isprop(o, prop.Name)
                                % For properties which exist on multiple
                                % objects, use the multipleValueCombinationMode
                                % setting to determine what value to store
                                this.InternalPropertySet = true;
                                try
                                    this.(prop.Name) = this.getResolvedValueToApply(...
                                        prop, internal.matlab.inspector.InspectorProxyMixin.getCombinedValue(...
                                        this.(prop.Name), o.(prop.Name), this.MultipleValueCombinationMode));
                                catch
                                    % Ignore any errors from this
                                end
                                this.InternalPropertySet = false;

                                % Assign a PostSet listener to the original
                                % object, so that the values can be kept in sync
                                originalProp = findprop(o, prop.Name);
                                if originalProp.SetObservable
                                    this.PropChangedListeners{end+1,1} = ...
                                        event.proplistener(o, originalProp, 'PostSet', ...
                                        @this.propChangedCallback);
                                end

                            end
                        end
                    end
                end

                % restore lasterror, so the user doesn't see it set by inspecting an object
                lasterror(lerr);
            end

            function localInitPreviousData(this)
                try
                    if isvalid(this)
                        initPreviousData(this);
                    end
                catch
                    % Since this is deferred it is possible that the
                    % inspector closes/etc
                end
            end

            % Initialize the PreviousData struct, which is used once the update
            % timer runs.
            if ~isa(this.OriginalObjects, "internal.matlab.inspector.EmptyObject")
                if internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle
                    localInitPreviousData(this);
                else
                    builtin('_dtcallback', @() localInitPreviousData(this));
                end
            end
        end

        function initPreviousData(this)
            % Initialize the PreviousData struct
            try
                for idx = 1:length(this.OriginalObjects)
                    o = this.getOriginalObjectAtIndex(idx);

                    if isa(o, 'handle')
                        this.PreviousData{idx} = this.CreateStructFcn(o);
                    end
                end
            catch
            end
        end

        function delete(this)
            % Remove any Property Changed listeners which have been added
            if ~isempty(this.PropChangedListeners)
                cellfun(@(x) delete(x), this.PropChangedListeners);
                this.PropChangedListeners = {};
            end

            if ~isempty(this.PropAddedListeners)
                cellfun(@(x) delete(x), this.PropAddedListeners);
            end
            this.PropAddedListeners = {};

            if ~isempty(this.PropRemovedListeners)
                cellfun(@(x) delete(x), this.PropRemovedListeners);
            end
            this.PropRemovedListeners = {};

            if ~isempty(this.DeletionListeners)
                cellfun(@(x) delete(x), this.DeletionListeners);
            end
            this.DeletionListeners = {};

            % Delete any UserRichEditorUI's that have been created
            k = keys(this.UserRichEditorUIMap);
            for idx = 1:length(k)
                richEditor = this.UserRichEditorUIMap(k{idx});

                % Delete the parent divfigure for the rich editor
                richEditorFigure = ancestor(richEditor, "figure");
                delete(richEditorFigure);
            end
            remove(this.UserRichEditorUIMap, keys(this.UserRichEditorUIMap));
        end

        function propChangedCallback(this, ed, es)
            % Handle this event by forwarding the setProperty call to the
            % original object
            try
                propName = ed.Name;
                isInternalPropSet = this.InternalPropertySet;

                changeIdx = -1;
                if length(this.OriginalObjects) > 1
                    changeIdx = find(this.OriginalObjects == es.AffectedObject);
                end

                this.InternalPropertySet = true;
                if changeIdx > 0
                    setSinglePropertyValueInternal(this, propName, changeIdx, ...
                        this.OriginalObjects(changeIdx).(propName));
                else
                    setPropertyValueInternal(this, propName, ...
                        this.OriginalObjects.(propName));
                end
                this.InternalPropertySet = isInternalPropSet;

                if ~this.InternalPropertySet
                    % Force notification of this property change to the server
                    this.ForcePropertyChange(end+1) = propName;
                    this.ForcePropertyChange = unique(this.ForcePropertyChange);
                end
            catch
                % Calling close all after inspecting multiple figures fires
                % this listener unintentionally, which results in error. As
                % a result, one of the object(s) being inspected may be
                % deleted. Make sure the listener does not throw an error.
            end
        end

        % Returns the property value.  It first tries to access the value
        % directly.  If the result is empty, it checks to see if the
        % OriginalObject has the property value set.
        function val = getPropertyValue(this, propertyName)
            try
                % Should be able to access the property directly
                val = this.(propertyName);
            catch e
                rethrow(e);
            end
        end

        % Returns the property value.  Uses the getPropertyValue method to
        % check for direct access, and if not, access through the original
        % object.
        function val = get(this, propertyName)
            val = getPropertyValue(this, propertyName);
        end

        % Set the property value.  This is called when a property change is
        % observed on the original object, so that the proxy object can be
        % similarly updated.  Arguments are:
        %   - Property Name
        %   - Property value.  There should be as many property values as there
        %   are objects.  So for an array of three objects, there will be three
        %   property values.
        function status = setPropertyValueInternal(this, varargin)
            status = '';
            propertyName = varargin{1};
            origValue = this.(propertyName);

            for i = 1:length(this.OriginalObjects)
                if length(this.OriginalObjects) == 1
                    obj = this.OriginalObjects;
                else
                    obj = this.OriginalObjects(i);
                end

                value = varargin{1 + i};
                origPropValue = value;

                % Set the property value
                [status, prop] = this.setPropValueOnProxyAndObject(obj, ...
                    propertyName, value, origPropValue);
                if ~isempty(status)
                    break;
                end
            end

            if ~isempty(status)
                this.revertPropertyOnFailure(prop, propertyName, origValue);
            end
        end

        % Set the property value.  This is called when a property change is
        % observed on a single original object, so that the proxy object can be
        % similarly updated.  Arguments are:
        %   - Property Name
        %   - index of this object in the OriginalObjects array
        %   - Property value.
        function status = setSinglePropertyValueInternal(this, propertyName, ...
                idx, value)
            origValue = this.(propertyName);
            origPropValue = value;

            % Set the property value
            [status, prop] = this.setPropValueOnProxyAndObject(...
                this.OriginalObjects(idx), propertyName, value, origPropValue, idx);

            if ~isempty(status)
                this.revertPropertyOnFailure(prop, propertyName, origValue);
            end
        end

        function revertPropertyOnFailure(this, prop, propertyName, origValue)
            % revert value
            if isempty(prop)
                this.(propertyName) = origValue;
            else
                this.(propertyName) = this.getResolvedValueToApply(prop, origValue);
            end
        end

        % Set the property value.  This is called when setting properties from
        % the inspector UI.  Necessary arguments are:
        %   Property Name - the property name to set
        %   Value - the property value to set
        %
        % Optional arguments to support value objects are:
        %   DisplayValue - the display value of the value to bet set
        %   Variable Name - the Variable Name
        function status = setPropertyValue(this, varargin)
            status = '';
            propertyName = varargin{1};
            value = varargin{2};
            origValue = this.(propertyName);

            for idx = 1:length(this.OriginalObjects)
                if length(this.OriginalObjects) == 1
                    obj = this.OriginalObjects;
                else
                    obj = this.OriginalObjects(idx);
                end

                origPropValue = value;

                % Set the property value
                [status, prop] = this.setPropValueOnProxyAndObject(obj, ...
                    propertyName, value, origPropValue, idx);
                if ~isempty(status)
                    break;
                end

                % Update the cached data with the updated value as well, rather
                % than waiting for the call to OrigObjectChange() to resolve the
                % value when the timer fires.
                if ~isempty(this.PreviousData) && (idx <= length(this.PreviousData)) && isfield(this.PreviousData{idx}, propertyName)
                    this.PreviousData{idx}.(propertyName) = value;
                end
            end

            if ~isempty(status)
                % revert value
                % If the status is not empty, we want this status value to be passed back from the function, and ignore if reverting the value fails.
                try
                    if isempty(prop)
                        this.(propertyName) = origValue;
                    else
                        this.(propertyName) = this.getResolvedValueToApply(prop, origValue);
                    end
                catch
                end
            end
        end

        % Called by setPropertyValue and setPropertyValueInternal to apply the
        % property value to the propertyName of the proxy object, and possibly
        % the original object (if this wasn't an internal property set)
        function [status, prop] = setPropValueOnProxyAndObject(this, ...
                obj, propertyName, value, origPropValue, varargin)

            idx = [];
            if ~isempty(varargin)
                idx = varargin{1};
            end

            % Temporarily change some warnings to errors so that the
            % normal inspector error handling path will be followed.
            w = internal.matlab.inspector.InspectorProxyMixin.disableWarnings(class(obj));
            status = [];

            try
                prop = findprop(this, propertyName);

                % Use the resolved value, which may be an enumeration or
                % class value instead of a string, as the value to apply to
                % the object
                value = this.getResolvedValueToApply(prop, value);

                if hasSetAccess(prop)
                    % Assign the proxy class value of the property to the
                    % new value
                    this.(propertyName) = value;
                end

                % Pass through to the original object if there is no setter
                % and if this isn't an InternalPropertySet
                if isempty(prop.SetMethod) && ~this.InternalPropertySet
                    if ~isempty(idx)
                        status = this.setOriginalPropValue(propertyName, origPropValue, idx);
                    else
                        status = this.setOriginalPropValue(propertyName, origPropValue);
                    end
                end
            catch ex
                status = ex.message;
                prop = [];
            end

            % Revert warning state
            if ~isempty(w)
                warning(w);
            end
        end

        function status = setOriginalPropValue(this, propertyName, value, varargin)
            status = '';
            idx = [];

            if ~isempty(varargin)
                idx = varargin{1};
            end
            try
                if ~this.InternalPropertySet
                    % If we are doing an internal property set (usually on
                    % object creation), then don't set the original
                    % object's values
                    if ~isempty(idx)
                        % A specific index was specified.  Just set this
                        % object's property value.
                        objAtIndex = this.getOriginalObjectAtIndex(idx);
                        if isprop(objAtIndex, propertyName)
                            try
                                objAtIndex.(propertyName) = value;
                            catch ex2
                                if isenum(value)
                                    objAtIndex.(propertyName) = string(value);
                                else
                                    rethrow(ex2);
                                end
                            end

                        end
                    else
                        % Loop through all objects
                        for i = 1:length(this.OriginalObjects)
                            % Don't use isscalar() because some objects override
                            % this, and we really need to check for the length
                            if length(this.OriginalObjects) == 1 %#ok<*ISCL>
                                obj = this.OriginalObjects;
                            else
                                obj = this.OriginalObjects(i);
                            end

                            if isprop(obj, propertyName)
                                obj.(propertyName) = value;
                            end
                        end
                    end
                end
            catch ex
                status = ex.message;
                try
                    if ~ischar(value) && ~isempty(enumeration(this.(propertyName)))
                        % We are applying an enumeration to the property
                        % type, but it may need to be a char value instead.
                        % Retry as a char and clear the error status if
                        % this succeeds.
                        this.OriginalObjects(i).(propertyName) = char(value);
                        status = '';
                    end
                catch
                end
            end
        end

        function updateInternalPropValue(this, propertyName, value, setMethod)
            if nargin<4 || isempty(setMethod)
                setMethod = @this.setOriginalPropValue;
            end

            try
                % Does a property inspector internal property exist?  If
                % so, set this value as well
                if isprop(this, this.getInternalPropName(propertyName))
                    this.(this.getInternalPropName(propertyName)) = value;
                end

                setMethod(this, propertyName, value);
            catch
            end
        end

        function set(this, propertyName, value)
            setPropertyValue(this, propertyName, value);
        end

        % Called to create an InspectorGroup.  Group ID, title, and
        % description must be specified.  Returns an InspectorGroup object,
        % which can have property names added to it.
        function group = createGroup(this, groupID, groupTitle, ...
                groupDescription)
            group = [];
            if ~isempty(this.GroupList)
                % Check to see if the group with the specified groupID has
                % already been created, and if it has, return it.
                idx = strcmp({this.GroupList.GroupID}, groupID);
                if any(idx)
                    group = this.GroupList(idx);
                end
            end

            if isempty(group)
                % Create new group
                group = internal.matlab.inspector.InspectorGroup(...
                    groupID,...
                    groupTitle,...
                    groupDescription);
                if this.AllGroupsExpanded
                    group.Expanded = true;
                end

                % Store all created groups in an array
                if isempty(this.GroupList)
                    this.GroupList = group;
                else
                    this.GroupList = [this.GroupList group];
                end
            end
        end

        % Creates an InspectorGroup, which is set to be an untitled group of
        % properties.  This allows for views with a few properties on top of the
        % groups.
        function group = createUntitledGroup(this)
            % Create the group, like any other group 
            groupID = this.UNTITLED_GROUP_NAME;
            if ~isempty(this.GroupList) 
                idx = length(find(startsWith({this.GroupList.GroupID}, '_UNTITLEDGROUP')));
                if idx > 0
                    groupID = [groupID '_' num2str(idx)];
                end
            end
            group = this.createGroup(groupID, '', '');

            % Assure that it is expanded (otherwise there is no way to make it
            % expanded)
            group.Expanded = true;
        end

        % Return an array of groups which have been created
        function groups = getGroups(this)
            groups = this.GroupList;
        end

        % Sets all groups to be expanded
        function expandAllGroups(this)
            this.AllGroupsExpanded = true;
            for i = 1:length(this.GroupList)
                g = this.GroupList(i);
                g.Expanded = true;
            end
        end

        function setWorkspace(this, workspace)
            this.Workspace = workspace;
        end

        function [changed, changedProperties, changedProxyProperties] = ...
                OrigObjectChange(this)
            % Called to determine if any of the properties of the original
            % objects that this is the proxy for have changed.  Ideally, if
            % all properties are setObservable=true, there would never be a
            % difference.  However, for setObservable=false properties, its
            % possible that they can get out of sync.
            changed = false;
            numPropsChanged = false;
            changedProperties = {};
            changedProxyProperties = {};

            combinedValues = [];
            for i=1:length(this.OriginalObjects)
                obj = this.getOriginalObjectAtIndex(i);

                % Compare against a struct of the original object
                % (necessary for handle objects)
                if ~isa(obj, 'handle') || (isa(obj, 'handle') && isvalid(obj))

                    currObjStruct = this.CreateStructFcn(obj);
                    origObjProps = fieldnames(currObjStruct);
                    if i <= length(this.PreviousData)
                        prevDataProps = fieldnames(this.PreviousData{i});
                        prevDataProps(strcmp(prevDataProps, this.LIMITING_PROPS)) = [];
                    elseif i == 1 && ~isa(obj, "internal.matlab.inspector.EmptyObject")
                        this.PreviousData{i} = this.CreateStructFcn(obj);
                        prevDataProps = fieldnames(this.PreviousData{i});
                    else
                        prevDataProps = [];
                    end

                    if isequal(sort(origObjProps), sort(prevDataProps))
                        % Check to see which specific properties have changed
                        changedIdx = cellfun(@(x) ~isequaln(...
                            currObjStruct.(x), this.PreviousData{i}.(x)), ...
                            origObjProps);
                        if any(changedIdx)

                            currChangedProperties = origObjProps(changedIdx);
                            realChanges = true(size(currChangedProperties));

                            for j = 1:length(currChangedProperties)
                                currProp = currObjStruct.(currChangedProperties{j});
                                prevProp = this.PreviousData{i}.(currChangedProperties{j});
                                try
                                    if isequaln(currProp, (prevProp)')
                                        % This is just a transpose -- don't
                                        % consider it a change
                                        realChanges(j) = false;
                                    elseif ischar(currProp) && ...
                                            isequaln(currProp, char(prevProp))
                                        % If one of the property values is
                                        % char, and the other is an enum, but
                                        % they are the same, then don't
                                        % consider this a real change to the
                                        % property.
                                        realChanges(j) = false;
                                    elseif internal.matlab.inspector.InspectorProxyMixin.isSmallNumericChange(currProp, prevProp)
                                        % These are non-empty numeric values
                                        % and the difference is miniscule
                                        realChanges(j) = false;
                                    end
                                catch
                                    % Ignore these errors... some property
                                    % types may fail on one of these
                                    % conditions, but that's ok -- just
                                    % consider it a real change in value
                                end
                            end

                            currChangedProperties(~realChanges) = [];
                            %                             if isempty(changedProperties)
                            %                                 changed = false;
                            %                             end

                            % Update the list of changed properties
                            changedProperties = unique(vertcat(changedProperties, ...
                                currChangedProperties), 'stable');
                            changed = true;
                        end

                        if ~isempty(this.CategoricalProperties)
                            % Compare the categories for any categorical
                            % variables
                            categoryChanges = cellfun(@(x) ...
                                ~isequal(categories(currObjStruct.(x)), ...
                                categories(this.PreviousData{i}.((x)))), ...
                                this.CategoricalProperties);
                            if any(categoryChanges)
                                % Update the list of changed properties
                                changedProperties = unique(vertcat(changedProperties, ...
                                    this.CategoricalProperties(categoryChanges)), ...
                                    'stable');
                                changed = true;
                            end
                        end

                        % Limit the changed properties to those properties
                        % which exist on the view object itself
                        thisProperties = properties(this);
                        changedProperties = intersect(changedProperties, thisProperties);

                        if isempty(combinedValues)
                            % The first time through the objects, the combined
                            % values is the object's values, since there's only
                            % one object so far
                            combinedValues = currObjStruct;
                        else
                            % The next time through the objects, combine the
                            % values with the previously determined values, if
                            % the previous value exists.  (When inspecting
                            % multiple objects, its possible they have different
                            % properties and the value may not exist)
                            objFields = fieldnames(currObjStruct);
                            for j=1:length(objFields)
                                propToCombine = objFields{j};
                                if ~isfield(combinedValues, propToCombine)
                                    % This property doesn't exist in the
                                    % combined values yet (due to inspecting
                                    % multiple different objects), just take the
                                    % value
                                    combinedValues.(propToCombine) = currObjStruct.(propToCombine);
                                else
                                    % Combine the property values based on the
                                    % current combination mode
                                    combinedValues.(propToCombine) = ...
                                        internal.matlab.inspector.InspectorProxyMixin.getCombinedValue(...
                                        combinedValues.(propToCombine), currObjStruct.(propToCombine), ...
                                        this.MultipleValueCombinationMode);
                                end
                            end
                        end
                    else
                        numPropsChanged = true;
                        changed = true;
                        changedProperties = unique(vertcat(...
                            changedProperties, ...
                            setdiff(origObjProps, prevDataProps)), ...
                            'stable');

                        if length(origObjProps) > length(prevDataProps)
                            % Property was added to the original object,
                            % need to add it to the proxy as well
                            for c = 1:length(changedProperties)
                                this.addPropertyToProxy(changedProperties{c});
                            end
                        else
                            % Property was removed
                        end
                    end
                end

                if changed && ~isempty(this.NonOrigProperties)
                    changedProperties = unique(vertcat(...
                        changedProperties(:), ...
                        this.NonOrigProperties(:)), ...
                        'stable');
                    changedProxyProperties = unique(vertcat(...
                        changedProxyProperties(:), ...
                        this.NonOrigProperties(:)), ...
                        'stable');
                end
            end

            % Only bother looking for real changes if there were any changes at
            % this point
            if changed && ~isempty(combinedValues)
                objFields = changedProperties;
                % Look for real changes, not counting differences between
                % an enumeration and char of the same value or other
                % similarly equal conditions between the proxy's current
                % value and the new combined value.
                changedIdx = false(size(objFields));
                for k = 1:length(objFields)
                    change = false;
                    x = objFields{k};
                    if isprop(this, x) && isfield(combinedValues, x)
                        try
                            thisValue = this.(x);
                            if ~isequaln(combinedValues.(x), thisValue)
                                change = true;

                                if iscell(thisValue) && isequaln(combinedValues.(x), thisValue')
                                    % cell comparison transposed
                                    change = false;
                                elseif ischar(combinedValues.(x)) && isequaln(combinedValues.(x), char(thisValue))
                                    % char vs enum comparison
                                    change = false;
                                elseif isobject(thisValue) && isequal(size(combinedValues.(x)), size(thisValue))
                                    % handle object comparison via size
                                    change = false;
                                elseif isnumeric(thisValue) && internal.matlab.inspector.InspectorProxyMixin.isSmallNumericChange(combinedValues.(x), thisValue)
                                    change = false;
                                end
                            end
                        catch
                            change = false;
                        end
                    end

                    changedIdx(k) = change;
                end
                changedProxyProperties = unique(vertcat(changedProxyProperties, ...
                    objFields(changedIdx)), 'stable');
                changed = true;
            end

            % Limit the list of changed properties to those which are
            % currently displayed
            propertyList = this.getPropertyListForMode(this.OriginalObjects, ...
                this.MultiplePropertyCombinationMode);
            changedProperties = intersect(propertyList, changedProperties);

            % If any proxy properties changed, which are the same as the
            % changed properties, just report the property in the changed
            % property list
            if ~isempty(this.NonOrigProperties)
                changedProxyProperties = intersect(propertyList, changedProxyProperties);
                overlaps = ismember(changedProxyProperties, changedProperties);
                changedProxyProperties(overlaps) = [];
            else
                % There's no need to report any changed proxy properties if the
                % original objects and the proxy objects have the same set. This
                % is only needed for objects which redefine the properties
                changedProxyProperties = [];
            end

            if ~isempty(this.ForcePropertyChange)
                % There are properties which we need to notify the server of a
                % change.  These may differ because they changed very quickly
                % (in between the periodic checks done on a timer)
                if isempty(changedProperties)
                    changedProperties = cellstr(this.ForcePropertyChange);
                elseif ~contains(changedProperties, this.ForcePropertyChange)
                    c = cellstr(this.ForcePropertyChange);
                    changedProperties = unique([changedProperties(:); c(:)]);
                end
                changed = true;

                % Reset the list since we are notifying the server via the
                % return value of this function
                this.ForcePropertyChange = strings(0);
            end

            if isempty(changedProperties) && isempty(changedProxyProperties) && ~numPropsChanged
                changed = false;
            end

        end

        function reinitializeFromOrigObject(this, changedProperties, ...
                changedProxyProperties)
            % Called to reinitialize the properties of the proxy from the
            % original object.  This is necessary because properties which
            % are SetObservable=false, they can get out of sync with the
            % original object.  changeProperties is a list of properties to
            % reinitialize.
            propertyList = this.getPropertyListForMode(this.OriginalObjects, ...
                this.MultiplePropertyCombinationMode);
            propChangedList = unique(union(changedProperties, changedProxyProperties));
            for j=1:length(propChangedList)
                propName = propChangedList{j};

                isProp = false;
                combinedVal = [];

                for i=1:length(this.OriginalObjects)
                    o = this.getOriginalObjectAtIndex(i);

                    % Take the object's property value - it was
                    % updated, but the proxy hasn't been updated
                    % yet
                    try
                        propValue = o.(propName);
                    catch
                        try
                            % Try one more time, to see if calling get() on the
                            % object will work
                            propValue = get(o, propName);
                        catch
                            % Typically this won't fail, but it can
                            % sometimes with dependent properties that
                            % become invalid.  Set to empty in this
                            % case.
                            propValue = [];
                        end
                    end

                    % Make sure the property being reported as changed is
                    % actually one of the properties which we are
                    % currently displaying (also private properties may
                    % show up as changed, which we don't care about)
                    if ismember(propName, propertyList)
                        isProp = true;

                        if isempty(this.OrigObjSetAccessNames) || any(this.OrigObjSetAccessNames == propName) || ...
                                isa(this, "internal.matlab.inspector.NonHandleObjWrapper")

                            if ismember(propName, changedProperties)
                                % Try to resolve the propValue as text into any
                                % enumeration or class types if possible
                                prop = findprop(this, propName);
                                if isempty(prop)
                                    isProp = false;
                                    continue;
                                else
                                    resolvedPropValue = this.getResolvedValueToApply(prop, propValue);
                                    combinedVal = ...
                                        internal.matlab.inspector.InspectorProxyMixin.getCombinedValue(...
                                        combinedVal, resolvedPropValue, ...
                                        this.MultipleValueCombinationMode);

                                    if hasSetAccess(prop) && i == length(this.OriginalObjects)
                                        % For object arrays, only set on the last of the
                                        % original objects, because this is when we have
                                        % the combinedValue properly
                                        this.InternalPropertySet = true;
                                        if length(this.OriginalObjects) == 1
                                            % Use the resolved property value
                                            this.(propName) = resolvedPropValue;
                                        else
                                            try
                                                % we have a set method
                                                this.(propName) = combinedVal;
                                            catch
                                            end
                                        end
                                        this.InternalPropertySet = false;

                                        if isKey(this.UserRichEditorUIMap, propName)
                                            c = this.UserRichEditorUIMap(propName);
                                            c.setValue(resolvedPropValue);
                                        end
                                    end
                                end
                            else
                                % Take the proxy's property value - it must
                                % have changed to be different from the
                                % original object
                                thisPropValue = this.(propName);
                                combinedVal = ...
                                    internal.matlab.inspector.InspectorProxyMixin.getCombinedValue(...
                                    combinedVal, thisPropValue, ...
                                    this.MultipleValueCombinationMode);

                                prop = findprop(this, propName);

                                % pass through if no setter
                                if isempty(prop.SetMethod) && hasSetAccess(prop)
                                    origProp = findprop(o, propName);
                                    if isempty(origProp) || hasSetAccess(origProp)
                                        o.(propName) = thisPropValue;
                                    end
                                end

                                if hasSetAccess(prop)
                                    % we have a set method
                                    % if the property is of a special type,
                                    % wrap the value in that type before
                                    % setting it
                                    this.(propName) = this.getResolvedValueToApply(prop,thisPropValue);
                                end
                            end
                        else
                            % The property doesn't have public set access, but
                            % it may still change.  If the proxy itself has
                            % public set access, then the value should be set.
                            prop = findprop(this, propName);
                            if hasSetAccess(prop)
                                resolvedPropValue = this.getResolvedValueToApply(prop, propValue);

                                this.InternalPropertySet = true;
                                this.(propName) = resolvedPropValue;
                                this.InternalPropertySet = false;
                            end
                        end

                        % Update the struct version of the data as well.
                        % This needs to happen for properties no matter if
                        % the access is public or private.
                        this.PreviousData{i}.(propName) = propValue;
                    end
                end

                if isProp
                    % If a property was dynamically added to the object,
                    % we need to also add it to the proxy object
                    propAdded = this.addPropertyToProxy(propName);

                    if isempty(combinedVal)
                        % The property may not have setAccess, so just take the
                        % propValue to apply, rather than a combined value
                        % across the inspected objects
                        combinedVal = propValue;
                    end
                    if isprop(this, this.getInternalPropName(propName))
                        this.InternalPropertySet = true;
                        this.(this.getInternalPropName(propName)) = combinedVal;
                        this.InternalPropertySet = false;
                    elseif propAdded
                        this.(propName) = combinedVal;
                    end
                end
            end
        end

        function obj = getOriginalObjectAtIndex(this, idx)
            % Returns the original object at the given index
            obj = internal.matlab.inspector.InspectorProxyMixin.getObjectAtIndex(...
                this.OriginalObjects, idx);
        end

        function displayName = getPropertyDisplayName(this, propertyName)
            arguments
                this
                propertyName (1,1) string
            end

            if isKey(this.PropertyDisplayNameMap, propertyName)
                displayName = char(this.PropertyDisplayNameMap(propertyName));
            else
                displayName = char(propertyName);
            end
        end

        function tooltip = getPropertyTooltip(this, propertyName)
            arguments
                this
                propertyName (1,1) string
            end

            if isKey(this.PropertyTooltipMap, propertyName)
                tooltip = char(this.PropertyTooltipMap(propertyName));
            else
                tooltip = '';
            end
        end
    end

    methods (Access = protected)
        % Override the displayScalarObject method so that a disp of an
        % InspectorProxyMixin will only show the properties defined by the
        % class which extends the mixin.
        function displayScalarObject(this)
            header = getHeader(this);
            disp(header);

            props = properties(this);
            try
                values = cellfun(@(x) this.(x), props, ...
                    'UniformOutput', false);
            catch
                try
                    values = cellfun(@(x) this.OriginalObjects.(x), props, ...
                        'UniformOutput', false);
                catch
                    values = repmat(' ', length(props), 1);
                end
            end
            if ~iscell(values)
                values = {values};
            end
            s = cell2struct(values, props, 1);
            disp(s);
        end

        % Returns a list of the names of the Public, non-hidden properties
        % for the given object obj.
        function propertyList = getPublicNonHiddenProps(~, obj)
            propertyList = properties(obj);
        end

        % Returns a list of property names for the properties in the list
        % of objects (objectList), based on the
        % multiplePropertyCombinationMode parameter.  This will be either
        % the union of properties, the intersection of properties, the
        % properties from the first object, or the properties from the last
        % object.
        function propertyList = getPropertyListForMode(this, objectList, ...
                multiplePropertyCombinationMode)
            if multiplePropertyCombinationMode == "UNION"
                propertyList = {};
                for i = 1:length(objectList)
                    obj = internal.matlab.inspector.InspectorProxyMixin.getObjectAtIndex(...
                        objectList, i);

                    p = this.getPublicNonHiddenProps(obj);
                    propertyList = union(propertyList, p, 'stable');
                end

            elseif multiplePropertyCombinationMode == "INTERSECTION"
                propertyList = {};
                for i = 1:length(objectList)
                    obj = internal.matlab.inspector.InspectorProxyMixin.getObjectAtIndex(...
                        objectList, i);

                    p = this.getPublicNonHiddenProps(obj);
                    if isempty(propertyList)
                        propertyList = p;
                    else
                        propertyList = intersect(propertyList, p, ...
                            'stable');
                    end
                end

            elseif multiplePropertyCombinationMode == "FIRST"
                if length(objectList) == 1
                    obj = objectList;
                else
                    obj = objectList(1);
                end

                propertyList = this.getPublicNonHiddenProps(obj);

            elseif multiplePropertyCombinationMode == "LAST"
                if length(objectList) == 1
                    obj = objectList;
                else
                    obj = objectList(end);
                end

                propertyList = this.getPublicNonHiddenProps(obj);
            end
        end

        function propertyAdded = addPropertyToProxy(this, propertyName)
            % Add a new property to the proxy. This is necessary when a new
            % property is dynamically added to the original object.
            propertyAdded = false;
            if ~isprop(this, propertyName)
                addprop(this, propertyName);
                propertyAdded = true;
            end
        end

        function propertyRemoved = removePropertyFromProxy(this, propertyName)
            % Remote the property from the proxy. This is necessary when a new
            % property is dynamically removed from the original object.
            propertyRemoved = false;
            if isprop(this, propertyName)
                p = findprop(this, propertyName);
                delete(p);
                propertyRemoved = true;
            end
        end

        function deletionCallback(this, varargin)
            % Called when the object that this is the proxy object for is
            % deleted.  If this is the only object, then the proxy should
            % be deleted as well.
            if length(this.OriginalObjects) == 1
                delete(this);
            end
        end

        function propAddedCallback(this, ~, ed)
            % Handle properties being added when MATLAB hits a drawnow or idle
            % state so we can access the property's metaclass info.  This
            % handles the case where there's code like:
            %    pr = addprop(f, 'NewProp');
            %    pr.Hidden = true;
            % The first line triggers the 'PropertyAdded' event, so if we
            % process it then, we'll see the property is Hidden = false
            % (default).  There's no notification when the 2nd line is run.

            % Use drawnow.callback like elsewhere in the inspector so updates
            % can happen at drawnows.
            matlab.graphics.internal.drawnow.callback(@(~,~)this.propAddedCallbackIdle(ed)); 
        end

        function propRemovedCallback(this, ~, ed)
            this.removePropertyFromProxy(ed.PropertyName);

            remove(this.ObjRenderedData, keys(this.ObjRenderedData));
            remove(this.ObjectViewMap, keys(this.ObjectViewMap));
        end

        function notifyPropertiesUpdated(this)
            % This can be called to notify the inspector that multiple
            % properties changed in the InspectorProxyMixin, and that it should
            % update.
            remove(this.ObjRenderedData, keys(this.ObjRenderedData));
            remove(this.ObjectViewMap, keys(this.ObjectViewMap));
            this.OrigObjSetAccessNames = [];

            e = internal.matlab.variableeditor.PropertyChangeEventData;
            e.Properties = properties(this);
            e.Values = [];
            this.notify("PropertiesUpdated", e);
        end

        function setPropertyDisplayName(this, propertyName, displayName)
            arguments
                this
                propertyName string {mustBeTextScalar, mustBeNonmissing}
                displayName string {mustBeTextScalar, mustBeNonmissing}
            end

            this.PropertyDisplayNameMap(propertyName) = ...
                internal.matlab.inspector.Utils.getPossibleMessageCatalogString(displayName);
        end

        function setPropertyTooltip(this, propertyName, tooltip)
            arguments
                this
                propertyName string {mustBeTextScalar, mustBeNonmissing}
                tooltip string {mustBeTextScalar, mustBeNonmissing}
            end

            this.PropertyTooltipMap(propertyName) = ...
                internal.matlab.inspector.Utils.getPossibleMessageCatalogString(tooltip);
        end
    end

    methods(Hidden = true)
        function propAddedCallbackIdle(this, ed)
            % Handle properties being added when MATLAB hits a drawnow or idle
            % state so we can access the property's metaclass info.  
            pr = findprop(ed.Source, ed.PropertyName);
            if ~isempty(pr) && pr.GetAccess == "public" && ~pr.Hidden
                this.addPropertyToProxy(ed.PropertyName);

                remove(this.ObjRenderedData, keys(this.ObjRenderedData));
                remove(this.ObjectViewMap, keys(this.ObjectViewMap));
            end
        end

        function assignUserRichEditorUI(this, propertyName, richEditorClassName, value)
            % Assign the UserRichEditorUI to use for the property name

            arguments
                this

                % The property name
                propertyName (1,1) string

                % The class name of the UserRichEditorUI
                richEditorClassName (1,1) string

                % The initial value of the property
                value
            end

            % Create a divfigure as the parent to the user's rich editor
            df = matlab.ui.internal.divfigure("Name", "RichEditorUI_" + propertyName, "Resize", false);
            grid = uigridlayout(df, [1,1], "BackgroundColor", [1,1,1]);
            try
                % Call the constructor to the user's rich editor UI, and set the
                % position based on what it specifies.
                constructor = str2func(richEditorClassName);
                richEditorUI = constructor("Parent", grid, "Value", value, "PropertyName", propertyName, "ProxyClass", this);
                df.Position = [1, 1, richEditorUI.getEditorSize];

                if isKey(this.UserRichEditorUIMap, propertyName)
                    % Delete the parent divfigure for the previously created
                    % rich editor
                    existingEditor = this.UserRichEditorUIMap(propertyName);
                    existingFigure = ancestor(existingEditor, "figure");
                    delete(existingFigure);
                end
                this.UserRichEditorUIMap(propertyName) = richEditorUI;
            catch
                richEditorUI = [];
                delete(df);
            end

            if isempty(richEditorUI) || ~isa(richEditorUI, "internal.matlab.inspector.editors.UserRichEditorUI")
                % Error if this isn't the right class
                error("Invalid UserRichEditorUI definition")
            end
        end

        function recreateUserRichEditorUI(this)
            % Recreate any UserRichEditorUI's which were assigned.  This may be
            % necessary when the object is reinspected
            k = keys(this.UserRichEditorUIMap);
            for idx = 1:length(k)
                propertyName = k{idx};
                currRichEditorUI = this.getRichEditorUI(propertyName);
                value = currRichEditorUI.Value;
                className = class(this.UserRichEditorUIMap(propertyName));

                % Delete the parent divfigure for the previously created rich
                % editor
                existingFigure = ancestor(currRichEditorUI, "figure");
                delete(existingFigure);

                % Recreate the rich editor UI with the new value if possible,
                % otherwise just use the existing value.
                if isprop(this, propertyName)
                    value = this.(propertyName).Value;
                end
                this.assignUserRichEditorUI(propertyName, className, value);
            end
        end

        function richEditorUI = getRichEditorUI(this, propertyName)
            % Get the UserRichEditorUI for the property
            if isKey(this.UserRichEditorUIMap, propertyName)
                richEditorUI = this.UserRichEditorUIMap(propertyName);
            else
                richEditorUI = [];
            end
        end

        function value = getResolvedValueToApply(this, prop, value)
            % Returns the resolved value to apply, given the metaclass property
            % object prop, and the current value.  If the metaclass object
            % specifies a type, the value will be resolved to that type.  (For
            % example, a char could be resolved to an enumeration).  

            arguments
                this;

                 % The metaclass property, result of findprop(obj, propName)
                 prop;

                 % Value to resolve
                 value; 
            end

            propTypeName = prop.Type.Name;
            if isKey(this.PropertyTypeMap, prop.Name)
                % Check if the property is defined in the PropertyTypeMap (which
                % is the case for dynamic properties and classes overriding the
                % type of properties)
                propType = this.PropertyTypeMap(prop.Name);

                % propType can be a metaclass object, or just a type name
                if isa(propType, "meta.type") || isa(propType, "meta.class")
                    propTypeName = propType.Name;
                else
                    propTypeName = propType;
                end
            end

            value = internal.matlab.inspector.InspectorProxyMixin.getResolvedValueToApplyFromType(propTypeName, value);
        end
    end

    methods (Static)
        % Returns the combined value for the current value and new value of
        % a property, based on the multipleValueCombinationMode parameter,
        % which can be all, blank, first or last.
        function value = getCombinedValue(currValue, newValue, ...
                multipleValueCombinationMode)
            if multipleValueCombinationMode == "ALL"
                % Combine property values into arrays for those
                % properties which exist in multiple objects
                if isempty(currValue) || isequal(currValue, newValue)
                    % If there's only one value, or if the new value is
                    % equal to the old value, just use it
                    value = newValue;
                else
                    if ~isempty(currValue) && (ischar(currValue) || ...
                            ~isscalar(currValue))
                        if iscell(currValue)
                            currValue{end+1} = newValue;
                            value = currValue;
                        elseif isnumeric(currValue)
                            value = [currValue newValue];
                        else
                            value = {currValue newValue};
                        end
                    else
                        value = [currValue newValue];
                    end
                end
            elseif multipleValueCombinationMode == "BLANK"
                if isempty(currValue) || isequal(currValue, newValue)
                    % If there's only one value, or if the new value is
                    % equal to the old value, just keep it
                    value = newValue;
                else
                    % Otherwise, the value should be blank (empty)
                    value = [];
                end

            elseif multipleValueCombinationMode == "FIRST"
                % Value should always be the first value found for the
                % property
                value = currValue;

            elseif multipleValueCombinationMode == "LAST"
                % Value should come from the current object
                % (overwriting the previous value)
                value = newValue;
            end
        end

        function w = disableWarnings(clsName)
            % Use the warning function to temporarily change a warning
            % to an error, so that the normal error handling path
            % will be followed.
            if contains(clsName, ".")
                s = split(clsName, ".");
                if strlength(s(1)) > 0 && strlength(s(end)) > 0
                    warnmsg = "MATLAB:ui:" + s(end) + ":";
                    w(1) = warning('error', char(warnmsg + "noSizeChangeForRequestedWidth")); %#ok<*CTPCT>
                    w(2) = warning('error', char(warnmsg + "noSizeChangeForRequestedHeight"));
                    w(3) = warning('error', char(warnmsg + "fixedWidth"));
                    w(4) = warning('error', char(warnmsg + "fixedHeight"));
                else
                    w = [];
                end
            else
                w = [];
            end
        end

        % Tries to convert a text object to an enumeration or class when it
        % is specified as such by propTypeName.  propTypeName is the property
        % type (for example, and enumeration or class definition name).
        function value = getResolvedValueToApplyFromType(propTypeName, value)
            if ~isequal(propTypeName, 'any') && ...
                    ~contains(propTypeName, " ") && ...
                    ~startsWith(propTypeName, "matlab.graphics") && ...
                    ~isa(value, propTypeName) && ...
                    ~any([internal.matlab.variableeditor.NumericArrayDataModel.NumericTypes, ...
                    "struct", "table", "timetable", "cell", "datetime", "unicodeString", ...
                    "duration", "calendarDuration", "char", "string", "categorical", ...
                    "internal.matlab.editorconverters.datatype.UserRichEditorUIType"] == propTypeName)
                % Try to convert the value to an actual class if the type
                % isn't 'any', doesn't contain any spaces (like 'double
                % property'), isn't a well known data type, and isn't
                % already a class of that type
                l = lasterror; 
                try
                    value = feval(propTypeName, value);
                catch
                end
                lasterror(l); 
            elseif contains(propTypeName, "internal.matlab.editorconverters.datatype.UserRichEditorUIType")
                % Value needs to be resolved to a UserRichEditorUIType.  Also
                % try to eval value to the actual value (not just text)
                l = lasterror; 
                try
                    value = eval(value);
                catch
                end

                try
                   value = internal.matlab.editorconverters.datatype.UserRichEditorUIType(value);
                catch
                end
                lasterror(l);                 
            end
        end

        % set the property value
        function [status, value] = staticSetPropertyValue(obj, propertyName, value)
            status = '';
            origValue = internal.matlab.inspector.PropertyAccessor.getValue(obj, propertyName);

            % Temporarily change some warnings to errors so that the
            % normal inspector error handling path will be followed.
            w = internal.matlab.inspector.InspectorProxyMixin.disableWarnings(class(obj));

            try
                prop = findprop(obj, propertyName);

                % Use the resolved value, which may be an enumeration or
                % class value instead of a string, as the value to apply to
                % the object
                value = internal.matlab.inspector.InspectorProxyMixin.getResolvedValueToApplyFromType(...
                    prop.Type.Name, value);

                if hasSetAccess(prop)
                    for i = 1:length(obj)
                        internal.matlab.inspector.PropertyAccessor.setValue(...
                            obj(i), propertyName, value);
                    end
                end
            catch ex
                status = ex.message;
            end

            % Revert warning state
            if ~isempty(w)
                warning(w);
            end

            if ~isempty(status)
                % revert value
                obj.(propertyName) = internal.matlab.inspector.InspectorProxyMixin.getResolvedValueToApplyFromType(...
                    prop.Type.Name, origValue);
            end
        end

        function b = isSmallNumericChange(v1, v2)
            le = lasterror;
            try
                if iscell(v1) || iscell(v2)
                    b = false;
                else
                    val1 = double(v1);
                    val2 = double(v2);
                    b = isnumeric(val1) && ~isempty(val1) && ...
                        isnumeric(val2) && ~isempty(val2) && ...
                        isequal(size(val1), size(val2)) && ...
                        all(abs(val1 - val2) < 1e4*eps(min(abs(val1), abs(val2))), 'all');
                end
            catch
                b = false;
            end
            lasterror(le);
        end

        function obj = getObjectAtIndex(objectList, idx)
            % Returns the object at a given index.  If there is only object
            % (determined by either the length being 1 or the numel being 1,
            % then it references the object without ().  This is needed because
            % some objects, even though they are scalar, fail when using
            % subsreferencing with parenthesis.
            if length(objectList) == 1 || numel(objectList) == 1
                obj = objectList;
            else
                obj = objectList(idx);
            end
        end

        function internalPropName = getInternalPropName(propName)
            % Returns the property name to use as an internal property.  For
            % properties which don't border on the namelengthmax, it will just
            % be the property name with '_PI' appended to it.  If adding the
            % '_PI' will be too long, a different strategy is used to make sure
            % the internal property name is still valid.
            returnString = isstring(propName);
            propName = string(propName);

            if isvarname(propName) && strlength(propName) < (namelengthmax - 3)
                internalPropName = propName + "_PI";
            else
                % With the reverses we always end up with a property name with
                % _PI at the end
                internalPropName = reverse(matlab.lang.makeValidName(reverse(propName + "_PI")));
            end

            if ~returnString
                internalPropName = char(internalPropName);
            end
        end
    end
end

% Checks to see whether a property has SetAccess or not. prop is the result
% of getting the metaclass property data for a class, and then getting the
% property (prop) from the PropertyList.
function access = hasSetAccess(prop)
    access = false;

    accessVal = prop.SetAccess;
    if ischar(accessVal)
        % If the value is text, it needs to be 'public'
        access = strcmp(accessVal, 'public');
    else
        % accessVal is either a meta.class value, or a cell array
        % containing a meta.class value.
        if iscell(accessVal)
            access = any(cellfun(@(c) any(strcmp(c.Name, ["internal.matlab.inspector.InspectorProxyMixin", ...
                "matlab.ui.control.internal.model.AbstractStateComponent"])), accessVal));
        elseif isa(accessVal, 'meta.class')
            % If the value is a meta.class value, verify that it is a 'friend'
            % class of the InspectorProxyMixin.
            access = any(strcmp(accessVal.Name, ["internal.matlab.inspector.InspectorProxyMixin", ...
                "matlab.ui.control.internal.model.AbstractStateComponent"]));
        end
    end
end
