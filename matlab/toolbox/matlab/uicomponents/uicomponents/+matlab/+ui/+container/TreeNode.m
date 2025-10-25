classdef (Sealed, ConstructOnLoad=true) TreeNode < ...
        ... Framework classes
        matlab.ui.container.internal.model.ContainerModel & ...
        ... Property Mixins
        matlab.ui.control.internal.model.mixin.IconableComponent & ...
        matlab.ui.container.internal.model.mixin.ExpandableComponent & ...   
        matlab.ui.control.internal.model.mixin.IconIDableComponent
    %
    
    % Do not remove above white space
    % Copyright 2016-2021 The MathWorks, Inc.
    
    properties(Dependent, AbortSet)
        Text = getString(message('MATLAB:ui:defaults:treenodeText'));
    end

    properties(Dependent)
        NodeData = [];
    end
    
    properties(Access = 'private')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set
        
        PrivateText = getString(message('MATLAB:ui:defaults:treenodeText'));
        PrivateNodeData = [];
    end
    
    properties(NonCopyable, Transient, Access = private)
        % Save reference to tree for efficiency. 
        PrivateTree = [];
    end
    properties(NonCopyable, Transient, SetAccess = immutable,  GetAccess = ...
            {?matlab.ui.internal.componentframework.services.optional.ControllerInterface,...
            ?matlab.ui.container.Tree, ...
            ?matlab.ui.container.internal.model.mixin.ExpandableComponent,...
            ?matlab.ui.container.internal.model.TreeComponentSelectionStrategy,...
            ?matlab.ui.container.internal.model.TreeNodeManager, ...
            ?matlab.ui.eventdata.CheckedNodesChangedData, ...
            ?matlab.ui.control.internal.model.mixin.StyleableComponent})
        
        % Unique ID to identify the node
        NodeId = "";
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = TreeNode(varargin)
            %
            
            % Do not remove above white space
            % Override the default values
            
            obj.Type = 'uitreenode';
            
            pvPairs = varargin;
            
            % Handle Node Set
            if numel(pvPairs) >= 2 && strcmp(pvPairs{1}, 'NodeId')
                % Client driven workflow
                nodeId = pvPairs{2};
                validateattributes(nodeId, {'string'}, {'scalar'});
                obj.NodeId = nodeId;
                pvPairs(1:2) = [];
            else
                % Commandline driven workflow
                obj.NodeId = matlab.lang.internal.uuid();
            end
            
            %opt out of predefined icons 
            obj.AllowedPresets = {};
            
            % Handle all other property sets
            parsePVPairs(obj,  pvPairs{:});

            obj.ValidateChildFcn = @validateChild;
        end
        
    end
    
    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        
        function set.Text(obj, newValue)
            
            % Error Checking
            try
                newValue = matlab.ui.control.internal.model.PropertyHandling.validateText(newValue);
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidTextValue', ...
                    'Text');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidText';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            % Property Setting
            obj.PrivateText = newValue;
            
            obj.markPropertiesDirty({'Text'});
        end
        
        function value = get.Text(obj)
            value = obj.PrivateText;
        end
        
        % ----------------------------------------------------------------------
        function set.NodeData(obj, newValue)
            % Property Setting
            obj.PrivateNodeData = newValue;
            
            obj.markPropertiesDirty({'NodeData'});
        end
        
        function value = get.NodeData(obj)
            value = obj.PrivateNodeData;
        end
        
    end
    
    methods
        
        function move(obj, targetNode, direction)
            % MOVE - Move tree node
            %
            %    MOVE(targetnode,siblingnode) - moves the target node
            %    after the specified sibling node
            %
            %    MOVE(targetnode,siblingnode,location) - moves the target
            %    node after or before the specified sibling node.  Specify
            %    location as 'after' or 'before'.
            %
            %    See also COLLAPSE, EXPAND, matlab.ui.container.Tree/scroll, UITREE, UITREENODE
            
            narginchk(2,3);
            
            if nargin == 3
                direction = validatestring(direction, {'after', 'before'});
            else 
                % Default value is 'after'
                direction = 'after';
            end   
            
            try
                % All node related error checking.
                validateMoveArguments(obj, targetNode);
                
                % Capture tree state to restore after move
                thisTree = obj.getTree();
                newTree = targetNode.getTree();
              
                cachedTreeData = struct();
                if ~isempty(newTree)
                    % The SelectedNodes of the new tree are the ones likely
                    % to get corrupted via reordering. They should be
                    % restored.
                    cachedTreeData = newTree.getDataToRestoreAfterMove();
                end
                
                % doMove assumes valid inputs
                doMove(obj, targetNode, direction);
                
                % Restore tree state if doMove was executed successfully
                if ~isempty(fields(cachedTreeData))
                    set(newTree, cachedTreeData);                    
                end
                
            catch me
                throw(me);
            end
        end
    end
    methods(Access = 'private')
        function validateMoveArguments(obj, targetNode)
           
            % Do error checking and throw error if necessary
            % Check first if it is a valid node
            if ~all(isa(obj, 'matlab.ui.container.TreeNode'))
            
                % throw error
                messageObj =  message('MATLAB:ui:components:firstArgumentRequiresTreeNode');
                
                % Use string from object
                messageText = getString(messageObj);
                
                error('MATLAB:ui:TreeNode:firstArgumentRequiresTreeNode', messageText);
                
            elseif ~all(isa(targetNode, 'matlab.ui.container.TreeNode'))
            
                % throw error
                messageObj =  message('MATLAB:ui:components:targetRequiresTreeNode');
                
                % Use string from object
                messageText = getString(messageObj);
                
                error('MATLAB:ui:TreeNode:targetRequiresTreeNode', messageText);

            elseif ~isscalar(obj)
                
                % throw error
                messageObj =  message('MATLAB:ui:components:requiresScalarTreeNode');
                
                % Use string from object
                messageText = getString(messageObj);
                
                error('MATLAB:ui:TreeNode:requiresScalarTreeNode', messageText);
                
            elseif ~isscalar(targetNode)
                
                % throw error
                messageObj =  message('MATLAB:ui:components:requiresScalarTargetTreeNode');
                
                % Use string from object
                messageText = getString(messageObj);
                
                error('MATLAB:ui:TreeNode:requiresScalarTargetTreeNode', messageText);
                
             elseif isempty(targetNode.Parent)
                % This if statement assumes that targetNode is scalar which
                % is verified above.
                 
                % throw error
                messageObj =  message('MATLAB:ui:components:targetIsNotParentedTreeNode');
                
                % Use string from object
                messageText = getString(messageObj);
                
                error('MATLAB:ui:TreeNode:targetIsNotParentedTreeNode', messageText);
                
            end
        end
        
        function doMove(obj, targetNode, direction)
            if (isequal(obj, targetNode))
                % Moving a node above/below itself would not change the
                % children order.
            else
                % Reorder Children
                
                
                existingChildren = allchild(targetNode.Parent);
                if ~isequal(obj.Parent, targetNode.Parent)                   
                    obj.Parent = targetNode.Parent;
                else
                    existingChildren = existingChildren(existingChildren~=obj);
                end
                
                insertIndex = find(existingChildren == targetNode);
                
                if isequal(direction, 'before')
                    % Child order is inverse of visual order
                    targetNode.Parent.Children = ...
                        [existingChildren(1:insertIndex-1);...
                        obj;...
                        existingChildren(insertIndex:end)];
                elseif isequal(direction, 'after')
                    % Child order is inverse of visual order
                    targetNode.Parent.Children = ...
                        [existingChildren(1:insertIndex);...
                        obj;...
                        existingChildren(insertIndex+1:end)];
                end
                
                eventData = struct('Name', 'nodeMove');
                eventData.RequiresMetadata = false;
                eventData.NodeIds = obj.NodeId;
                eventData.Data = struct(...
                    'id', obj.NodeId,...
                    'parent', targetNode.Parent.NodeId,...
                    'options', struct('node', targetNode.NodeId, 'place', direction));
                handleNodeEvent(obj, eventData);
            end
        end
        
    end
    % ---------------------------------------------------------------------
    % Custom Display Functions
    % ---------------------------------------------------------------------
    methods(Access = protected)
        
        function names = getPropertyGroupNames(obj)
            % GETPROPERTYGROUPNAMES - This function returns common
            % properties for this class that will be displayed in the
            % curated list properties for all components implementing this
            % class.
            
            names = {'Text',...
                'Icon',...
                'NodeData'};
            
        end
        
        function str = getComponentDescriptiveLabel(obj)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            str = obj.Text;
            
        end
    end
    
    methods(Access = 'protected')
        
        function validateParentAndState(obj, newParent)
            % Validator for 'Parent'
            %
            % Can be extended / overriden to provide additional validation
            
            % Error Checking
            %
            % A valid parent is one of:
            % - a parenting component
            % - empty []
            
            % Only validate if the value is non empty
            %
            % Empty values are acceptible for not having a parent
            if(~isempty(newParent))
                
                if ~(isa(newParent, 'matlab.ui.container.internal.model.TreeComponent')||...
                        isa(newParent, 'matlab.ui.container.TreeNode'))
                    
                    messageObj = message('MATLAB:ui:components:invalidTreeNodeParent', ...
                        'Parent');
                    
                    % MnemonicField is last section of error id
                    mnemonicField = 'invalidParent';
                    
                    % Use string from object
                    messageText = getString(messageObj);
                    
                    % Create and throw exception
                    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                    throw(exceptionObject);
                    
                end
            end
            
            % Clean up old parent
            oldTree = obj.getTree();
            
            newTree = [];
            if ~isempty(newParent)
                newTree = newParent.getTree();
            end
            
            % Handle node being removed within old tree
            if ~isempty(oldTree) && ~isequal(oldTree, newTree)
                oldTree.handleDescendentRemoved(obj);
                
                % Clean up tree reference.
                obj.PrivateTree = [];
            end
            
            % Handle node being added within tree
            if ~isempty(newTree)
                if isequal(newTree, oldTree)
                    % TreeNode is newly added or moved within the tree
                    newTree.handleDescendentMoved(obj, newParent);
                else
                    newTree.handleDescendentAdded(obj, newParent);
                end
            end    
        end

        function validateChild(obj, newChild)
            % Validator for 'Child'
            %
            % Can be extended / overriden to provide additional validation
            
            % Error Checking
            %
            % A valid child is one of:
            % - TreeNode
            % - ... and that's it!
            
            % Only validate if the value is non empty
            %
            % Empty values are acceptible for not having a parent
            if(~isempty(newChild))
                
                if ~(isa(newChild, 'matlab.ui.container.TreeNode'))
 
                    messageObj = message('MATLAB:ui:components:invalidTreeOrNodeChild', ...
                        'Parent', class(newChild));
                    
                    % MnemonicField is last section of error id
                    mnemonicField = 'invalidParent';
                    
                    % Use string from object
                    messageText = getString(messageObj);
                    
                    % Create and throw exception
                    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                    throwAsCaller(exceptionObject);
                   
                end
            end            
        end

    end
    methods
        function delete(obj)

            tree = obj.getTree();
            
            % Allow tree to handle the node removal
            % This may mutate the SelectedNodes property of the tree
            if ~isempty(tree) &&  isvalid(tree) && strcmp(tree.BeingDeleted, 'off')
                tree.handleDescendentRemoved(obj);
            end
            
            % Clean up object.
            obj.PrivateTree = [];

        end
    end
    
     methods (Hidden)
         function controller = createController(~, ~, ~ ) 
           % Do nothing 
           controller = [];
        end
    end
    methods (Access = private)
        
        function tree = getTree(obj)
            
             % Cache tree reference for future use.
             if isempty(obj.PrivateTree)
                 tree = ancestor(obj, {'uitree', 'uicheckboxtree'});
                 obj.PrivateTree = tree;
             end
             
             tree = obj.PrivateTree;
        end
    end
    
    methods (Access = {?matlab.ui.container.internal.model.ContainerModel, ...
            ?matlab.ui.container.internal.model.mixin.ExpandableComponent})   
        function handleNodeEvent(obj, eventData)
             
            tree = obj.getTree();
            
             % if treenode is not parented to a tree, do not cache actions
             if ~isempty(tree)
                 tree.handleNodeEvent(eventData);
             end

        end   
    end
    properties (Access = private)
        % Properties that will trigger a view update
        RegisteredMetadataProperties = ["NodeId", "Text", "Icon", "ContextMenu", "IconID"];
    end
    methods(Access = {...
        ?matlab.ui.container.internal.model.TreeNodeManager})
    
        function metadata = getNodeMetadata(obj)
                        
            validNodes = obj(isvalid(obj));
            
            if isempty(validNodes)
                metadata = [];
            else
                % Assign generic properties.  Assume that obj may be a vector.
                % Struct will populate a vector of matching length.
                metadata = struct(...
                    'id', get(validNodes, 'NodeId'),...
                    'label', get(validNodes, 'PrivateText'),...
                    'iconID', get(validNodes, 'IconID'),...
                    'iconUri', get(validNodes, 'IconURL'));
            
                for index = 1:numel(validNodes)
                    % Assign parent information
                    if isempty(validNodes(index).Parent)
                        parentId = "";
                    else
                        parentId = validNodes(index).Parent.NodeId;
                    end

                    metadata(index).parent = parentId;
                    
                    % Assign ContextMenu ID
                    if(isempty(validNodes(index).ContextMenu))
                        metadata(index).contextMenuID = '';
                    else
                        metadata(index).contextMenuID = validNodes(index).ContextMenu.ObjectID;
                    end
                end
            end
        end
    end
    
    methods(Access = {...
            ?appdesservices.internal.interfaces.model.AbstractModel, ...
            ?appdesservices.internal.interfaces.model.AbstractModelMixin})

        function markPropertiesDirty(obj, propertyNames)
            % MARKPROPERTIESDIRTY - Leverage dirty mechanism to inform the
            % tree that a descendent requires an update.
            if isvalid(obj) && isempty(obj.Controller)   
                import appdesservices.internal.util.ismemberForStringArrays;
                if any(ismemberForStringArrays(string(propertyNames), obj.RegisteredMetadataProperties))                 
                    eventData = struct('Name', 'nodeEdit');
                    eventData.RequiresMetadata = true;
                    eventData.NodeIds = obj.NodeId;
                    eventData.Data = obj;
                    handleNodeEvent(obj, eventData);
                end
            else
                % If tree node is environment that uses standard
                % controller, pass dirty property information to super
                markPropertiesDirty@matlab.ui.container.internal.model.ContainerModel(obj, propertyNames);
            end
        end
    end
    
    methods(Access='public', Static=true, Hidden=true)
      function varargout = doloadobj( hObj) 
          % DOLOADOBJ - Graphics framework feature for loading graphics
          % objects
          
          % on component loading, property set will not trigger marking 
          % dirty, so disable view property cache
          % Todo: enable it when we have a better design for loading
          % Todo: need a better way to disable cache instead of in invidudal
          % subclass
          hObj.disableCache();

          hObj = doloadobj@matlab.ui.control.internal.model.mixin.IconableComponent(hObj);
          varargout{1} = hObj;
      end
   end
end



