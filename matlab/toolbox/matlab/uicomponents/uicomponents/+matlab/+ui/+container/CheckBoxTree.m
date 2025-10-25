classdef (Sealed, ConstructOnLoad=true) CheckBoxTree <  ...
        ... Shared tree functionality
        matlab.ui.container.internal.model.TreeComponent
%CHECKBOXTREE Create check box tree component
%   cbxt = matlab.ui.container.CheckBoxTree creates a check box tree
%   and returns the CheckBoxTree object. No parent is created.
%
%   cbxt = matlab.ui.container.CheckBoxTree('Parent',parent) creates a
%   check box tree in the specified parent container.
%   The parent container can be a figure created using the uifigure
%   function, or one of its child containers: Tab, Panel, ButtonGroup or
%   GridLayout
%
%   cbxt = matlab.ui.container.CheckBoxTree(______,Name,Value)
%   specifies CheckBoxTree property values using one or more
%   Name,Value pair arguments. Use this option with any of the input
%   argument combinations in the previous syntaxes.
%
%   matlab.ui.container.CheckBoxTree properties:
%     Node properties:
%       CheckedNodes     - An array of nodes in checked state
%       SelectedNodes    - An array of nodes in selected state
%
%     Font and Color properties:
%       FontName         -  Font name
%       FontSize         -  Font size
%       FontWeight       -  Font weight
%       FontAngle        -  Font angle
%       FontColor        -  Font color
%       BackgroundColor  -  Background color
%
%     Interactivity properties:
%       Visible          -  Tree visibility
%       Editable         -  Node text editability
%       Enable           -  Operational state of tree
%       Tooltip          -  Tooltip
%
%     Position properties:
%       Position         - Location and size
%       InnerPosition    - Location and size
%       OuterPosition    - Location and size
%       Layout           - Layout options
%
%     Callback properties:
%       CheckedNodesChangedFcn - Checked nodes changed callback
%       SelectionChangedFcn    - Selection changed callback
%       NodeExpandedFcn        - Node expanded callback
%       NodeCollapsedFcn       - Node collapsed callback
%       CreateFcn              - Creation function
%       DeleteFcn              - Deletion function
%
%     Callback execution control properties:
%       Interruptible    - Callback interruption
%       BusyAction       - Callback queuing
%       BeingDeleted     - Deletion status
%
%     Parent/child properties:
%       Parent           - Parent container
%       Children         - Children
%       HandleVisibility - Visibility of object handle
%
%     Identifier properties:
%       Type             - Type of graphics object
%       Tag              - Object identifier
%       UserData         - User data
%
%   matlab.ui.container.CheckBoxTree supported functions:
%      collapse          - Collapse tree node
%      expand            - Expand tree node
%      scroll            - Scroll to location within check box tree
%
%   Example: Check Box Tree with Nested Nodes
%      fig = uifigure;
%      cbxt = matlab.ui.container.CheckBoxTree('Parent',fig);
%
%      % Assign Tree callback in response to node selection
%      cbxt.CheckedNodesChangedFcn = @(src,event)display(event);
%      cbxt.SelectionChangedFcn = @(src,event)display(event);
%
%      % First level nodes
%      category1 = uitreenode(cbxt,'Text','Runners','NodeData',[]);
%      category2 = uitreenode(cbxt,'Text','Cyclists','NodeData',[]);
%
%      % Second level nodes.
%      % Node data is age (y), height (m), weight (kg)
%      p1 = uitreenode(category1,'Text','Joe','NodeData',[40 1.67 58]);
%      p2 = uitreenode(category1,'Text','Linda','NodeData',[49 1.83 90]);
%      p3 = uitreenode(category2,'Text','Rajeev','NodeData',[25 1.47 53]);
%      p4 = uitreenode(category2,'Text','Anne','NodeData',[88 1.92 100]);
%
%      % Expand tree to see all nodes
%      expand(cbxt,'all');
%
%      % Initialize all nodes as checked
%      cbxt.CheckedNodes = cbxt.Children;
%
%   See also UIFIGURE, UITREENODE, UITREE

