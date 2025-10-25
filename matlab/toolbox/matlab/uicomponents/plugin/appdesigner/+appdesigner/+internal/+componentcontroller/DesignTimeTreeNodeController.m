classdef DesignTimeTreeNodeController < ...
        matlab.ui.container.internal.controller.TreeNodeController  & ...
        appdesigner.internal.componentcontroller.DesignTimeVisualComponentsController  & ...
        appdesservices.internal.interfaces.controller.DesignTimeParentingController  & ...
        appdesigner.internal.componentcontroller.DesignTimeIconHandler
    
    % DesignTimeTreeNodeController is a Visual Component Container 
    % Unlike GBT Containers that extend DesignTimeGbtParentingController
    % it extends DesignTimeParentingController   
    
    % Copyright 2017-2023 The MathWorks, Inc.
    
    methods
        function obj = DesignTimeTreeNodeController(component, parentController, proxyView, adapter)
            obj = obj@matlab.ui.container.internal.controller.TreeNodeController(component, parentController, proxyView);
            obj = obj@appdesigner.internal.componentcontroller.DesignTimeVisualComponentsController(component, proxyView, adapter);
            factory = appdesigner.internal.componentmodel.DesignTimeComponentFactory;
            obj = obj@appdesservices.internal.interfaces.controller.DesignTimeParentingController( factory );
            
            % g1625958 - Workaround for the issue where proxyview and 
            % controllers are deleted when tree-nodes are inserted at
            % specific indexes/ re-ordered
            component.setControllerHandle(obj);

            obj.fireServerReadyEvent(obj.Model);
        end
        
        function populateView(obj, proxyView)
            populateView@matlab.ui.container.internal.controller.TreeNodeController(obj, proxyView);

            % Destroy the visual comopnent's runtime listeners.  We will
            % not be needing these during design time.
            delete(obj.Listeners);
            obj.Listeners = [];
            
            % Create controllers and design time listeners
            populateView@appdesservices.internal.interfaces.controller.DesignTimeParentingController(obj, proxyView);
            populateView@appdesigner.internal.componentcontroller.DesignTimeVisualComponentsController(obj, proxyView);
        end
        
        function arrangeNewlyAddedChild(obj, child, componentIndex)
            % The recommended workflow for reordering the children in Tree is to use the move command
            % which will preserve the state of the nodes even after a reorder.
            child.move(child.Parent.Children(componentIndex), 'before')
        end

        function adjustedProperties = adjustParsedCodegenPropertiesForAppLoad(obj, parsedProperties)
            adjustedProperties = adjustParsedCodegenPropertiesForAppLoad@appdesigner.internal.controller.DesignTimeController(obj, parsedProperties);
            % Ensures NodeId is always sent during app load
            adjustedProperties = [adjustedProperties, {'NodeId'}];
        end
    end
    
    methods (Access = 'protected')
        
        function deleteChild(obj, model, child)            
            delete( child );
        end
        
        function model = getModel(obj)            
            model = obj.Model;
        end
        
        function handleDesignTimePropertiesChanged(obj, src, changedPropertiesStruct)
            % HANDLEDESIGNTIMEPROPERTIESCHANGED - Delegates the logic of
            % handling the event to the runtime controllers via the
            % handlePropertiesChanged method
            handlePropertiesChanged(obj, changedPropertiesStruct);
        end

        function handleDesignTimeEvent(obj, src, event)
            % HANDLEDESIGNTIMEEVENT - Delegates the logic of handling the
            % event to the runtime controllers via the handleEvent method
            if strcmp(event.Data.Name, 'PropertyEditorEdited') && strcmp(event.Data.PropertyName, 'Icon')
                
                propertyName = event.Data.PropertyName;
                
                % Validate the inputted Image file
                [fileNameWithExtension, validationStatus, imageRelativePath] = obj.validateImageFile(propertyName, event);
                
                if validationStatus
                    obj.ViewModel.setProperties({'ImageRelativePath', imageRelativePath});
                    % this is an event callback and we're adjusting the 
                    % event data. Since it's called from handleEvent, it's
                    % a client event.
                    obj.handleComponentDynamicDesignTimeProperties(struct('ImageRelativePath', imageRelativePath), true);
                end

                setModelProperty(obj, ...
                    propertyName, ...
                    fileNameWithExtension, ...
                    event ...
                    );
            else
                handleEvent(obj, src, event);
            end
        end
    end
    
    methods(Access = {...
            ?appdesigner.internal.componentcontroller.DesignTimeTreeController, ...
            ?appdesigner.internal.componentcontroller.DesignTimeCheckBoxTreeController, ...
            ?appdesigner.internal.componentcontroller.DesignTimeTreeNodeController})

        function fireServerReadyEvent(obj, treeNode)
            % UPDATETREEPROPERTIES - In some cases, the tree proeprties need to be updated
            % when a new tree node is added. For example, if a checked tree node is added
            % to CheckBoxTree, the CheckedNodes property needs to be updated to contain
            % the newly added tree node.

            % Propogate changes to the parent
            if (~isempty(obj.ParentController))
                obj.ParentController.fireServerReadyEvent(treeNode);
            end
        end
    end
   
end
