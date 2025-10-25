classdef (Hidden) TreeController < ...
        matlab.ui.control.internal.controller.ComponentController & ...
        matlab.ui.container.internal.controller.mixin.ExpandableComponentController  & ...
        matlab.ui.control.internal.controller.mixin.StyleableComponentController & ...
        matlab.ui.control.internal.controller.mixin.ClickableComponentController  &...
        matlab.ui.control.internal.controller.mixin.DoubleClickableComponentController
    %

    % Copyright 2016-2023 The MathWorks, Inc.
    methods
        function populateView(obj, proxyView)
            populateView@matlab.ui.control.internal.controller.ComponentController(obj, proxyView);

            obj.flushQueuedActionToView();
        end
    end
    methods(Hidden, Access = 'public')

        function flushQueuedActionToView(obj)

            if ~isempty(obj.ViewModel)

                queuedActions = obj.Model.TreeNodeManager.pullRemainingEvents();

                if ~isempty(queuedActions)

                    func = @() obj.ClientEventSender.sendEventToClient(...
                        'editTreeContent',...
                        { ...
                        'TreeEvents', jsonencode(queuedActions), ...
                        } ...
                        );
                    matlab.ui.internal.dialog.DialogHelper.dispatchWhenPeerNodeViewIsReady(obj.Model, obj.ViewModel, func);
                end
            end
        end
    end

    methods(Access = 'protected')

        function propertyNames = getAdditionalPropertyNamesForView(obj)
            % Get additional properties to be sent to the view

            propertyNames = getAdditionalPropertyNamesForView@matlab.ui.control.internal.controller.ComponentController(obj);

            % Non - public properties that need to be sent to the view
            propertyNames = [propertyNames; {...
                'NodeId';...
                'StyleConfigurationStorage' ...
                }];
        end


        function viewPvPairs = getPropertiesForView(obj, propertyNames)
            % GETPROPERTIESFORVIEW(OBJ, PROPERTYNAME) returns view-specific
            % properties, given the PROPERTYNAMES
            %
            % Inputs:
            %
            %   propertyNames - list of properties that changed in the
            %                   component model.
            %
            % Outputs:
            %
            %   viewPvPairs   - list of {name, value, name, value} pairs
            %                   that should be given to the view.
            import appdesservices.internal.util.ismemberForStringArrays;
            viewPvPairs = {};

            % Properties from Super
            viewPvPairs = [viewPvPairs, ...
                getPropertiesForView@matlab.ui.control.internal.controller.ComponentController(obj, propertyNames), ...
                ];
            checkFor = ["SelectedNodes", "StyleConfigurationStorage"];
            isPresent = ismemberForStringArrays(checkFor, propertyNames);

            if isPresent(1)
                newValue = obj.formatNodes(obj.Model.SelectedNodes);
                viewPvPairs = [viewPvPairs, ...
                    {'SelectedNodes', newValue}, ...
                    ];
            end

            if isPresent(2)
                newValue = obj.formatStyleConfigurationStorage(obj.Model.StyleConfigurationStorage);
                viewPvPairs = [viewPvPairs, ...
                    {'StyleConfigurationStorage', newValue}, ...
                    ];
            end
        end



        function handleEvent(obj, src, event)
            % Handle Events coming from the client
            %
            % Note, other icon components (button)handles design time
            % events for Icon like 'PropertyEditorEdited', but
            % that is not yet implemented for the TreeNode so that does
            % not appear here for now.

            handleEvent@matlab.ui.control.internal.controller.ComponentController(obj, src, event);
            handleEvent@matlab.ui.control.internal.controller.mixin.ClickableComponentController(obj, src, event);
            handleEvent@matlab.ui.control.internal.controller.mixin.DoubleClickableComponentController(obj, src, event);

            if(any(strcmp(event.Data.Name, {'SelectionChanged'})))
                % Forwards the event to be handled by the Tree

                % Store the previous value
                previousValue = obj.Model.SelectedNodes;

                selectedNodes = event.Data.SelectedNodes;

                if isempty(selectedNodes)
                    newValue = [];
                else
                    nodeIDs = string(event.Data.SelectedNodes);
                    newValue = obj.Model.getNodesById(nodeIDs);
                end

                % Create event data
                eventData = matlab.ui.eventdata.SelectedNodesChangedData(newValue, previousValue);

                % Update the model and emit an event which in turn will
                % trigger the user callback
                obj.handleUserInteraction('SelectionChanged', event.Data, {'SelectionChanged', eventData, 'PrivateSelectedNodes', newValue});

            elseif(any(strcmp(event.Data.Name, {'NodeTextChanged', 'NodeExpanded', 'NodeCollapsed'})))
                % Forwards the event to be handled by the Tree

                % Forward the information up the hierarchy so it can be
                % handled by the tree.
                nodeIDs = string(event.Data.Node);
                node = obj.Model.getNodesById(nodeIDs);
                obj.handleDescendantEvent(node, event);

            elseif(strcmp(event.Data.Name,'LinkClicked'))
                if (isfield(event.Data,'url'))
                    obj.handleLinkClicked(event.Data.url);
                end
            end
        end
    end

    methods(Access = protected)
        function infoObject = getComponentInteractionInformation(obj, event, info)
            % GETCOMPONENTINTERACTIONINFORMATION - Returns component
            % specific information for clicked, contextmenuopening and
            % similar events. 
            info.Node = matlab.ui.container.TreeNode.empty();
            info.Level = [];

            %The tree also returns the treenode that was selected
            %and the level
            clickedNodeID = event.Data.node;
            if ~isempty(clickedNodeID)
                info.Node = obj.Model.getNodesById(string(clickedNodeID));
                info.Level = event.Data.level;
            end

            infoObject = matlab.ui.eventdata.TreeInteraction(info);
        end
    end

    methods(Access = {?matlab.ui.container.internal.controller.TreeNodeController})
        function handleDescendantEvent(obj, node, event)

            % Assemble eventdata
            % Fire Tree Callback
            eventName = event.Data.Name;

            switch(eventName)
                case('NodeTextChanged')

                    % Store the previous value
                    previousValue = node.Text;

                    newValue = event.Data.Text;

                    % Create event data
                    eventData = matlab.ui.eventdata.NodeTextChangedData(node, newValue, previousValue);

                    % Update the model and emit an event which in turn will
                    % trigger the user callback
                    if (~isequal(previousValue, newValue))
                        % Model updates would typically be done in the
                        % handleUserInteraction, but the update is on the
                        % node and the callback is on the tree.
                        node.Text = newValue;
                        obj.handleUserInteraction(eventName, event.Data, {eventName, eventData});
                    end

                case('NodeExpanded')

                    % Create event data
                    eventData = matlab.ui.eventdata.NodeExpandedData(node);

                    % Update the model and emit an event which in turn will
                    % trigger the user callback
                    obj.handleUserInteraction(eventName, event.Data, {eventName, eventData});

                case('NodeCollapsed')

                    % Create event data
                    eventData = matlab.ui.eventdata.NodeCollapsedData(node);

                    % Update the model and emit an event which in turn will
                    % trigger the user callback
                    obj.handleUserInteraction(eventName, event.Data, {eventName, eventData});
            end
        end
    end

    methods(Access = public)
        function excludedPropertyNames = getExcludedComponentSpecificPropertyNamesForView(~)
            % Hook for subclasses to provide a list of property names that
            % needs to be excluded from the properties to sent to the view at Run time

            excludedPropertyNames = {'StyleConfigurations'};

        end
    end

    methods
        function delete(obj)
            % DELETE - Reset the tree node manager to prepare for any new
            % controller created for tree.
            obj.Model.TreeNodeManager.reset();
        end
    end

    methods(Hidden = true)
        function component = getComponentToApplyButtonEvent(obj, event)
            % GETCOMPONENTTOAPPLYBUTTONEVENT - Calculate what the
            % current object should be given the event information.  The
            % current object will be either the tree or a treenode within
            % the tree
            component = obj.Model;
            if isfield(event.Data, 'data')
                % ContextMenuOpeningFcn
                eventStructure = event.Data.data;
            else
                % All others.
                eventStructure = event.Data;
            end
            
            node = [];
            if isfield(eventStructure, 'node')
                node = eventStructure.node; 
            end
            if ~isempty(node)
                nodeObject = obj.Model.getNodesById(string(node));
                % Node may be deleted in the course of processing
                % multiple events. Verify node is valid.
                if ~isempty(nodeObject) && isvalid(nodeObject)

                    component = nodeObject;
                end
            end
        end

        function component = getComponentToApplyContextMenuEvent(obj, event)
            % GETCOMPONENTTOAPPLYBUTTONEVENT - Calculate what the
            % current object should be given the event information.  The
            % current object will be either the tree or a treenode within
            % the tree
            component = getComponentToApplyButtonEvent(obj, event);
            if isempty(component.ContextMenu)
                component = obj.Model;
            end
        end
    end

    methods(Static=true, Hidden=true)
        function newValue = formatNodes(selectedNodes)
            newValue = [];
            % Convert Nodes to node ids
            % Use for loop because get does not return consistent
            % results for one node vs multiple nodes
            for index = 1:numel(selectedNodes)
                newValue = [newValue, get(selectedNodes(index), 'NodeId')];
            end
        end

        function formattedSerializableStyle = formatStyleConfigurationStorage(value)
            import matlab.ui.control.internal.controller.mixin.StyleableComponentController; 
            formattedSerializableStyle = StyleableComponentController.getSerializableStyleConfigurationStorage(value);

            % Perform Tree specific manipulation
            for index = 1:numel(formattedSerializableStyle.TargetIndex)
                if isa(formattedSerializableStyle.TargetIndex{index}, "matlab.ui.container.TreeNode")
                    % filter invalid nodes
                    nodeList = formattedSerializableStyle.TargetIndex{index};
                    nodeList = nodeList(isvalid(nodeList));

                    formattedSerializableStyle.TargetIndex{index} = get(nodeList, 'NodeId');
                end
            end
        end
    end
end

