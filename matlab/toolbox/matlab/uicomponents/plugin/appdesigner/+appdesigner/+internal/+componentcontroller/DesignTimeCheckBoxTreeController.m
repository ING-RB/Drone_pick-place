classdef DesignTimeCheckBoxTreeController < ...
    matlab.ui.container.internal.controller.CheckBoxTreeController  & ...
    appdesigner.internal.componentcontroller.DesignTimeTreeController

    % As the functionality of CheckBoxTree greatly overlaps with Tree,
    % it extends DesignTimeTreeController

    % Copyright 2020 The MathWorks, Inc.

    methods
        function obj = DesignTimeCheckBoxTreeController(component, parentController, proxyView, adapter)
            obj = obj@matlab.ui.container.internal.controller.CheckBoxTreeController(component, parentController, proxyView);
            obj = obj@appdesigner.internal.componentcontroller.DesignTimeTreeController(component, parentController, proxyView, adapter);
        end

        function populateView(obj, proxyView)
            populateView@appdesigner.internal.componentcontroller.DesignTimeTreeController(obj, proxyView)
        end
        
        function arrangeNewlyAddedChild(obj, child, componentIndex)
            % The recommended workflow for reordering the children is to use the move command
            % which will preserve the state of the nodes even after a reorder.
            child.move(child.Parent.Children(componentIndex), 'before')
        end
    end

    methods (Access = 'protected')
        function handleDesignTimePropertiesChanged(obj, src, changedPropertiesStruct)
            % HANDLEDESIGNTIMEPROPERTIESCHANGED - Delegates the logic of
            % handling the event to the runtime controllers via the
            % handlePropertiesChanged method

            handlePropertiesChanged(obj, changedPropertiesStruct)
        end

        function unhandledProperties = handlePropertiesChanged(obj, changedPropertiesStruct)
            % HANDLEPROPERTIESCHANGED - Converts the string Node Ids to Tree Nodes and then delegates the logic of
            % handling the event to the runtime controllers via the
            % handlePropertiesChanged method

            % CheckedNodes property in changedPropertiesStruct will be cell of NodeIds when received from Client.
            % However, run-time CheckBoxTree component requires it to be an array of TreeNodes.
            % So convert the cell of NodeIds into array of Tree Nodes.
            if isfield(changedPropertiesStruct, 'CheckedNodes')
                checkedNodeIds = changedPropertiesStruct.CheckedNodes;
                if ischar(checkedNodeIds) || isstring(checkedNodeIds)
                    checkedNodeIds = cellstr(checkedNodeIds);
                end

                changedPropertiesStruct.CheckedNodes = obj.convertNodeIdsToNodes(checkedNodeIds);
            end

            handlePropertiesChanged@matlab.ui.control.internal.controller.ComponentController(obj, changedPropertiesStruct);
        end
    end

    methods
        function treeNodesArr = convertNodeIdsToNodes(obj, checkedNodeIds)
            treeNodesArr = [];
            for i = 1:numel(checkedNodeIds)
                treeNodesArr = [treeNodesArr, obj.getTreeNodeByNodeId(obj.Model, checkedNodeIds{i})];
            end
        end

        function matchedNode = getTreeNodeByNodeId(obj, node, nodeId)
            matchFound = 0;
            matchedNode = [];
            for i = 1:numel(node.Children)
                if strcmp(node.Children(i).NodeId, nodeId)
                    matchedNode = node.Children(i);
                    matchFound = 1;
                    break;
                end
            end
            if matchFound ~= 1
                for i = 1:numel(node.Children)
                    matchedNode = obj.getTreeNodeByNodeId(node.Children(i), nodeId);
                    if isa(matchedNode, 'matlab.ui.container.TreeNode')
                        break;
                    end
                end
            end
        end
    end

    methods(Access = {...
            ?appdesservices.internal.interfaces.controller.AbstractController, ...
            ?appdesservices.internal.interfaces.controller.AbstractControllerMixin})

        function handleChildCodeGenerated(obj, changedChild)
            handleChildCodeGenerated@appdesigner.internal.componentcontroller.DesignTimeTreeController(obj, changedChild)

            if ismember(changedChild, obj.Model.CheckedNodes)
                obj.updateGeneratedCode();
            end
        end
    end

    methods(Access = {...
            ?appdesigner.internal.componentcontroller.DesignTimeTreeController, ...
            ?appdesigner.internal.componentcontroller.DesignTimeCheckBoxTreeController, ...
            ?appdesigner.internal.componentcontroller.DesignTimeTreeNodeController})

        function fireServerReadyEvent(obj, treeNode)
            % FIRESERVERREADYEVENT - In some cases, the tree properties need to be updated
            % when a new tree node is added. For example, if a checked tree node is added
            % to CheckBoxTree, the CheckedNodes property needs to be updated to contain
            % the newly added tree node. This fires a ServerReady event so
            % that client sets the CheckedNodes proeprty on receiving this
            % event.
            
            if ~isempty(obj.ClientEventSender)
                obj.ClientEventSender.sendEventToClient('ServerReady', {'NodeId', treeNode.NodeId{1}});
            end
        end
    end
end
