classdef DesignTimeParentingController <  ...
        matlab.ui.internal.componentframework.services.optional.ControllerInterface & ...
        appdesservices.internal.interfaces.controller.AbstractControllerMixin
    
    % DesignTimeParentingController  A Mixin controller class to handle peer nodes
    % being created and deleted on the client.  It is instantiated with a
    % factory to create child objects.
    
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties(Access=protected)
        % a factory to create child objects
        Factory
        
        % Listen to 'childAdded' and 'childRemoved' of the PeerNode
        ChildAddedListener
        ChildRemovedListener
        
        % Map of peerNode ids processed by this controller.
        ProcessedPeerNodes
    end
    
    methods (Abstract, Access=protected )
        
        %  subclasses will define how to delete a child object from its
        %  parent model
        deleteChild(obj,parentModel,child);
        
        % subclasses will define how to get the model associated to this
        % controller
        model = getModel(obj);
        
    end
    
    methods
        function obj = DesignTimeParentingController(factory)
            % construct a DesignTimeParentingController with the factory that will
            % be used to create child model objects
            
            % save the factory
            obj.Factory = factory;
            if isa(obj.Model, 'appdesservices.internal.interfaces.model.AbstractModel')
                dirtyPropertyStrategy = appdesservices.internal.interfaces.model.DirtyPropertyStrategyFactory.getDirtyPropertyStrategy(obj.Model);
                obj.Model.setDirtyPropertyStrategy(dirtyPropertyStrategy);
            end
            
            obj.ProcessedPeerNodes = containers.Map;
        end
        function populateView(obj, view)
            % process the proxyView to setup listeners and process its
            % child peer nodes
            % Notes:
            %   1. the proxyView can be empty when this controller is
            %      instantiated by the framework to gather component default
            %      values
            %   2. The ProxyView's peer node is empty in TestProxyView.
            %      Need to fix that
            %   3. The ProxyView could be deleted if closing app so quickly
            if ~isempty(obj.ViewModel)
                obj.processViewModel();
            end
            
        end
        
        function delete(obj)
            % Clean up listeners
            delete(obj.ChildAddedListener);
            delete(obj.ChildRemovedListener);
        end
        
        function arrangeNewlyAddedChild(obj, child, componentIndex)
            % Adjusts the children order when a new child is added.
            % Sub-classes cnan override this method to provide their own
            % implmentation

            % There is a possibility of Hidden Handles being added to the 
            % object tree during this method call.  However, the number of 
            % arranged children MUST be equal to the number of original 
            % children.  By setting ShowHiddenHandles off, we ensure that 
            % any new hidden handles don't cause an error due to the number of 
            % arranged children. g2468867
            originalShowHiddenHandlesPropertyValue = get(groot,'ShowHiddenHandles');
            if originalShowHiddenHandlesPropertyValue
                cleanup = onCleanup(@() set(groot, 'ShowHiddenHandles', originalShowHiddenHandlesPropertyValue));
                set(groot, 'ShowHiddenHandles', 'off')
            end

            arrangeChildren = child.getControllerHandle().adjustChildOrder(child.Parent.getControllerHandle(), child, componentIndex);
            
            % Ensure that all axes are at the bottom of the graphics
            % hiearchy.  This procedure is important to avoid warnings
            % about child order and is critical when gridying an app that
            % contains an axes.
            for i = 1:length(arrangeChildren)
                index(i) = isa(arrangeChildren(i),'matlab.ui.control.UIAxes');
            end
            chartingChildren = arrangeChildren(index);
            nonChartingChildren = arrangeChildren(~index);
            arrangeChildren = [nonChartingChildren;chartingChildren];
            
            obj.Model.Children = arrangeChildren;
        end
    end
    
    methods(Access = {...
            ?appdesservices.internal.interfaces.controller.AbstractController,...
            ?appdesservices.internal.interfaces.controller.AbstractControllerMixin,...
            ?matlab.ui.internal.DesignTimeGBTComponentController,...
            })
        
        function handlePeerNodeReparentedTo(obj, addedChildPeerNode)
            % Handles a peer node being reparented from the view
            % The addedChildPeerNode has been added to this peer node, so
            % update the list of peer node processed by this controller.
            
            % add the peerNode id as a key to the map
            obj.ProcessedPeerNodes(char(addedChildPeerNode.getId())) = true;
        end
        
        function handlePeerNodeReparentedFrom(obj, removedChildPeerNode)
            % Handles a peer node being reparented from the view
            % The removedChildPeerNode has been removed from this peer node, so
            % update the list of peer node processed by this controller.
            
            id = char(removedChildPeerNode.getId());

            % If a child is reparented before its peer node has been processed,
            % the ProcessedPeerNodes map will not have its id.  This can happen
            % during very quick operation, i.e. in tests.  When that happens
            % avoid removing the ID as it is not present in the map and will error.
            if ~isKey(obj.ProcessedPeerNodes, id)
                return;
            end

            % remove from the ProcessedPeerNode map
            remove(obj.ProcessedPeerNodes, id);
        end
        
        function children = getAllChildren(obj, model)
            % GETALLCHILDREN - Get all of the children of the model,
            % regardless of the 'HandleVisibility' value.  The returned
            % graphics array does not include AnnotationPanes because
            % AnnotationPanes are used for the Axes Toolbar, which is not
            % shown at design-time.
            % OUTPUT:
            %     children: graphics array consisting of all children of
            %     model, excluding AnnotationPanes.
            
            % call allchild() function script from uitools to get all
            % children
            children = allchild(model);
            
            % Remove the annotation panes.
            children = obj.removeAnnotationPanes(children);
        end
        
        function child = findChildByPeerNode(obj, peerNode)
            child = [];
            
            model = obj.getModel();
            childrenListMap = appdesigner.internal.application.getDescendantsMapWithCodeName(model);
            
            codeName = peerNode.getProperty('CodeName');
            if (isfield(childrenListMap, codeName))
                child = childrenListMap.(codeName);
            end
        end
    end
    
    methods(Access = {...
            ?appdesservices.internal.interfaces.controller.AbstractController, ...
            ?appdesservices.internal.interfaces.controller.AbstractControllerMixin})
        function handleChildCodeGenerated(obj, changedChild)
            % Propogate changes to the parent
            if(~isempty(obj.ParentController))
                obj.ParentController.handleChildCodeGenerated(changedChild);
            end
            
            % Subclasses should extend this method if they want to provide
            % customized behavior (ex: button group)
        end
    end
    
    methods(Access=private)
        function processViewModel(obj)
            
            % The peerNode in the proxyView was a result of a client-driven
            % workflow it may already have peerNode children.  These
            % child peer nodes may have been added before this parent
            % controller was created resulting in the controller missing
            % "childAdded" events of the peer node.
            
            % The following logic is to make sure any missed peer
            % node children are processed.  The indexing in the loop is
            % 0 based because the peer nodes are java objects.
            if isa(obj.Model, 'matlab.ui.componentcontainer.ComponentContainer')
                % UAC component's Children property alwasy returns empty, and 
                % it would use runtime logic to handle them, so skip them here.
                return;
            end

            % Listen to child added and child removed events on the peer
            % node
            obj.ChildAddedListener = addlistener(obj.ViewModel,'childAdded', @obj.handlePeerNodeAdded);
            obj.ChildRemovedListener = addlistener(obj.ViewModel,'childRemoved', @obj.handlePeerNodeRemoved);

            children = obj.ViewModel.getChildren();
            for i = 1: numel(children)
                % get the child peer node
                childPeerNode = children(i);

                % process the peer node
                % This method is part of the DesignTimeParentingController API
                obj.processClientCreatedPeerNode(childPeerNode);
            end
        end
        
        function processClientCreatedPeerNode(obj, viewModel)
            
            viewModelType = viewModel.getType();
            
            hasMATLABObjectCreated = viewModel.getProperty('IsAttachedtoComponentModel');
            if (~isempty(hasMATLABObjectCreated) && strcmp(hasMATLABObjectCreated, 'true'))
                % A peer node was created on the client and the associated MCOS
                % object has already been created.
                % Stop processing
                return;
            end
            
            % A peer node was created on the client and the associated MCOS
            % object must be created as a child of this controller's model
            
            % However, the child model may already exist so need to check
            % using the ProcessedPeerNodes map
            childexists = isKey(obj.ProcessedPeerNodes, char(viewModel.getId()));
            
            if(childexists)
                % Stop processing, the child should already
                % - be created, parented
                % - in the right order
                return;
            end
            
            try
                % if the child does not exist, create a child object
                child = obj.Factory.createModel(obj.getModel(),viewModel);
            catch me
                if ~isempty(viewModel) && isvalid(viewModel)
                    % If the user closes App Designer very quickly when
                    % UAC is still constructing on MATLAB side, viewModel 
                    % would be deleted already.
                    viewmodel.internal.factory.ManagerFactoryProducer.dispatchEvent(viewModel, 'peerEvent',...
                        struct('Name', 'ModelCreationError', 'Type', viewModelType, 'Message', me.message));
                end
                return;
            end
            
            % add the peerNode id as a key to the map to keep track
            % that the peernode was already processed
            obj.ProcessedPeerNodes(char(viewModel.getId())) = true;
            
            % Return early before adjusting figure or other containers-in-figure's child order
            if(strcmpi(class(obj.Model), 'appdesigner.internal.model.AppDesignerModel') || ...
                    strcmpi(class(obj.Model), 'appdesigner.internal.model.AppModel'))
                return
            end
            
            try
                componentIndex = appdesservices.internal.peermodel.PeerNodeProxyView.getViewModelChildIndex(viewModel, viewModel.getParent());
            catch ex
                if ( isempty(viewModel) || isempty(viewModel.getParent))
                    % if the user closed the app very quickly, the
                    % peer nodes are getting destroyed but at the same time
                    % they are still processing to be added on the server
                    % in this method.  Somewhere in the java method
                    % peerNode.getParent the peerNode was
                    % destroyed causing the exception
                    return;
                else
                    rethrow(ex);
                end
            end

            obj.arrangeNewlyAddedChild(child, componentIndex);            
        end
        
        function processClientDeletedPeerNode(obj,peerNode)
            % A child Peer node was deleted from the client and the
            % corresponding MCOS object must be deleted
            
            % When the user closes a tab on the client the peer node for
            % the tab is destroyed, this method gets called and the model is
            % deleted.
            % But there are instances where a removeChild event for a peer
            % node still makes it to the server. The problem is the parent
            % model is already deleted, so a check must be made for that.
            
            % get the model associated to this controller
            if ~isvalid(obj)
                % mf0 viewmodle could fire parent's childDestroyed event
                % first, so in such a case, do not need to handle children
                % deletion which have been deleted from parent's destroy
                return;
            end
            model = obj.getModel();
            
            if isvalid(model )
                % have the model return the child with the given id if it
                % exists
                child = obj.findChildByPeerNode(peerNode);
                
                % remove from the ProcessedPeerNode map
                peerNodeId = char(peerNode.getId());
                if obj.ProcessedPeerNodes.isKey(peerNodeId)
                    remove(obj.ProcessedPeerNodes, peerNodeId);
                end
                
                % if the child was found, remove it from the Model and delete it
                if ~isempty(child)
                    obj.deleteChild(model, child);
                end
            end
        end
        
        function handlePeerNodeAdded(obj, src, event)
            % Handles the 'ChildAdded' event on the Peer Node
            
            % only process the event if the peer node was created on the client
            % get the peerNode from the event and create a
            % PeerNodeProxyView
            
            if appdesservices.internal.peermodel.isEventFromClient(event)
                peerNode = event.getData().get('child');
                obj.processClientCreatedPeerNode(peerNode);
            end
        end
        
        function handlePeerNodeRemoved(obj, src, event)
            % Handles the 'childRemoved' event on the Peer Node
            
            % only process the child removed if it was created on the client
            if appdesservices.internal.peermodel.isEventFromClient(event)
                peerNode = event.getData().get('child');

                obj.processClientDeletedPeerNode(peerNode);
            end
        end
        
        function graphicsArrayNoAnnotationPanes = removeAnnotationPanes(obj, graphicsArray)
            % REMOVEANNOTATIONPANES - Removes the annotation panes from a
            % graphics array.
            % INPUT:
            %    obj
            %    graphicsArray - array that potentially contains many different components
            % OUTPUT:
            %    graphicsArrayNoAnnotationPanes - original graphics array with the annotation panes removed
            
            % g2092770: Using arrayfun to remove AnnotationPanes is not performant
            % g2272722: Annotation Panes cannot be deleted, they must only
            % be removed from the list.
            
            % Find all objects in graphicsArray that are not annotation panes
            graphicsArrayNoAnnotationPanes = findall(graphicsArray, 'flat', '-not','Type', 'annotationpane');
        end
        
    end
    
    methods (Static)
        function child = findChild(childList,idToLookFor)
            child = [];
            %  loop over the children looking for one with the idToLookFor
            for idx = 1:length(childList)
                
                % Get the id of this object from the controller
                id = childList(idx).getControllerHandle().getId();
                
                % See if this id matches the one we are looking for
                if(strcmp(id, idToLookFor))
                    child = childList(idx);
                    break;
                end
            end
        end
    end
    
end
