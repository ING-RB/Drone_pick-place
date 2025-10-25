% This class is unsupported and might change or be removed without
% notice in a future version.

% This class handles actions coming from the Object Browser tree in the Property
% Inspector, for MCOS objects.

% Copyright 2020-2022 The MathWorks, Inc.

classdef InspectorObjectActionHelper < handle

    methods (Static)
        function b = actionEventHandler(ed, metaDataHandler)
            % Event handler for client-side actions events for MCOS objects in
            % the object browser.  Currently the only supported event is
            % selection.

            arguments
                % Event data
                ed

                % The ObjetHierarchyMetaData class for the current object
                % browser display.
                metaDataHandler
            end

            switch ed.actionType
                case "objectSelectionChanged"
                    b = internal.matlab.inspector.peer.InspectorObjectActionHelper.selectObject(ed, metaDataHandler);

                otherwise
                    b = [];
            end
        end
    end

    methods (Static, Hidden = true)
        function hSelected = selectObject(ed, metaDataHandler)
            % Selects the object specified by the event data, ed.  It contains
            % the 'childOrder', which is the selected index in the tree data.

            arguments
                % Event data
                ed

                % The ObjetHierarchyMetaData class for the current object
                % browser display.
                metaDataHandler
            end

            hSelected = [];
            switch ed.selectionCriteria
                case "childOrder"
                    % Select based on the child order in the tree
                    hSelected = internal.matlab.inspector.peer.InspectorObjectActionHelper.selectChild(...
                        ed.affectedNodes, metaDataHandler, ed.channel);

                case "index"
                    hSelected = internal.matlab.inspector.peer.InspectorObjectActionHelper.selectChildFromBreadCrumbs(...
                        ed.objectToSelect, metaDataHandler, ed.channel);
            end
        end

        function currObjects = selectChild(childrenIndex, metaDataHandler, channel)
            % Inspects the selected child in the object browser tree, based on
            % the childIndex

            arguments
                % The child index in the tree hierarchy
                childrenIndex

                % The ObjetHierarchyMetaData class for the current object
                % browser display.
                metaDataHandler

                % inspector channel
                channel
            end

            for childIdx = 1:length(childrenIndex)
                childIndex = childrenIndex(childIdx);

                % Get the selected field and index for the child index
                [selectedField, selectedIndex, isReadOnly] = internal.matlab.inspector.ObjectHierarchyMetaData.getSelectedFieldAndIndex(...
                    childIndex, metaDataHandler);

                % Get the current reference object, which is the top level
                % object in the tree.
                hierarchyTopProxy = metaDataHandler.getProxyObject();
                hierarchyTop = metaDataHandler.getRefObject();
                currObj = hierarchyTop;

                % Walk through the list of selected fields, and reference that
                % object in the original object.  For example, selected fields
                % may be something like:  ["A", "B"], so we need to do:
                % currObj = currObj.A; currObj = currObj.B.  If there is a
                % selectedIndex, that needs to be taken into account (for arrays
                % of objects)
                refString = "";
                for idx = 1:length(selectedField)
                    if isjava(currObj)
                        % Call get(obj, propertyName) for java objects
                        currObj = {get(currObj, selectedField(idx))};
                    else
                        currObj = {currObj.(selectedField(idx))};
                    end
                    refString = refString + "." + selectedField(idx);
                    if selectedIndex(idx) > 0
                        currObj = currObj{1}(selectedIndex(idx));
                        refString = refString + "(" + selectedIndex(idx) + ")";
                    else
                        currObj = currObj{1};
                    end
                end

                if childIdx == 1
                    currObjects = currObj;
                else
                    currObjects(end + 1) = currObj;
                end
            end

            inspectorMap = internal.matlab.inspector.peer.InspectorFactory.getInspectorInstances;
            if isKey(inspectorMap, channel)
                % Get the inspector
                inspectorMgr = inspectorMap(channel);


                currObj = internal.matlab.inspector.peer.InspectorObjectActionHelper.getObjectToInspect(...
                    currObjects, metaDataHandler, isReadOnly, refString, hierarchyTopProxy);

                if isgraphics(currObj)
                    % This is the case of a non-graphics object having a
                    % graphics object as a property.  When the graphics object
                    % is inspected, its browser takes over.  So rather than
                    % leave the inspector in this mixed state, just inspect the
                    % graphics object.
                    inspectorMgr.inspect(currObj,...
                        internal.matlab.inspector.MultiplePropertyCombinationMode.INTERSECTION,...
                        internal.matlab.inspector.MultipleValueCombinationMode.LAST, ...
                        "", "");
                else
                    % Call subObjectInspect() on the new object, keeping the
                    % hierarchy top the same.
                    topLevelObj = internal.matlab.inspector.peer.InspectorObjectActionHelper.getTopLevelObjFromProxy(metaDataHandler);
                    inspectorMgr.subObjectInspect(currObj,...
                        internal.matlab.inspector.MultiplePropertyCombinationMode.INTERSECTION,...
                        internal.matlab.inspector.MultipleValueCombinationMode.LAST, ...
                        metaDataHandler.VariableWorkspace, metaDataHandler.VariableName, topLevelObj, childrenIndex);
                end
            end
        end

        function topLevelObj = getTopLevelObjFromProxy(metaDataHandler)
            hierarchyTopProxy = metaDataHandler.getProxyObject();

            % If the top level object is a proxy object, use it, since this may
            % redefine properties or property access
            if isempty(hierarchyTopProxy) || ~isa(hierarchyTopProxy, "internal.matlab.inspector.InspectorProxyMixin")
                topLevelObj = metaDataHandler.getRefObject();
            else
                topLevelObj = hierarchyTopProxy;
            end
        end
        
        function currObj = getObjectToInspect(obj, metaDataHandler, isReadOnly, refString, hierarchyTopProxy)
            arguments
                obj;
                metaDataHandler internal.matlab.inspector.ObjectHierarchyMetaData
                isReadOnly logical = false;
                refString string = strings(0);
                hierarchyTopProxy = [];
            end

            if ~isempty(metaDataHandler.getProxyObject)
                useLabelForReadOnly = metaDataHandler.getProxyObject.UseLabelForReadOnly;
                supportsPopupWindowEditor = metaDataHandler.getProxyObject.SupportsPopupWindowEditor;
                showInspectorToolstrip = metaDataHandler.getProxyObject.ShowInspectorToolstrip;
                checkForRecursiveChildren = metaDataHandler.getProxyObject.CheckForRecursiveChildren;
            else
                useLabelForReadOnly = false;
                supportsPopupWindowEditor = true;
                showInspectorToolstrip = true;
                checkForRecursiveChildren = true;
            end

            if ~isa(obj, "handle")
                % Need to find out if read-only based on finding the
                % property from either the metaDataHandler.ProxyObject or
                % the metaDatahandler.RefObject.
                if isjava(obj) || isa(hierarchyTopProxy, "internal.matlab.inspector.JavaObjectWrapper")
                    if ~isjava(obj)
                        wrapper = internal.matlab.inspector.JavaObjectWrapper(hierarchyTopProxy.ObjectRef, ...
                            metaDataHandler.VariableName + refString, metaDataHandler.VariableWorkspace, isReadOnly);
                    else
                        wrapper = internal.matlab.inspector.JavaObjectWrapper(obj, ...
                            metaDataHandler.VariableName + refString, metaDataHandler.VariableWorkspace, isReadOnly);
                    end
                elseif isstruct(obj)
                    wrapper = internal.matlab.inspector.StructWrapper(obj, ...
                        metaDataHandler.VariableName + refString, metaDataHandler.VariableWorkspace, isReadOnly);
                else
                    wrapper = internal.matlab.inspector.ValueObjectWrapper(obj, ...
                        metaDataHandler.VariableName + refString, metaDataHandler.VariableWorkspace, isReadOnly);
                end

                currObj = wrapper;
            elseif (useLabelForReadOnly || ~supportsPopupWindowEditor || ~showInspectorToolstrip || ~checkForRecursiveChildren) && ...
                    ~isa(obj, "internal.matlab.inspector.InspectorProxyMixin")
                [proxyClass, proxyClassName] = internal.matlab.inspector.peer.InspectorFactory.getInspectorView(class(obj), 'default', obj);
                if isempty(proxyClassName)
                    currObj = internal.matlab.inspector.DefaultInspectorProxyMixin(obj);
                else
                    currObj = proxyClass;
                end
            else
                currObj = obj;
            end

            if useLabelForReadOnly
                % set the UseLabelForReadOnly flag if available
                currObj.UseLabelForReadOnly = useLabelForReadOnly;
            end
            if ~supportsPopupWindowEditor
                currObj.SupportsPopupWindowEditor = supportsPopupWindowEditor;
            end
            if ~showInspectorToolstrip
                currObj.ShowInspectorToolstrip = showInspectorToolstrip;
            end
            if ~checkForRecursiveChildren
                currObj.CheckForRecursiveChildren = checkForRecursiveChildren;
            end
        end
        
        function currObj = selectChildFromBreadCrumbs(childIndex, metaDataHandler, channel)
            % Inspects the selected child in the object breadCrumbs, based on
            % the childIndex

            arguments
                % The child index in the tree hierarchy
                childIndex

                % The ObjetHierarchyMetaData class for the current object
                % browser display.
                metaDataHandler

                % inspector channel
                channel
            end

            st = cell2mat(cellfun(@(x) mls.internal.fromJSON(x), ...
                string(metaDataHandler.getData.breadCrumbsData), "UniformOutput", false));
            selectedObj = st([st.pathToNavigateOnClick] == str2double(childIndex));
            if ~isempty(selectedObj)
                selectedID = selectedObj.id;
                currObj = internal.matlab.inspector.peer.InspectorObjectActionHelper.selectChild(...
                    selectedID, metaDataHandler, channel);
            else
                currObj = [];
            end
        end
    end
end
