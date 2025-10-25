 classdef (Hidden) TreeNodeManager < handle
    %TREENODEMANAGER This object performs manages the communication between
    %the tree and the view by keeping track of the node related
    %events/operations etc.
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties (Constant, Access = 'private')
        MethodEventNames = ["scroll", "expand", "collapse"];
        EventsToMergeOnConstruction = ["nodeAdd", "nodeEdit", "nodeRemove", "nodeMove"];
        EventsToNotFilter = ["nodeRemove"];
    end
    properties (Access = 'private')
        Tree

        % Events queued to send to view at drawnow
        QueuedActionToView
        % Events to filter if node is deleted
        FilterableQueuedActionIndices
        
        % Keep track of dirty state so that an update to the view can be
        % requested once and only once per dirty status
        IsDirty = false;
        
        % Up until first draw now (first request for pullRemainingEvents), the
        % manager will be in merge mode to minimize processing during
        % construction
        MergeEventsMethod = "construction";
        ConstructionMergeEventMethod = "construction";
    end
    
    
    methods
        
        function obj = TreeNodeManager(tree)
            obj.Tree = tree;
            
            obj.reset();
        end
    end
    
    methods
        function reset(obj)
            % RESETNODEMANAGER - Restore node manager to construction
            % defaults.  
            % There are two primary use cases to reset the treenode manager
            %    - Initial tree construction
            %    - Restore of view after controller deletion (move,
            %    reparent, reorder of siblings)
            
            obj.QueuedActionToView = [];
            obj.FilterableQueuedActionIndices = [];
            obj.IsDirty = false;
            obj.MergeEventsMethod = "construction";
            obj.ConstructionMergeEventMethod = "construction";
            
        end
        
        function handleNodeEvent(obj, eventData)
            if obj.MergeEventsMethod == obj.ConstructionMergeEventMethod
                % Post pone processing events until one of the events does
                % not match the meragable events (scroll, expand, collapse)
                if ~any(strcmp(eventData.Name, obj.EventsToMergeOnConstruction))
                    % Create NodeAdd construction event and place before
                    % first expand/collapse/scroll event
                    mergedEventData = obj.buildEventForEntireTreeConstruction();
                    obj.addEventToQueue(mergedEventData);
                    obj.addEventToQueue(eventData);
                    
                    % Events will no longer be merged
                    obj.MergeEventsMethod = "none";
                end
            else
                
                switch(eventData.Name)
                    case 'nodeAdd'
                        % If node has children, add them to the data
                        eventData.Data = findall(eventData.Data);
                        
                    case 'nodeRemove'
                        
                        
                        removedNode = eventData.Data;
 
                        
                        % If the parent of the node is being deleted, let
                        % parent handle cleanup.
                        parent = removedNode.Parent;
                        if isempty(parent) || parent.BeingDeleted
                            eventData = [];                            
                        else
                            % Clear actions associated with node: expand/collapse/scroll
                            if obj.IsDirty
                                % Filter existing collapse/expand scroll
                                % commands if they are operating on removed node
                                allNodes = findall(eventData.Data);            
                                for index = 1:numel(allNodes) 
                                    id = allNodes(index).NodeId;
                                    obj.filterQueuedActions(id);
                                end
                                % Filter parent if removed node is last child
                                % Parent isn't expandable if it has no children
                                if all(isequal(removedNode, removedNode.Parent.Children)) % only child is the deleted node
                                    obj.filterQueuedActions(removedNode.Parent.NodeId);
                                end  
                            end
                            % Replace Data with node proxy since actual
                            % node will be deleted by the time the
                            % controller processes the information
                            eventData.Data = struct('id', removedNode.NodeId);
                        end
                    otherwise
                end
                obj.addEventToQueue(eventData);
            end
            
            if obj.IsDirty == false
                triggerViewUpdate(obj.Tree);
                obj.IsDirty = true;
            end   
        end
        
    end
    
    methods(Access = {?matlab.ui.container.internal.controller.TreeController})
        function queuedActions = pullRemainingEvents(obj)
            % GETEVENTS - This represents a request from the
            % controller after a drawnow.  The access permissions on the
            % method reenforce that the role of this method is to faciliate
            % post drawnow event collection that will go to the view.
            if obj.MergeEventsMethod == obj.ConstructionMergeEventMethod
                % Create NodeAdd construction event
                mergedEventData = obj.buildEventForEntireTreeConstruction();
                obj.addEventToQueue(mergedEventData);
            end
            
            
            queuedActions = obj.QueuedActionToView;
            
            if ~isempty(queuedActions)
                % Replace node with node metadata that is view ready
                for index = numel(queuedActions):-1:1
                    if queuedActions(index).RequiresMetadata == true
                        
                        % Data field is expected to be a treenode object
                        metaData = getNodeMetadata(queuedActions(index).Data);
                        
                        if isempty(metaData)
                            % Meta data will be empty if node is deleted or
                            % invalid
                            % Remove action in this case
                            queuedActions(index) = [];
                        else                            
                            queuedActions(index).Data = getNodeMetadata(queuedActions(index).Data);
                        end
                    end
                end
                if ~isempty(queuedActions)
                    if isfield(queuedActions, 'RequiresMetadata')
                        queuedActions = rmfield(queuedActions, 'RequiresMetadata');
                    end
                    if isfield(queuedActions, 'NodeIds')
                        queuedActions = rmfield(queuedActions, 'NodeIds');
                    end
                end
            end
            
                
            % TreeNodeManager reset internal states
            obj.QueuedActionToView = [];
            obj.FilterableQueuedActionIndices = [];
            obj.IsDirty = false;
            
            % Events will no longer be merged after first drawnow
            obj.MergeEventsMethod = "none";
        end
    end
        
    methods(Access = private)
        function addEventToQueue(obj, eventData)
            % Append new eventData to list
            if ~isempty(eventData)
                if isempty(obj.QueuedActionToView)
                    obj.QueuedActionToView = eventData;
                else
                    obj.QueuedActionToView(end+1) = eventData;
                end

                if ~strcmp(eventData.Name, obj.EventsToNotFilter)    
                    obj.FilterableQueuedActionIndices(end+1) = numel(obj.QueuedActionToView);
                end
            end
            
        end
        
        function removeEventFromQueue(obj, index)
            % Remove event from queue and maintain
            % FilterableQueuedActionIndices
            obj.QueuedActionToView(index) = [];
            obj.FilterableQueuedActionIndices(obj.FilterableQueuedActionIndices == index) = [];
            % Shift the indices greater than index down 1
            indicesToShift = obj.FilterableQueuedActionIndices > index;
            obj.FilterableQueuedActionIndices(indicesToShift) = obj.FilterableQueuedActionIndices(indicesToShift) - 1;
            
        end

        function eventData = buildEventForEntireTreeConstruction(obj)
            
            if ~isempty(obj.Tree.FlatTreeNodeList)
                eventData = struct('Name', 'nodeAdd');
                eventData.RequiresMetadata = true;
                eventData.NodeIds = obj.Tree.FlatNodeIdList;                        
                eventData.Data = obj.Tree.FlatTreeNodeList;
            else
                eventData = [];
            end
        end
        
        function filterQueuedActions(obj, id)
            
            assert(isscalar(id), 'Argument id is expected to be scalar')
            % Search list from end because we might delete entry
            for index = reshape(sort(obj.FilterableQueuedActionIndices, 'descend'), 1, [])
                if any(strcmp(obj.QueuedActionToView(index).Name, obj.MethodEventNames))
                    % Remove id from Target
                    obj.QueuedActionToView(index).NodeIds = ...
                        obj.QueuedActionToView(index).NodeIds(...
                        obj.QueuedActionToView(index).NodeIds~=id);
                    if isempty(obj.QueuedActionToView(index).NodeIds)
                        % Remove event from array if it has no target.
                        obj.removeEventFromQueue(index);
                    end
                end
            end
        end          
    end   
end

