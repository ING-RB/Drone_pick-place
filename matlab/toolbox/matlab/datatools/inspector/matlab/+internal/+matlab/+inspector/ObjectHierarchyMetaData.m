% This class is unsupported and might change or be removed without
% notice in a future version.

% This class provides the Object Browser information for the object browser tree
% in the Property Inspector, for MCOS objects.

% Copyright 2020-2024 The MathWorks, Inc.

classdef ObjectHierarchyMetaData < internal.matlab.inspector.InspectorMetaData

    properties (Access = private)
        % The sub-object currently being inspected in the tree.
        SubObject = [];

        SubObjectIdx = NaN;

        % Whether to show the class name in the object browser hierarchy or not.
        % When not shown, just the property name is displayed.  Default is true,
        % to show the class name along with the property name.
        ShowClassInHierarchy (1,1) logical = true;

        % The top level name to show.  Will be used only if
        % UseVarNameAsHierarchyTop is set to true.
        TopLevelVariableName string = "";

        % Whether to use the variable name as the top of the object browser
        % hierarchy or not.  Default is false, so that the top of the hierarchy
        % is the class name.
        UseVarNameAsHierarchyTop (1,1) logical = false;

        CheckForRecursiveChildren (1,1) logical = true;
    end

    properties (Hidden)
        ProxyObject = [];
        PropertyTypeMap = [];
    end

    methods
        function this = ObjectHierarchyMetaData(hObj, subObject, subObjectIdx, topLevelVariableName)
            % Construct a ObjectHierarchyMetaData object, for the specified
            % object hObj, and optionally the subObject currently being
            % inspected.

            arguments
                hObj
                subObject = [];
                subObjectIdx = NaN;
                topLevelVariableName string = "";
            end

            if isa(hObj, "internal.matlab.inspector.InspectorProxyMixin")
                % Get the original object being inspected
                this.initPropMap(hObj);
                this.ProxyObject = hObj;
                this.ShowClassInHierarchy = hObj.ShowClassInHierarchy;
                if hObj.UseVarNameAsHierarchyTop
                    this.TopLevelVariableName = topLevelVariableName;
                end
                this.CheckForRecursiveChildren = hObj.CheckForRecursiveChildren;
                hObj = hObj.OriginalObjects;
            else
                this.initPropMap(hObj);
            end
            this.RefObject = hObj;

            if nargin > 1 && ~isempty(subObject)
                % The sub-object being inspected has been specified
                if isa(subObject, "internal.matlab.inspector.JavaObjectWrapper")
                    this.SubObject = subObject.ObjectRef;
                elseif isa(subObject, "internal.matlab.inspector.InspectorProxyMixin")
                    this.SubObject = subObject.OriginalObjects;
                else
                    this.SubObject = subObject;
                end

                if nargin > 2
                    this.SubObjectIdx = subObjectIdx;
                end
            end

            if ~isempty(this.RefObject)
                % Initialize the breadcrumbs and tree data
                this.TreeData =  this.getTreeData();
                this.BreadCrumbsData = this.getBreadCrumbsData();
            end
        end

        function changed = hasDataChanged(this)
            % Returns true if the metadata has changed

            arguments
                this internal.matlab.inspector.ObjectHierarchyMetaData
            end

            changed = false;

            % Check for changes to the tree data first
            newTreeTreeData = this.getTreeData;
            if ~isequal(newTreeTreeData, this.TreeData)
                this.TreeData = newTreeTreeData;
                changed = true;
            end

            % Next, check for changes to the breadcrumbs data
            newBreadCrumbsData = this.getBreadCrumbsData();
            if ~isequal(newBreadCrumbsData, this.BreadCrumbsData)
                this.BreadCrumbsData = newBreadCrumbsData;
                changed = true;
                return;
            end
        end

        function data = getData(this)
            % Returns the meta data as a struct, containing the treeData and
            % breadCrumbsData as fields.

            arguments
                this internal.matlab.inspector.ObjectHierarchyMetaData
            end

            % Make sure to always return the most updated data
            this.hasDataChanged();
            data = struct("treeData", {this.TreeData}, ...
                "breadCrumbsData",{this.BreadCrumbsData});
        end

        function obj = getRefObject(this)
            % Returns the reference object for the object hierarchy

            arguments
                this internal.matlab.inspector.ObjectHierarchyMetaData
            end

            obj = this.RefObject;
        end

        function obj = getProxyObject(this)
            % Returns the proxy object for the reference object for the
            % object hierarchy

            arguments
                this internal.matlab.inspector.ObjectHierarchyMetaData
            end

            obj = this.ProxyObject;
        end
    end

    methods (Hidden)
        function initPropMap(this, obj)
            this.PropertyTypeMap = containers.Map;
            try
                propNames = properties(obj);
                for idx = 1:length(propNames)
                    this.PropertyTypeMap(propNames{idx}) = findprop(obj, propNames{idx});
                end
            catch
            end
        end

        function b = getBreadCrumbsData(this)
            % Creates the breadcrumbs data for the object hierarchy

            arguments
                this internal.matlab.inspector.ObjectHierarchyMetaData
            end

            % Start with the tree data, and construct the breadcrumbs by working
            % from the selected item(s) and up to the parent.
            d = this.TreeData;
            sd = string(d);
            sttd = cellfun(@(x) mls.internal.fromJSON(x), sd, "UniformOutput", false);
            sttd = cell2mat(sttd);
            sttd(1).parent = 0;

            ids = {};
            labels = {};

            % find selected item(s)
            selectedIndex = find(string({sttd.selected}) == "on");
            if isempty(selectedIndex)
                selectedIndex = 1;
            end

            % get the ids and labels for the selected item(s)
            ids{end+1} = selectedIndex;
            labels{end+1} = {sttd(selectedIndex).label};
            parent = sttd(selectedIndex).parent;

            % work up the tree, parent by parent, until the top level object is
            % found
            while parent > 0
                currObj = sttd(parent);
                ids{end+1} = currObj.id;
                labels{end+1} = currObj.label;
                parent = currObj.parent;
            end

            % Create a struct array of the textToDisplay (property name and
            % class), as well as the id, a numeric array of the selection
            st = struct("textToDisplay", labels(1), "id", ids(1));
            if length(ids) > 1
                for idx = 2:length(ids)
                    st(idx).textToDisplay = labels(idx);
                    st(idx).id = ids(idx);
                end
            end

            % Create a cell array of the JSON data for the breadcrumbs, working
            % from the selection to the top level object.
            b = cell(length(st), 1);
            path = 0;
            for idx = 1:length(b)
                st(idx).pathToNavigateOnClick = path;
                path = path + 1;
                % Update the text displayed in the case of multiple selections
                numIDs = length(st(idx).id);
                if numIDs == 1
                    st(idx).textToDisplay = st(idx).textToDisplay{1};
                elseif numIDs == 2
                    st(idx).textToDisplay = strjoin(st(idx).textToDisplay, ", ");
                elseif numIDs > 2
                    st(idx).textToDisplay = getString(message(...
                        "MATLAB:codetools:inspector:MultiPropertySelectedInHierarchy", ...
                        st(idx).textToDisplay{1}, string((length(st(idx).id) - 1))));
                end

                b{idx} = mls.internal.toJSON(st(idx));
            end

            % flip the array so it starts from the top level object
            b = flipud(b);
        end

        function d = getTreeData(this)
            % Creates the tree data for the object hierarchy
            arguments
                this internal.matlab.inspector.ObjectHierarchyMetaData
            end

            d = getHierarchy(this.RefObject, ...
                this.SubObject, ...
                this.SubObjectIdx, ...
                this.PropertyTypeMap, ...
                this.ShowClassInHierarchy, ...
                this.TopLevelVariableName, ...
                this.CheckForRecursiveChildren, ...
                this.ProxyObject);
        end
    end

    methods(Static, Hidden = true)
        function [selectedField, selectedIndex, isReadOnly] = getSelectedFieldAndIndex(childIndex, metaDataHandler)
            % Returns the selectedField as an array, for example ["A", "B"].
            % selectedIndex is a corresponding numeric array, which will only be
            % set in case of arrays of objects.
            arguments
                % The child index in the tree hierarchy
                childIndex

                % The ObjetHierarchyMetaData class for the current object
                % browser display.
                metaDataHandler
            end

            isReadOnly = false;
            if childIndex > 1
                % Get the current tree data, as td, and convert them to their
                % structs (from JSON), as sttd
                td = string(metaDataHandler.getData.treeData);
                sttd = cellfun(@(x) mls.internal.fromJSON(x), td, "UniformOutput", false);
                sttd = cell2mat(sttd);

                % Get the selected object based on the child index, and get its
                % property name
                selectedObj = sttd([sttd.id] == childIndex);
                selectedField = string(selectedObj.propName);
                isReadOnly = isReadOnly || (selectedObj.isReadOnly == "true");

                % Get its parent object ID
                parentObj = sttd([sttd.id] == selectedObj.parent);
                parentIDs = [0 sttd.parent];

                % Find the objects which share the same parent
                sameParent = sttd(parentIDs == parentObj.id);
                c = {sameParent.propName};
                c = c(~cellfun(@isempty, c));

                % Look for objects of the same name (this is an array of
                % objects)
                sameNames = string(c);
                sameNamesObj = sameParent(sameNames == selectedField);
                selectedIndex = [];

                if length(sameNamesObj) > 1
                    % There is an array of objects
                    selectedIndex(end+1) = selectedObj.arrayIndex;
                else
                    selectedIndex(end+1) = 0;
                end

                while ~isempty(parentObj.parent)
                    % Keep going up the tree until the root object is found
                    parentPropName = string(parentObj.propName);
                    childIndex = parentObj.id;
                    if ~isempty(parentPropName) && ~parentObj.isArraySummary
                        selectedField(end+1) = parentPropName; %#ok<*AGROW>
                        parentObj = sttd([sttd.id] == parentObj.parent);

                        parentIDs = [0 sttd.parent];
                        sameParent = sttd(parentIDs == parentObj.id);
                        sameNames = string({sameParent.propName});
                        sameNamesObj = sameParent(sameNames == parentPropName);

                        if length(sameNamesObj) > 1
                            % There is an array of objects
                            selectedIndex(end+1) = find([sameNamesObj.id] == childIndex);
                        else
                            selectedIndex(end+1) = 0;
                        end
                    else
                        parentObj = sttd(parentObj.parent == [sttd.id]);
                    end
                end

                % The field list was found in backwards order, flip it back to
                % the right order
                selectedField = fliplr(selectedField);
                selectedIndex = fliplr(selectedIndex);
            else
                selectedField = strings(0);
                selectedIndex = [];
            end
        end
    end