% Copyright 2019-2021 The MathWorks, Inc.

    properties(Dependent, AbortSet)
        %CheckedNodes - Checked nodes specified as a TreeNode or an array
        %   of TreeNode objects.  Use this property to get or set the
        %   checked nodes in a tree
        CheckedNodes = [];
    end

    properties(Access = {?appdesservices.internal.interfaces.model.AbstractModel}, ReconnectOnCopy=true)
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set

        PrivateCheckedNodes = [];
    end

    properties(NonCopyable, Dependent, AbortSet)
        %CheckedNodesChangedFcn - Checked nodes changed callback.  Use this
        %   callback function to execute commands when the user checks
        %   different nodes in the check box tree.
        CheckedNodesChangedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback;
    end

    properties(NonCopyable, Access = 'private')

        % Callbacks
        PrivateCheckedNodesChangedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback;

        % Strategy to handle differences in behavior based on Multiselect
        CheckedNodesStrategy
    end

    events(NotifyAccess = {?appdesservices.internal.interfaces.model.AbstractModel})
        CheckedNodesChanged;
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = CheckBoxTree(varargin)
            %

            % Do not remove above white space
            % Override the default values

            % Super
            obj = obj@matlab.ui.container.internal.model.TreeComponent(varargin{:});

            % Wire callbacks
            obj.attachCallbackToEvent('CheckedNodesChanged', 'PrivateCheckedNodesChangedFcn');

            % Store strategy
            obj.CheckedNodesStrategy = matlab.ui.container.internal.model.DefaultCheckedNodesStrategy(obj);
            obj.Type = 'uicheckboxtree';
        end

        % ----------------------------------------------------------------------
        function set.CheckedNodes(obj, checkedNodes)

            try
                % Validate nodes
                checkedNodes = obj.CheckedNodesStrategy.validateTreeNodes(checkedNodes);

                % Add descendents when parent is checked
                leafNodesToAdd = obj.CheckedNodesStrategy.getCheckedDescendantsToAdd(checkedNodes);

                % Add ancestor if all children in branch are checked
                parentNodesToAdd = obj.CheckedNodesStrategy.getCheckedAncestorsToAdd(checkedNodes);

                % Combine all nodes
                checkedNodes = unique([checkedNodes; leafNodesToAdd; parentNodesToAdd], 'stable');

            catch me

                % Create and throw exception
                messageObj = message('MATLAB:ui:components:checkedNodesInvalid', 'CheckedNodes');

                % MnemonicField is last section of error id
                mnemonicField = 'checkedNodesInvalid';

                % Use string from object
                messageText = getString(messageObj);

                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
            end

            % Property Setting
            obj.doSetCheckedNodes(checkedNodes);

        end

        function value = get.CheckedNodes(obj)
            value = obj.PrivateCheckedNodes;
        end

        % ----------------------------------------------------------------------

        function set.CheckedNodesChangedFcn(obj, newValue)
            % Property Setting
            obj.PrivateCheckedNodesChangedFcn = newValue;

            obj.markPropertiesDirty({'CheckedNodesChangedFcn'});
        end

        function value = get.CheckedNodesChangedFcn(obj)
            value = obj.PrivateCheckedNodesChangedFcn;
        end

        % ----------------------------------------------------------------------

    end
    methods(Access = protected)

        % Update the Selection Strategy property
        function updateSelectionStrategy(obj)

            % Since there is no Multiselect or selection modes, the
            % strategy is always the same.
            obj.SelectionStrategy = matlab.ui.container.internal.model.ZeroToOneCheckBoxTreeSelectionStrategy(obj);

         end
    end

    methods(Access = private)

        function doSetCheckedNodes(obj, checkedNodes)
            % DOSETCHECKEDNODES - Update CheckedNodes storage and mark
            % dirty

            if isempty(checkedNodes)
                checkedNodes = [];
            else
                checkedNodes = [checkedNodes(:)];
            end
            obj.PrivateCheckedNodes = checkedNodes;

            obj.markPropertiesDirty({'CheckedNodes'});
        end
    end
    methods(Access = {?matlab.ui.container.TreeNode, ...
            ?matlab.ui.container.internal.model.TreeComponent})
        function handleDescendentRemoved(obj, treeNode)
            % HANDLEDESCENDENTREMOVED - Special handle any tree state that
            % would react when a node is removed (CheckedNodes for example)

            % Handle Tree state
            handleDescendentRemoved@matlab.ui.container.internal.model.TreeComponent(obj, treeNode);

            % Remove node from CheckedNodes
            if ~isempty(obj.CheckedNodes)

                allRemovedTreeNodes = findall(treeNode);

                % Filter nodes for valid nodes only
                nodesToKeep = ~obj.ismemberForNodes(obj.CheckedNodes, allRemovedTreeNodes);
                nodeIsChecked = obj.ismemberForNodes(treeNode, obj.CheckedNodes);

                parentNodesToAdd = [];
                if any(nodesToKeep)

                    parentNode = treeNode.Parent;
                    remainingSiblings = allchild(parentNode);
                    remainingSiblings = remainingSiblings(remainingSiblings ~= treeNode);
                    if ~nodeIsChecked && ~isempty(remainingSiblings)
                        % If you remove the last unchecked node, then the
                        % result will be a branch where all children are
                        % checked.  In this case, the appropriate ancestors
                        % must be added to the CheckedNodes
                        singleBranchCheckedNodes = remainingSiblings(obj.ismemberForNodes(remainingSiblings, obj.CheckedNodes));
                        parentNodesToAdd = obj.CheckedNodesStrategy.getCheckedAncestorsToAdd(singleBranchCheckedNodes, treeNode);
                    end
                end

                % Update privately the checked nodes so that the
                % dependent logic when setting CheckedNodes does not
                % get rerun.
                obj.doSetCheckedNodes([obj.CheckedNodes(nodesToKeep); parentNodesToAdd]);

            end
        end

        function handleDescendentMoved(obj, treeNode, parentNode)
            % HANDLEDESCENDENTREMOVED - Special handle any tree state that
            % would react when a node is moved within tree
            %(CheckedNodes for example)

            % Handle Tree state
            handleDescendentMoved@matlab.ui.container.internal.model.TreeComponent(obj, treeNode, parentNode);

            updateCheckedNodesAfterNodeParentChange(obj, treeNode, parentNode)

        end

        function handleDescendentAdded(obj, treeNode, parentNode)
            % HANDLEDESCENDENTADDED- Special handle any tree state that
            % would react when a node is added to tree
            %(CheckedNodes for example)

            % Handle Tree state
            handleDescendentAdded@matlab.ui.container.internal.model.TreeComponent(obj, treeNode, parentNode);

            updateCheckedNodesAfterNodeParentChange(obj, treeNode, parentNode)

        end

        function updateCheckedNodesAfterNodeParentChange(obj, treeNode, parentNode)
            % UPDATECHECKEDNODESAFTERNODEPARENTCHANGE - When a node changes
            % parent, the checked state may adjust based on its status and
            % the status of the new siblings (or old siblings).

            % Parent can be the tree in the case of load. Tree is not
            % checkable so ignore this case.
            if parentNode ~= obj

                nodeIsChecked = obj.ismemberForNodes(treeNode, obj.CheckedNodes);
                parentIsChecked = obj.ismemberForNodes(parentNode, obj.CheckedNodes);

                if parentIsChecked && ~nodeIsChecked
                    % When moving a node to branch with a checked parent, that
                    % node should become checked
                    obj.doSetCheckedNodes([obj.PrivateCheckedNodes; treeNode]);

                elseif ~parentIsChecked && nodeIsChecked
                    % A checked node should prefer to remain checked.  In
                    % addition, logic to analyze the node's ancestors needs to
                    % be done:

                    % When moving a node to branch with an unchecked parent,
                    % verify that no ancestors need to be checked in
                    % response

                    newSiblings = allchild(parentNode);
                    if isempty(newSiblings)
                        singleBranchCheckedNodes = parentNode;
                        parentNodesToAdd  = [obj.CheckedNodesStrategy.getCheckedAncestorsToAdd(singleBranchCheckedNodes); parentNode];
                    else
                        singleBranchCheckedNodes = newSiblings(obj.ismemberForNodes(newSiblings, obj.CheckedNodes));
                        parentNodesToAdd = obj.CheckedNodesStrategy.getCheckedAncestorsToAdd(singleBranchCheckedNodes);
                    end

                    obj.doSetCheckedNodes([obj.PrivateCheckedNodes; parentNodesToAdd]);

                end
            end
        end
        function treeData = getDataToRestoreAfterMove(obj)
            % GETDATATORESTOREAFTERMOVE - This data will be set on the tree
            % after nodes are moved.  This is required because moving the
            % tree node may be treated as a delete then add which will
            % corrupt tree settings that detect node deletion like
            % selection and checked nodes.
            treeData = getDataToRestoreAfterMove@matlab.ui.container.internal.model.TreeComponent(obj);

            if ~isempty(obj.CheckedNodes)
                treeData.CheckedNodes = obj.CheckedNodes;
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

            names = {'CheckedNodes',...
                'SelectedNodes',...
                'CheckedNodesChangedFcn',...
                'SelectionChangedFcn'};

        end

        function str = getComponentDescriptiveLabel(obj)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            str = '';

        end
    end
    methods (Hidden, Static) 
        function modifyOutgoingSerializationContent(sObj, obj) 

           % sObj is the serialization content for obj 
           modifyOutgoingSerializationContent@matlab.ui.container.internal.model.TreeComponent(sObj, obj);
        end
        function modifyIncomingSerializationContent(sObj) 

           % sObj is the serialization content that was saved for obj 
           modifyIncomingSerializationContent@matlab.ui.container.internal.model.TreeComponent(sObj);
        end 
    end
end
