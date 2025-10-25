classdef  (Hidden) TreeComponent < ...
        ... Framework classes
        matlab.ui.container.internal.model.ContainerModel & ...
        ... Property Mixins
        matlab.ui.control.internal.model.mixin.EnableableComponent & ...
        matlab.ui.control.internal.model.mixin.EditableComponent & ...
        matlab.ui.control.internal.model.mixin.VisibleComponent & ...
        matlab.ui.control.internal.model.mixin.FontStyledComponent & ...
        matlab.ui.control.internal.model.mixin.BackgroundColorableComponent & ...
        matlab.ui.control.internal.model.mixin.HorizontalClippingWithNoneComponent & ...
        matlab.ui.control.internal.model.mixin.PositionableComponent & ...
        matlab.ui.container.internal.model.mixin.ExpandableComponent & ...
        matlab.ui.control.internal.model.mixin.TooltipComponent & ...
        matlab.ui.control.internal.model.mixin.Layoutable & ...
        matlab.ui.control.internal.model.mixin.StyleableComponent & ...
        matlab.ui.control.internal.model.mixin.FocusableComponent & ...
        matlab.ui.control.internal.model.mixin.ClickableComponent & ...
        matlab.ui.control.internal.model.mixin.DoubleClickableComponent


    %

    % Do not remove above white space
    % Copyright 2016-2024 The MathWorks, Inc.

    properties(Dependent, AbortSet)

        SelectedNodes = [];
    end

    properties(NonCopyable, Dependent, AbortSet)
        % Callbacks
        SelectionChangedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback;
        NodeExpandedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback;
        NodeCollapsedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback;
        NodeTextChangedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback;
    end

    properties(Transient, Access = ...
            {?matlab.ui.internal.componentframework.services.optional.ControllerInterface,...
            ?matlab.ui.container.internal.model.TreeComponent, ...
            ?matlab.ui.container.internal.model.mixin.ExpandableComponent,...
            ?matlab.ui.container.internal.model.TreeSelectedNodesStrategy,...
            ?matlab.ui.container.internal.model.TreeNodeManager,...
            ?matlab.ui.eventdata.CheckedNodesChangedData})

        % ID identifying the tree component
        NodeId = "#";
    end

    properties(Access = {?appdesservices.internal.interfaces.model.AbstractModel}, ReconnectOnCopy=true)
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set

        PrivateSelectedNodes = [];
    end

    properties (Transient, Access = {?appdesservices.internal.interfaces.model.AbstractModelMixin})
        TargetEnums = ["tree", "node", "level", "subtree"];
        TargetDefault = "tree";
    end

    methods(Abstract, Access = protected)

        % Update the Selection Strategy property during construction and
        % property sets
        updateSelectionStrategy(obj)
    end

    properties(Access = 'protected')
        % This block must have 'protected' permissions for compatibility
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set

        PrivateMultiselect matlab.internal.datatype.matlab.graphics.datatype.on_off = 'off';

        
    end

    properties(NonCopyable, Access = 'protected')
        % Strategy to handle differences in behavior based on Multiselect
        SelectionStrategy

        % This block must have 'protected' permissions for compatibility
        % Callbacks
        PrivateSelectionChangedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback;
        PrivateNodeExpandedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback;
        PrivateNodeCollapsedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback;
        PrivateNodeTextChangedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback;
    end

    properties (NonCopyable, Transient, SetAccess = immutable, GetAccess = ...
            {?appdesservices.internal.interfaces.controller.AbstractController,...
            ?matlab.ui.internal.componentframework.services.optional.ControllerInterface})

        % Manager for node related events, faciliates populating view
        TreeNodeManager
    end

    events(NotifyAccess = {?appdesservices.internal.interfaces.model.AbstractModel})
        SelectionChanged;
        NodeExpanded;
        NodeCollapsed;
        NodeTextChanged;
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = TreeComponent(varargin)
            %

            % Do not remove above white space
            % Override the default values

            % call super
            obj = obj@matlab.ui.container.internal.model.ContainerModel(varargin{:});

            defaultPosition = [20, 20, 150, 300];
            obj.PrivateOuterPosition = defaultPosition;
            obj.PrivateInnerPosition = defaultPosition;
            obj.Editable = 'off';

            obj.TreeNodeManager = matlab.ui.container.internal.model.TreeNodeManager(obj);
            obj.updateSelectionStrategy();

            parsePVPairs(obj,  varargin{:});

            obj.ValidateChildFcn = @validateChild;

            % Wire callbacks
            obj.attachCallbackToEvent('SelectionChanged', 'PrivateSelectionChangedFcn');
            obj.attachCallbackToEvent('NodeExpanded', 'PrivateNodeExpandedFcn');
            obj.attachCallbackToEvent('NodeCollapsed', 'PrivateNodeCollapsedFcn');
            obj.attachCallbackToEvent('NodeTextChanged', 'PrivateNodeTextChangedFcn');
            obj.attachCallbackToEvent('Clicked', 'PrivateClickedFcn');
            obj.attachCallbackToEvent('DoubleClicked', 'PrivateDoubleClickedFcn');
        end


        % ----------------------------------------------------------------------
        function set.SelectedNodes(obj, newValue)

            try
                newValue = obj.SelectionStrategy.validateSelectedNodes(newValue);
            catch ME

                % Create and throw exception
                exceptionObject = obj.SelectionStrategy.getExceptionObject();
                throw(exceptionObject);
            end

            % Property Setting
            doSetSelectedNodes(obj, newValue);

            obj.markPropertiesDirty({'SelectedNodes'});
        end

        function value = get.SelectedNodes(obj)
            value = obj.PrivateSelectedNodes;
        end

        % ----------------------------------------------------------------------
        function set.SelectionChangedFcn(obj, newValue)
            % Property Setting
            obj.PrivateSelectionChangedFcn = newValue;

            obj.markPropertiesDirty({'SelectionChangedFcn'});
        end

        function value = get.SelectionChangedFcn(obj)
            value = obj.PrivateSelectionChangedFcn;
        end

        % ----------------------------------------------------------------------
        function set.NodeExpandedFcn(obj, newValue)
            % Property Setting
            obj.PrivateNodeExpandedFcn = newValue;

            obj.markPropertiesDirty({'NodeExpandedFcn'});
        end

        function value = get.NodeExpandedFcn(obj)
            value = obj.PrivateNodeExpandedFcn;
        end
        % ----------------------------------------------------------------------
        function set.NodeCollapsedFcn(obj, newValue)
            % Property Setting
            obj.PrivateNodeCollapsedFcn = newValue;

            obj.markPropertiesDirty({'NodeCollapsedFcn'});
        end

        function value = get.NodeCollapsedFcn(obj)
            value = obj.PrivateNodeCollapsedFcn;
        end

        % ----------------------------------------------------------------------
        function set.NodeTextChangedFcn(obj, newValue)
            % Property Setting
            obj.PrivateNodeTextChangedFcn = newValue;

            obj.markPropertiesDirty({'NodeTextChangedFcn'});
        end

        function value = get.NodeTextChangedFcn(obj)
            value = obj.PrivateNodeTextChangedFcn;
        end
    end

    methods

        function scroll(obj, scrollTarget)
            % SCROLL - Scroll to location within tree
            %
            %   SCROLL(component,location) scrolls tree to the specified
            %   location within a tree. The location can be 'top',
            %   'bottom' or a TreeNode object.
            %
            %   See also UITREE

            narginchk(2, 2);
            scrollTarget = convertStringsToChars(scrollTarget);

            validTargets = {'top', 'bottom'};

            % Do error checking and throw error if necessary
            % Check first if it is a valid node
            if (isa(scrollTarget, 'matlab.ui.container.TreeNode') && isscalar(scrollTarget) ...
                    && obj.nodesAreTreeMember(scrollTarget)) ...
                    ... Or is enum values 'top', 'bottom'
                    || ischar(scrollTarget) &&...
                    any(startsWith(validTargets, scrollTarget,'IgnoreCase', true))

                if isa(scrollTarget, 'matlab.ui.container.TreeNode')

                    target = scrollTarget.NodeId;
                else

                    % Value is 'top' or 'bottom'
                    target = string(...
                        validTargets(...
                        startsWith(validTargets, scrollTarget,'IgnoreCase', true)...
                        )...
                        );
                end

                eventData = struct('Name', 'scroll');
                eventData.RequiresMetadata = false;
                eventData.NodeIds = target;
                eventData.Data = struct('Target', target);

                if any(strcmp(target, {'bottom', 'top'}))
                    % Store node reference so that the veiw knows how
                    % long to wait before scrolling
                    eventData.NodeIds = obj.NodeId;
                end

                obj.handleNodeEvent(eventData);
            else
                % throw error
                messageObj =  message('MATLAB:ui:components:invalidTreeScrollTarget', 'top', 'bottom');

                % Use string from object
                messageText = getString(messageObj);

                error('MATLAB:ui:Tree:invalidTreeScrollTarget', messageText);


            end
        end

    end

    methods(Access = protected)
        function doSetSelectedNodes(obj, newValue)
            % Update SelectedNodes value without marking it dirty.
            % This is generally done to consolidate dirty events.
            % Property Setting
            obj.PrivateSelectedNodes = newValue;

        end

        function doSetMultiselect(obj, newValue)
            % Update multiselect value

            % Property Setting
            obj.PrivateMultiselect = newValue;

            % Update selection strategy
            obj.updateSelectionStrategy();

        end

        % STYLEABLE Methods
        function index = validateStyleIndex(obj, target, index)
            if strcmpi(target, 'level') || ...
                    (iscategorical(target) && target == "level")
                target = "level";

                if ~isValidLevelIndex(obj, index)
                    messageObject = message('MATLAB:ui:style:invalidLevelTargetIndex', ...
                        target);
                    % MnemonicField is last section of error id
                    mnemonicField = 'invalidLevelTargetIndex';

                    % Use string from object
                    messageText = getString(messageObject);

                    % Create and throw exception
                    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                    throwAsCaller(exceptionObject);
                else
                    % Ensure index is a row vector
                    index = reshape(index, 1, []);
                end
            elseif strcmpi(target, 'node') || ...
                    (iscategorical(target) && target == "node") || ...
                    strcmpi(target, 'subtree') || ...
                    (iscategorical(target) && target == "subtree")
                target = "node";

                if ~isValidNodeIndex(obj, index)
                    messageObject = message('MATLAB:ui:style:invalidNodeTargetIndex', ...
                        target);
                    % MnemonicField is last section of error id
                    mnemonicField = 'invalidNodeTargetIndex';

                    % Use string from object
                    messageText = getString(messageObject);

                    % Create and throw exception
                    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                    throwAsCaller(exceptionObject);
                else
                    % Ensure index is a row vector
                    index = reshape(index, 1, []);
                end
            end
        end

    end
    methods (Access = private)
        function isValid = isValidLevelIndex(~, idx)
            % A 'level' index is valid if it is a scalar or array of positive integers
            try
                validateattributes(idx,{'numeric'},{'positive','integer','real','finite','vector'});
                isValid = true;
            catch
                isValid = false;
            end
        end

        function isValid = isValidNodeIndex(~, idx)
            try
                validateattributes(idx,{'matlab.ui.container.TreeNode'},{});
                isValid = true;
            catch
                isValid = false;
            end
        end
    end

    properties(Dependent, Access = {?matlab.ui.container.internal.model.TreeNodeManager,...
            ?matlab.ui.container.internal.model.TreeComponent})
        FlatTreeNodeList = matlab.ui.container.TreeNode.empty;
        FlatNodeIdList = string.empty;
    end
    properties(Access = {?matlab.ui.container.internal.model.TreeNodeManager,...
            ?matlab.ui.container.internal.model.TreeComponent})
        PrivateFlatTreeNodeList = matlab.ui.container.TreeNode.empty;
        PrivateFlatNodeIdList = string.empty;
        FlatNodeListIsDirty = true;
    end
    methods

        function nodeList = get.FlatTreeNodeList(obj)

            updateFlatTreeNodeList(obj)
            nodeList = obj.PrivateFlatTreeNodeList;
        end

        function nodeList = get.FlatNodeIdList(obj)

            updateFlatTreeNodeList(obj)
            nodeList = obj.PrivateFlatNodeIdList;
        end

    end

    methods (Access = private)
        function updateFlatTreeNodeList(obj)
            if (obj.FlatNodeListIsDirty)
                % Find all descendent
                obj.PrivateFlatTreeNodeList = findall(allchild(obj));

                % Create matching list of Ids
                if ~isempty(obj.PrivateFlatTreeNodeList)
                    obj.PrivateFlatNodeIdList = [obj.PrivateFlatTreeNodeList.NodeId];
                else
                    obj.PrivateFlatNodeIdList = string.empty;
                end

                obj.FlatNodeListIsDirty = false;
            end
        end
    end

    methods(Access = {?matlab.ui.container.internal.controller.TreeController,...
            ?matlab.ui.container.internal.controller.TreeNodeController,...
            ?matlab.ui.internal.componentframework.services.optional.ControllerInterface})

        function nodes = getNodesById(obj, nodeIds)
            % GETNODESBYID -  Returns node object in tree given id
            %
            %Note: There is minimal validation here because it is assumed
            %the nodeIds all represent nodes in the tree.  Generally this
            %method will be called after selection has changed on the client
            %and it is assumed the client is providing accurate information.

            import appdesservices.internal.util.ismemberForStringArrays;

            % Find indicies of nodes where the id matches the nodeIds
            idx = ismemberForStringArrays(obj.FlatNodeIdList, nodeIds);

            % Return corresponding nodes
            nodes = obj.FlatTreeNodeList(idx);

        end
    end

    methods (Access = {?matlab.ui.container.internal.model.TreeNodeStrategy, ...
            ?matlab.ui.container.internal.model.TreeComponent})
        function nodesAreMembers = nodesAreTreeMember(obj, treeNodes)
            % NODESARETREEMEMBER - Returns true if the treeNode entered are
            % all members of the tree, otherwise it returns false

            % Validation that the nodes are within the hierarchy
            allTreeNodes = findall(allchild(obj));

            if ~isempty(allTreeNodes)
                % Search for empty uninitialized NodeId values
                nodeIds = [treeNodes.NodeId];

                % Use NodeId to validate selectedNodes because it is faster
                % Operating on Ids is faster than operating on MCOS objects
                allIds = [allTreeNodes.NodeId];

                % Note: ismember was fastest validation technique compared with
                % using setxor and setdiff.
                nodesAreMembers = all(ismember(nodeIds, allIds));
            else

                % If the tree has no descendents, then the treeNode
                % provided is not a member
                nodesAreMembers = false;
            end
        end
        function isMembers = ismemberForNodes(obj, setA, setB)
            % NODEISMEMBER - Returns logical array the size of setA.  True
            % means that the value in setA exists in setB.
            import appdesservices.internal.util.ismemberForStringArrays;

            if isempty(setB) || isempty(setA)
                isMembers = false(size(setA));
            else

                % Search for empty uninitialized NodeId values
                nodeIdsA = [setA.NodeId];

                % Use NodeId to validate selectedNodes because it is faster
                % Operating on Ids is faster than operating on MCOS objects
                nodeIdsB = [setB.NodeId];

                % Note: ismember was fastest validation technique compared with
                % using setxor and setdiff.
                isMembers = ismemberForStringArrays(nodeIdsA, nodeIdsB);
            end
        end
    end
    % ---------------------------------------------------------------------
    % Custom Display Functions
    % ---------------------------------------------------------------------
    methods(Access = protected)

        function doUpdate(obj)
            % DOUPDATE - This function overrides
            % default no-op functionality provided by UIComponent.  For
            % MATLAB-implemented components, properties changed in the
            % Model must explicitly be flushed to the controller.

            doUpdate@matlab.ui.container.internal.model.ContainerModel(obj);
            if ~isempty(obj.Controller)
                obj.Controller.flushQueuedActionToView();
            end
        end

        function names = getPropertyGroupNames(~)
            % GETPROPERTYGROUPNAMES - This function returns common
            % properties for this class that will be displayed in the
            % curated list properties for all components implementing this
            % class.

            names = {'SelectedNodes',...
                'Multiselect',...
                'SelectionChangedFcn'};

        end

        function str = getComponentDescriptiveLabel(~)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.


            % There's no strong property in Tree representing the visual
            % for the component.
            str = '';
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

    methods (Access = {?matlab.ui.container.internal.model.ContainerModel, ...
            ?matlab.ui.container.internal.model.mixin.ExpandableComponent})
        function handleNodeEvent(obj, eventData)

            obj.TreeNodeManager.handleNodeEvent(eventData);

            % Most events can affect the order of the flat list of
            % treenodes (add, remove, move). The order is expected to be
            % generally consistent with the view.
            import appdesservices.internal.util.ismemberForStringArrays;
            eventsThatDoNotAffectFlatNodeList = ["nodeEdit", "expand", "collapse", "scroll"];
            if ~ismemberForStringArrays(string(eventData.Name), eventsThatDoNotAffectFlatNodeList)
                obj.FlatNodeListIsDirty = true;
            end
        end
    end

    methods (Access = {?matlab.ui.container.internal.model.TreeNodeManager})

        function triggerViewUpdate(obj)
            % Mark QueuedActionToView dirty so that controller makes request
            obj.markPropertiesDirty({'QueuedActionToView'});
        end
    end

    methods(Access = {?matlab.ui.container.TreeNode, ...
            ?matlab.ui.container.internal.model.TreeComponent})
        function handleDescendentRemoved(obj, treeNode)

            allRemovedTreeNodes = [];

            % Remove node from SelectedNodes
            if ~isempty(obj.SelectedNodes)

                if isempty(allRemovedTreeNodes)
                    allRemovedTreeNodes = findall(treeNode);
                end

                % Find SelectedNodes array that are being removed
                isSelectedAndRemoved = obj.ismemberForNodes(obj.SelectedNodes, allRemovedTreeNodes);

                % Check if treeNode was selected as optimization
                if any(isSelectedAndRemoved)
                    % Remove deleted node from selected Nodes array
                    nodeArray = obj.SelectedNodes(~isSelectedAndRemoved);

                    if isempty(nodeArray)
                        % Empty representation for SelectedNodes
                        obj.SelectedNodes = [];
                    else
                        obj.SelectedNodes = nodeArray;
                    end

                    % Public setter for SelectedNodes will mark it dirty
                end
            end

            % Assemble Node Event
            eventData = struct('Name', 'nodeRemove');
            eventData.RequiresMetadata = false;
            eventData.NodeIds = treeNode.NodeId;
            eventData.Data =  treeNode;
            handleNodeEvent(obj, eventData);

        end

        function handleDescendentMoved(obj, treeNode, parentNode)
            % HANDLEDESCENDENTMOVED - Special handle any tree state that
            % would react when a node is added to tree or moved within tree

            % Assemble Node Event
            eventData = struct('Name', 'nodeMove');
            eventData.RequiresMetadata = false;
            eventData.NodeIds = treeNode.NodeId;
            eventData.Data = struct(...
                'parent', parentNode.NodeId,...
                'id', treeNode.NodeId);
            handleNodeEvent(obj, eventData);
        end

        function handleDescendentAdded(obj, treeNode, parentNode)
            % HANDLEDESCENDENTADDED- Handle any tree state that
            % would react when a node is added to tree

            % Assemble Node Event
            eventData = struct('Name', 'nodeAdd');
            eventData.RequiresMetadata = true;
            eventData.NodeIds = treeNode.NodeId;
            eventData.Data = treeNode;

            handleNodeEvent(obj, eventData);

        end

        function tree = getTree(obj)

            % TreeNodes use getTree generically in their code.
            tree = obj;
        end

        function treeData = getDataToRestoreAfterMove(obj)
            % GETDATATORESTOREAFTERMOVE - This data will be set on the tree
            % after nodes are moved.  This is required because moving the
            % tree node may be treated as a delete then add which will
            % corrupt tree settings that detect node deletion like
            % selection and checked nodes.
            treeData = struct();

            if ~isempty(obj.SelectedNodes)
                treeData.SelectedNodes = obj.SelectedNodes;
            end
        end
    end
    methods (Hidden, Static) 
        function modifyOutgoingSerializationContent(sObj, obj) 

           % sObj is the serialization content for obj 
           modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj, obj);
           modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.BackgroundColorableComponent(sObj, obj);
        end
        function modifyIncomingSerializationContent(sObj) 

           % sObj is the serialization content that was saved for obj 
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj);
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.BackgroundColorableComponent(sObj);
        end 

    end
end
