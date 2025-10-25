classdef (Hidden) DefaultCheckedNodesStrategy < matlab.ui.container.internal.model.TreeCheckedNodesStrategy
    %DEFAULTCHECKEDNODESSTRATEGY Implementation of a strategy to handle the
    %CheckedNodes property in a Tree
    
    % Copyright 2019-2020 The MathWorks, Inc.
    
    methods
        
        function leafNodes = getCheckedDescendantsToAdd(obj, checkedNodes)
            % GETDESCENDENTSMISSINGFROMCHECKEDNODES - Return the leaf nodes
            % that do not exist in the checkedNodes.
            
            if isempty(checkedNodes)
                leafNodes = [];
            else
                descendants = findall(checkedNodes);
                
                % Check all descendents to see if they exist in the
                % checkednodes
                isNodeMember = obj.Tree.ismemberForNodes(descendants, checkedNodes);
                leafNodes = descendants(~isNodeMember);
            end
        end
        
        function nodes = getCheckedAncestorsToAdd(obj, existingCheckedNodes, varargin)
            % GETCHECKEDANCESTORSTOADD - Analyze the checked nodes.  If all
            % nodes in a branch are checked, add parent of those nodes if 
            % required.  Do this parent check recursively.
           existingAncestorsToAdd = [];
           existingAncestorsToAdd = obj.getParentNodesWhenAllChildrenAreInCheckedNodes(existingAncestorsToAdd, existingCheckedNodes,varargin{:});
           nodes = [existingAncestorsToAdd(:)];
        end
    end
    
    methods(Access = private)
        function parentNodesToAdd = getParentNodesWhenAllChildrenAreInCheckedNodes(obj, parentNodesToAdd, checkedNodes, nodesToFilter)
            % GETPARENTNODESWHENALLCHILDRENAREINCHECKEDNODES - If all
            % are checked, the appropriate parent/ancestors will need to be
            % added to the CheckedNodes.
            %
            % tree - CheckBox tree that is the ultimate root of the nodes
            % parentNodesToAdd - Parents identified to add.  This supports
            % the recursive functionality of this function
            % checkedNodes - The nodes known to be checked.
            % nodesToFilter - Nodes to ignore in the calculation of
            % whether all children are checked.  This is typically a node
            % in the process of being deleted/removed.
            
            if nargin < 4
                nodesToFilter = [];
            end
            
            if ~isempty(checkedNodes)
                % Gather parent nodes of all checked nodes
                parentsToCheck = unique([checkedNodes(:).Parent], 'stable');
                
                % Filter out values that are not tree nodes
                % Remove the tree which is not a treenode.
                parentsToCheck = parentsToCheck(parentsToCheck ~= obj.Tree);
                
                % Filter values that are already part of the checked nodes
                parentsToCheck = parentsToCheck(~obj.Tree.ismemberForNodes(parentsToCheck, checkedNodes));
                
                % For each unaccounted for parent, verify the parent should or
                % should not be added to the CheckedNodes
                for index = numel(parentsToCheck):-1:1
                    allChildren = allchild(parentsToCheck(index));
                    filteredChildren = allChildren(~obj.Tree.ismemberForNodes(allChildren, nodesToFilter));
                    if ~all(obj.Tree.ismemberForNodes(filteredChildren, checkedNodes))
                        parentsToCheck(index) = [];
                    end 
                end
                
                % If there are parents meeting the criteria, recursively check
                % their parent nodes for inclusion in the CheckedNodes
                if ~isempty(parentsToCheck)
                    newParent = obj.getParentNodesWhenAllChildrenAreInCheckedNodes(parentNodesToAdd, parentsToCheck);
                    parentNodesToAdd = [parentsToCheck(:); newParent(:)];
                end
            end
            
        end
    end
end

