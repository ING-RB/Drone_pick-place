classdef TreeNodeInteractor < matlab.uiautomation.internal.interactors.AbstractComponentInteractor ...
        ... access to the TreeNode/NodeId property
        & matlab.ui.internal.componentframework.services.optional.ControllerInterface
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2019-2023 The MathWorks, Inc.
    
    methods
        
        function uichoose(actor, tnHandleArray, value)
            
            arguments
                actor
                tnHandleArray = []
                value {mustBeScalarLogical} = false
            end 

            import matlab.uiautomation.internal.Modifiers;
            import matlab.uiautomation.internal.InteractorFactory;
            
            % Get tree root
            tnHandleArray = unique(tnHandleArray, 'stable');
            firstTreeNode = actor.Component;
            tree = getParentTree(firstTreeNode);

            % Otherwise we can assume standard parenting-rules apply
            validateRootDescendant(tree);
            
            % narginchk for uitree and uickeckboxtree cases
            if strcmp(tree.Type, 'uicheckboxtree')
                narginchk(1,3);
            elseif strcmp(tree.Type, 'uitree')
                narginchk(1,2);
            end

            % Tree must be multiselectable if more than one tree node
            % passed as arguments
            if numel(tnHandleArray) > 1 && (strcmp(tree.Type , 'uicheckboxtree') || strcmp(get(tree,'Multiselect'), "off"))
                error(message('MATLAB:uiautomation:Driver:ComponentNotMultiSelectable'));
            end            

            % Choose happens only when the tree nodes to be chosen are different from the already selected nodes
            if numel(tnHandleArray) ~= numel(tree.SelectedNodes) || ~all(ismember(tnHandleArray, tree.SelectedNodes))
                for i = 1:numel(tnHandleArray)
                    treenode = tnHandleArray(i);
                    expand(actor, treenode, tree);
                    targetID = treenode.NodeId;
                    if i == 1
                        actor.Dispatcher.dispatch(...
                              tree, 'uipress', 'TargetNodeID', char(targetID));
                    else
                        treenodeActor = InteractorFactory.getInteractorForHandle(treenode);
                        modifier = Modifiers.CTRL;
                        treenodeActor.Dispatcher.dispatch(...
                            tree, 'uipress', 'TargetNodeID', char(targetID), 'Modifier', modifier);
                    end
                end
            end

            % If it is a uicheckbox tree, check the value to toggle as
            % needed
            if strcmp(tree.Type , 'uicheckboxtree')
                toggle = shouldToggleCheckbox(tree, firstTreeNode, value) && (nargin == 3);
                if toggle
                    targetID = firstTreeNode.NodeId;
                    actor.Dispatcher.dispatch(tree, 'uipress', ...
                    'TargetNodeID', char(targetID), 'ToggleCheckBox', true);
                end
            end

        end
        
        function uicontextmenu(actor, menu)
            arguments
                actor
                menu (1,1) matlab.ui.container.Menu {validateParent}
            end
            
            treenode = actor.Component;
            tree = getParentTree(treenode);
            
            % otherwise we can assume standard parenting-rules apply
            validateRootDescendant(tree);
            
            % expand all the way up
            expand(actor,treenode, tree);
            
            targetID = treenode.NodeId;
            actor.Dispatcher.dispatch(...
                tree, 'uicontextmenu', 'TargetNodeID', char(targetID));
            
            menuInteractor = matlab.uiautomation.internal.InteractorFactory.getInteractorForHandle(menu);
            menuInteractor.uipress();
        end
        
    end
end

function expand(actor, treenode, tree)
    parent = treenode.Parent;
    allAncestors = {};
    % Put all target treenode's ancestor treenodes to a cell
    while parent ~= tree
        allAncestors(end+1) = {parent};
        parent = parent.Parent;
    end
    % Iterate through the ancestor treenodes from top to bottom
    % Expand every ancestor treenode
    while ~isempty(allAncestors)
        parentNodeToExpand = allAncestors{end};
        allAncestors(end) = [];
        nodeId = parentNodeToExpand.NodeId;
        actor.Dispatcher.dispatch(...
            tree, 'uipress', 'TargetNodeID', char(nodeId), 'ExpandOnly', true);
    end
end

function validateRootDescendant(tree)
if isempty(tree)
    error( message('MATLAB:uiautomation:Driver:RootDescendant') );
end
end

function tree = getParentTree(treenode)
tree = ancestor(treenode, 'matlab.ui.container.internal.model.TreeComponent');
end

function toggle = shouldToggleCheckbox(tree, treenode, value)
currValue = any(tree.CheckedNodes == treenode);
toggle = currValue ~= value;
end

function mustBeScalarLogical(value)
validateattributes(value, {'logical'}, {'scalar'});
end

function validateParent(menu)
if isempty(ancestor(menu, 'matlab.ui.container.ContextMenu'))
    error(message('MATLAB:uiautomation:Driver:InvalidContextMenuOption'));
end
end