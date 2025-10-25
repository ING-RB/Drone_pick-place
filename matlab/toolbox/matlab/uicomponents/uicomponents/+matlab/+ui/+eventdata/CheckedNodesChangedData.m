classdef CheckedNodesChangedData < matlab.ui.eventdata.internal.AbstractEventData
    % This class is for the event data of 'CheckedNodesChanged' events
    
    % Copyright 2019-2020 The MathWorks, Inc.
    
    properties(SetAccess = 'private')
        CheckedNodes;
        
        PreviousCheckedNodes;
    end
    
    properties(Dependent)
        
        ParentCheckedNodes;
        
        PreviousParentCheckedNodes;
        
        LeafCheckedNodes;
        
        PreviousLeafCheckedNodes;
        
        IndeterminateCheckedNodes;
        
        PreviousIndeterminateCheckedNodes;
    end
    
    properties(Hidden, Access = private)
        
        PrivateParentCheckedNodes = "";
        
        PrivatePreviousParentCheckedNodes = "";
        
        PrivateLeafCheckedNodes = "";
        
        PrivatePreviousLeafCheckedNodes = "";
        
        PrivateIndeterminateCheckedNodes = "";
        
        PrivatePreviousIndeterminateCheckedNodes = "";
    end
    
    methods
        function obj = CheckedNodesChangedData(newCheckedNodes, oldCheckedNodes)
            % The new and old value are required input.
            
            narginchk(2, 2);
            
            % Populate the properties
            obj.CheckedNodes = newCheckedNodes;
            obj.PreviousCheckedNodes = oldCheckedNodes;
            
        end
    end
    
    methods
        function nodes = get.LeafCheckedNodes(obj)
            % LEAFCHECKEDNODES - Checked nodes which are also
            % leaf nodes
            nodes = obj.PrivateLeafCheckedNodes;
            
            % If nodes have never been calculated they will be the default
            if isstring(nodes)
                % Leaf nodes will not have children
                nodes = findall(obj.CheckedNodes, 'flat', 'Children', matlab.graphics.GraphicsPlaceholder.empty);
                obj.PrivateLeafCheckedNodes = nodes;
            end
            
        end
        
        function nodes = get.PreviousLeafCheckedNodes(obj)
            % PREVIOUSLEAFCHECKEDNODES - Checked nodes which are also
            % leaf nodes
            nodes = obj.PrivatePreviousLeafCheckedNodes;
            % If nodes have never been calculated they will be the default
            if isstring(nodes)
                % Leaf nodes will not have children
                nodes = findall(obj.PreviousCheckedNodes, 'flat', 'Children', matlab.graphics.GraphicsPlaceholder.empty);
                obj.PrivatePreviousLeafCheckedNodes = nodes;
            end
            
        end
        
        function nodes = get.ParentCheckedNodes(obj)
            % PARENTCHECKEDNODES - Checked nodes which are also
            % parent nodes
            nodes = obj.PrivateParentCheckedNodes;
            % If nodes have never been calculated they will be the default
            if isstring(nodes)
                % Parent nodes will have children
                nodes = findall(obj.CheckedNodes, 'flat', '-not', 'Children', matlab.graphics.GraphicsPlaceholder.empty);
                obj.PrivateParentCheckedNodes = nodes;
            end
        end
        
        function nodes = get.PreviousParentCheckedNodes(obj)
            % PREVIOUSPARENTCHECKEDNODE - Checked nodes which are also
            % parent nodes
            nodes = obj.PrivatePreviousParentCheckedNodes;
            % If nodes have never been calculated they will be the default
            if isstring(nodes)
                % Parent nodes will have children
                nodes = findall(obj.PreviousCheckedNodes, 'flat', '-not', 'Children', matlab.graphics.GraphicsPlaceholder.empty);
                obj.PrivatePreviousParentCheckedNodes = nodes;
            end    
        end
        
        function nodes = get.IndeterminateCheckedNodes(obj)
            % INDETERMINATECHECKEDNODES - Nodes that are neither
            % checked nor unchecked.  These will all be parent nodes.
            nodes = obj.PrivateIndeterminateCheckedNodes;
            
            % If nodes have never been calculated they will be the default
            if isstring(nodes)
                nodes = obj.calculateIndeterminateNodes(obj.CheckedNodes);
                obj.PrivateIndeterminateCheckedNodes = nodes;
            end
        end
        
        function nodes = get.PreviousIndeterminateCheckedNodes(obj)
            % PREVIOUSINDETERMINATECHECKEDNODES - Nodes that are neither
            %  checked nor unchecked.  These will all be parent nodes.
            nodes = obj.PrivatePreviousIndeterminateCheckedNodes;
            % If nodes have never been calculated they will be the default
            if isstring(nodes)
                nodes = obj.calculateIndeterminateNodes(obj.PreviousCheckedNodes);
                obj.PrivatePreviousIndeterminateCheckedNodes = nodes;
            end
        end
    end
    methods (Static, Access = private)
        
        function nodes = calculateIndeterminateNodes(checkedNodes)
            % CALCULATEINDETERMINATENODES - Given a set of leaf nodes, this
            % function returns every parent/ ancestor node which in the
            % view would be indeterminate (black box in view).
            
            import appdesservices.internal.util.ismemberForStringArrays;
            
            nodes = matlab.graphics.GraphicsPlaceholder.empty(0,1);
            if ~isempty(checkedNodes)
                checkedIds = [checkedNodes.NodeId];
                for index = numel(checkedNodes):-1:1
                
                    % If parent of leaf node is checked, ignore it
                    % Leverage node id to improve comparison performance
                    if ~ismemberForStringArrays(checkedNodes(index).Parent.NodeId, checkedIds)
                    
                        % Climb the hierarchy until the tree/check box tree
                        nodes = [matlab.ui.eventdata.CheckedNodesChangedData.getParentNodesRecursively(nodes, checkedNodes(index)); nodes];
                    end
                
                
                end
                nodes = unique(nodes, 'stable');
            end
        end
        
        function nodes = getParentNodesRecursively(allParents, node)
            
            % Return each parent until the tree is hit.
            nodes = allParents;
            if isa(node.Parent, 'matlab.ui.container.TreeNode')
                % The parent is indeterminate, so collect all parents of
                % this node.
                nodes = matlab.ui.eventdata.CheckedNodesChangedData.getParentNodesRecursively([node.Parent; allParents], node.Parent);
            end
        end
    end
    
    % ---------------------------------------------------------------------
    % Custom Display Functions
    % This class inherits from event.EventData so this class will always
    % have the two properties 'Source' and 'Event'
    % These properties will be filtered so they always appear at the bottom
    % of the properties list.
    % ---------------------------------------------------------------------
    methods(Access = protected)
        
        function names = getPropertyGroupNames(obj)
            % GETPROPERTYGROUPNAMES - This function returns common
            % properties for this class that will be displayed in the
            % curated list properties for all components implementing this
            % class.
            
            superClassProperties = properties(event.EventData);
            
            % Add only the most important properties to the custom display
            names = {'LeafNodes'; 'CheckedNodes'; 'PreviousCheckedNodes'};
            
            % Add the super class properties to the end of the display
            names = [names; superClassProperties];
                
        end   
    end
end

