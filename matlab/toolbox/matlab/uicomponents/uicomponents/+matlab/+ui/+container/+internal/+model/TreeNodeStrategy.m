classdef TreeNodeStrategy
    %TREENODESTRATEGY This object performs validation for the
    %Tree component.  It will be subclassed to allow custom strategies
    %based on the selection state of the tree component.
    
    % Copyright 2019-2020 The MathWorks, Inc.
    
    properties (Access = 'protected')
        Tree
    end
    
    
    methods
        
        function obj = TreeNodeStrategy(tree)
            obj.Tree = tree;
        end
    end
    
    methods
        function output = validateTreeNodes(obj, nodes, maxNodes)
            
            % By default, there is no restriction on how many nodes are
            % expected.
            if nargin < 3
                maxNodes = Inf;
            end
            
            % special check for empty because SelectedNodes is always allowed
            % to be empty, regardless of the size constraints
            if (isequal(nodes, []))
                output = nodes;
                return;
            end
            
            % Remove duplicates from selectedNodes
            nodes = unique(nodes, 'stable');
            
            validateattributes(nodes, ...
                {'matlab.ui.container.TreeNode'}, {'vector'});
            
            validateattributes(numel(nodes), {'numeric'}, ...
                {'<=' maxNodes});
            
            nodesAreValid = nodesAreTreeMember(obj.Tree, nodes);
            
            % Assert that all selected nodes are part of the tree hierarchy
            % Customer facing error will be thrown by calling function
            assert(nodesAreValid, 'Some nodes were not part of tree')
            
            % reshape to column
            output = nodes(:);
        end    
    end   
end

