classdef (Hidden) ExpandableComponent < handle & appdesservices.internal.interfaces.model.AbstractModelMixin
    
    % ExpandableComponent provides the functionality to expand or collapse
    % TreeNodes
    
    % Copyright 2016 The MathWorks, Inc.
    
    methods
        function obj = ExpandableComponent(varargin)
            
        end
        
    end
    
    methods(Access = 'public')
        function expand(obj, varargin)
            % EXPAND - Expand tree or treenode
            %
            %    EXPAND(parent) - expands the nodes of a tree or treenode.
            %    If parent is a Tree object, then the top-level nodes
            %    display in an expanded state.  If parent is a TreeNode
            %    object, then that node displays in an expanded state.
            %
            %    EXPAND(parent,'all') - expands all nodes of a tree or
            %    treenode
            %
            %    See also COLLAPSE, MOVE, matlab.ui.container.Tree/scroll, UITREE, UITREENODE
            
            validateattributes(obj,...
                {'matlab.ui.container.internal.model.mixin.ExpandableComponent'}, {});
            narginchk(1, 2);
            
            
            obj.processExpandableMethod('expand', varargin{:})
            
        end
        
        function collapse(obj, varargin)
            % COLLAPSE - Collapse tree or treenode
            %
            %    COLLAPSE(parent) - collapses the nodes of a tree or treenode.
            %    If parent is a Tree object, then the top-level nodes
            %    display in a collapsed state.  If parent is a TreeNode
            %    object, then that node display in an collapsed state.
            %
            %    COLLAPSE(parent,'all') - collapses all nodes of a tree or
            %    treenode
            %
            %    See also EXPAND, MOVE, matlab.ui.container.Tree/scroll, UITREE, UITREENODE 
            
            validateattributes(obj,...
                {'matlab.ui.container.internal.model.mixin.ExpandableComponent'}, {});
            narginchk(1, 2);
            
            obj.processExpandableMethod('collapse', varargin{:})
            
        end
    end
    
    methods (Access = private)
        
        function nodes = getExpandableNodes(obj, flag)
            % Return all nodes with children to be expanded/collapsed.
            nodes = getTargetNodes(obj);
            
            if strcmp(flag, 'all')
                % Search all descendents that do not currently have
                % children (implied here is that the view would have
                % an expansionhandle)
                nodes = findall(nodes, '-not', 'Children', matlab.graphics.GraphicsPlaceholder.empty());
            else
                % Search only the nodes array for noddes that do not
                % currently have children (implied here is that the view
                % would have an expansion handle)
                nodes = findobj(nodes, 'flat', '-not', 'Children', matlab.graphics.GraphicsPlaceholder.empty());
            end
        end
        
        function nodes = getTargetNodes(obj)
            % Return all nodes with children to be expanded/collapsed.
            if isa(obj, 'matlab.ui.container.TreeNode')
                nodes = obj;
            else                
                nodes = allchild(obj);
            end
        end
        
        function processExpandableMethod(obj, eventName, flag)
            % Shared function for expand and collapse
            % eventName = 'expand' or 'collapse'
            % eventHandle = @expand, @collapse
            % flag, 'all', or nothing
            
            if nargin == 3
                validString = validatestring(flag, {'all'});
            else
                validString = '';
            end

            if ~isempty(allchild(obj))
                % View has not been created, cache any instructions
            
                expandableNodes = obj.getExpandableNodes(validString);
                targetNodes = obj.getTargetNodes();    
                if ~isempty(expandableNodes)

                    eventData = struct('Name', eventName);
                    eventData.RequiresMetadata = false;
                    eventData.NodeIds = [expandableNodes.NodeId];
                    eventData.Data = struct('Nodes', [targetNodes.NodeId], 'Flag', validString);
                    handleNodeEvent(obj, eventData);
                end
            end
        end
    end
    
    methods (Abstract, Access = {?matlab.ui.container.internal.model.ContainerModel, ...
            ?matlab.ui.container.internal.model.mixin.ExpandableComponent})
        
        handleNodeEvent(obj, eventData)
        
    end
end