end

function h = getHierarchy(obj, subObject, subObjectIdx, propertyTypeMap, showClassName, topLevelName, checkForRecursiveChildren, proxyObject)
    % Local function used to construct the object hierarchy for an object.  The
    % currently selected sub-object may also be specified (or can be [] if not).

    arguments
        obj
        subObject
        subObjectIdx = nan
        propertyTypeMap = []
        showClassName (1,1) logical = false
        topLevelName string = ""
        checkForRecursiveChildren (1,1) logical = true
        proxyObject = [];
    end

    % Keep track of the objects which have been traversed to far, to help avoid
    % recursive references
    traversedObjects = {};

    % The object identifier.  Each object in the hierarchy is assigned an unique
    % identifier
    objectIdentifier = 0;

    % Construct a struct of the results, which will be added to as the hierarchy
    % is traversed.
    t = struct('id', [], ...
        'label', strings(0), ...
        'parent', [], ...
        'selected', strings(0), ...
        'visible', strings(0), ...
        'isReadOnly', strings(0), ...
        'iconProps', strings(0), ...
        'propName', strings(0), ...
        'arrayIndex', [], ...
        'isArraySummary', true(0));

    % Check for properties to skip in the hierarchy, if it is defined
    if isempty(proxyObject)
        propsToSkip = strings(0);
    else
        propsToSkip = proxyObject.PropsToSkipInHierarchy;
    end

    % Call the getHierarchyInternal recursive function, which will traverse the
    % object, and add details to the table, t.
    getHierarchyInternal(obj, 0, topLevelName, 0, propertyTypeMap);

    % Collapse the table into the expected format, and do some extra handling
    % for the root object
    h = collapseHierarchy(t);
    h(1) = strrep(h(1), '"parent":0', '"parent":null');

    function n = getNextId()
        % Returns the next id to use for an identifier
        objectIdentifier = objectIdentifier + 1;
        n = objectIdentifier;
    end

    function getHierarchyInternal(obj, parentID, name, arrayIndex, propertyTypeMap)
        % Recursive function used to traverse an object hierarchy

        % First, check if we've seen this object before.  If we have, just
        % return, otherwise recursive references in the object will cause an
        % infinite loop.
        if checkForRecursiveChildren
            seenBefore = cellfun(@(x) x == obj, traversedObjects, ...
                "ErrorHandler", @(~,~) false, "UniformOutput", false);
            if any(cell2mat(seenBefore))
                return
            end
        end

        % It hasn't been seen previously, so add it to the list of traversed
        % objects
        traversedObjects{end + 1} = obj;

        % Construct the row in the table for the current object.  The label will
        % include the property name and class, something like:
        % Prop1: ObjectType
        %
        % Or, in the case of arrays of objects, it can be something like:
        % Prop1(1): ObjectType
        currObjID = getNextId;
        t(end+1).id = currObjID;
        if isempty(name) || strlength(name) == 0
            t(end).label = getDisplayClass(obj, proxyObject, parentID);
        elseif ~isempty(arrayIndex) && arrayIndex > 0
            t(end).label = name + "(" + arrayIndex + "): " + getDisplayClass(obj, proxyObject, parentID);
        elseif showClassName
            t(end).label = name + ": " + getDisplayClass(obj, proxyObject, parentID);
        else
            t(end).label = name;
        end
        t(end).propName = name;
        t(end).arrayIndex = arrayIndex;
        t(end).parent = parentID;
        t(end).visible = "on";

        isReadOnly = false;
        try
            if ~isempty(propertyTypeMap) && isKey(propertyTypeMap, name)
                propVal = propertyTypeMap(name);
                isReadOnly = ~isequal(propVal.SetAccess, "public");
            else
                % Check the read-only flag of the parent
                parentTbl = t([false ([t(2:end-1).id] == parentID) false]);
                if ~isempty(parentTbl)
                    isReadOnly = str2num(parentTbl.isReadOnly); %#ok<ST2NM>
                end
            end
        catch
        end
        t(end).isReadOnly = string(isReadOnly);
        t(end).iconProps = "";
        t(end).isArraySummary = false;

        % If this object is the subObject, it is the selected object in the tree
        objSelected = "off";
        if isscalar(subObject)
            matchesSubObject = isequal(obj, subObject);
        else
            matchesSubObject = any(arrayfun(@(x) isequal(obj, x), subObject));
        end
        if matchesSubObject
            if ~isnan(subObjectIdx)
                if any(subObjectIdx == (length(t) - 1))
                    objSelected = "on";
                end
            else
                if  length(t) > 3 && any([t(2:end-1).selected] == "on") && (isscalar(subObject))
                    % Something has already been selected, uh-oh
                    objSelected = "off";
                else
                    objSelected = "on";
                end
            end
        end
        t(end).selected = objSelected;

        % Traverse all of the properties of this object, looking for those which
        % are themselves objects.
        if isstruct(obj)
            p = fieldnames(obj);
        elseif isjava(obj)
            if any(name == propsToSkip)
                p = [];
            else
                try
                    % Need to call get() on the object, and use the field names
                    % from that
                    objProps = get(obj);
                    p = fieldnames(objProps);
                catch
                    p = [];
                end
            end
        else
            p = properties(obj);
        end

        for idx = 1:length(p)
            propName = p{idx};
            if any(propName == propsToSkip)
                continue;
            end

            try
                props = obj.(propName);
            catch
                if isjava(obj)
                    props = get(obj, propName);
                else
                    % Ignore issues accessing the property, and just treat it as
                    % empty.  This can fail for missing dependent accessor methods,
                    % incorrect class definitions, etc.
                    props = [];
                end
            end
            newParentID = 0;

            if isstruct(props) || isjava(props) || (isobject(props) && ~isempty(props) && ~internal.matlab.datatoolsservices.FormatDataUtils.isValueSummaryClass(class(props)) ...
                    && ~isstring(props) && ~istall(props)) && ~isenum(props)

                if isa(props, "containers.Map")
                    propLen = 1;
                else
                    propLen = length(props);
                end

                if propLen > 1
                    % Add in an entry in the hierarchy for an array of objects.
                    % This will show up as something like:
                    % Prop1:  1x3 ObjectType

                    t(end+1).id = getNextId;
                    newParentID = t(end-1).id + 1;
                    t(end).label = propName + ": " + internal.matlab.datatoolsservices.FormatDataUtils.dimensionString(props) + " " + getDisplayClass(props);
                    t(end).parent = currObjID; %t.id(end-1);
                    t(end).propName = propName;
                    if isequal(props, subObject)
                        t(end).selected = "on";
                    else
                        t(end).selected = "off";
                    end
                    t(end).visible = "on";
                    t(end).isReadOnly = "false";
                    t(end).iconProps = "";
                    t(end).isArraySummary = true;
                    t(end).arrayIndex = 0;
                end

                for idx2 = 1:propLen
                    % Traverse the object.  There will be only 1, except in the
                    % cases of a property containing an object array.
                    try
                        propObj = props(idx2);
                    catch ex
                        if idx2 == 1
                            propObj = props;
                        else
                            rethrow(ex)
                        end
                    end
                    if propLen > 1
                        currArrayIdx = idx2;
                    else
                        currArrayIdx = 0;
                    end

                    if isobject(propObj) || isstruct(propObj) || isjava(propObj)
                        % This property contains an object, call
                        % getHierarchyInternal recursively to add in the
                        % hierarchy for its properties. If propObj is a
                        % poxymixin, set propObj to be the underlying object.
                        if isa(propObj, 'internal.matlab.inspector.InspectorProxyMixin')
                            propObj = propObj.OriginalObjects;
                        end
                        if newParentID > 0
                            getHierarchyInternal(propObj, newParentID, propName, currArrayIdx, propertyTypeMap);
                        else
                            getHierarchyInternal(propObj, currObjID, propName, currArrayIdx, propertyTypeMap);
                        end
                    end
                end
            end
        end
    end
end

function c = collapseHierarchy(val)
    % Collapse the struct array into the expected form, which is a cell array of
    % JSON text for the objects in the tree.
    val(1) = [];
    st = val;
    c = cell(length(st), 1);
    for idx = 1:length(c)
        c{idx} = mls.internal.toJSON(st(idx));
    end
end

function c = getDisplayClass(obj, proxyObj, parentID)
    % Returns the display class for an object, which in most cases just the
    % class name.  So instead of seeing 'matlab.package.Classname', you would
    % just see 'Classname'
    arguments
        obj
        proxyObj = []
        parentID = 0;
    end

    if ~isempty(proxyObj) && parentID == 0 && isa(proxyObj, "internal.matlab.inspector.NonHandleObjWrapper")
        % For non-handle objects, get the class name from the ObjectRef object
        c = class(proxyObj.ObjectRef);
    else
        c = class(obj);
        if contains(c, ".") && ~strcmp(c, "containers.Map")
            c = fliplr(extractBefore(fliplr(c), "."));
        end
    end
end
