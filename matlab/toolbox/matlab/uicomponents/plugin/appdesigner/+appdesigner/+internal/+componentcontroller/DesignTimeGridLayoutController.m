classdef DesignTimeGridLayoutController < ...
        matlab.ui.container.internal.controller.GridLayoutController & ...
        appdesigner.internal.componentcontroller.DesignTimeVisualComponentsController & ...
        appdesservices.internal.interfaces.controller.DesignTimeParentingController
    
    % DesignTimeGridLayoutController is a Visual Component-style controller
    % and hence extends DesignTimeVisualComponentsController.
    %
    % Since there is no explicit run-time GridController, it extends
    % directly from matlab.ui.control.internal.controller.ComponentController
    
    % Copyright 2018 - 2023 The MathWorks, Inc.
    
    methods
        function obj = DesignTimeGridLayoutController(component, parentController, proxyView, adapter)
            obj@matlab.ui.container.internal.controller.GridLayoutController(component, parentController, proxyView);
            obj = obj@appdesigner.internal.componentcontroller.DesignTimeVisualComponentsController(component, proxyView, adapter);
            factory = appdesigner.internal.componentmodel.DesignTimeComponentFactory;
            obj = obj@appdesservices.internal.interfaces.controller.DesignTimeParentingController( factory );
            
            obj.NumericProperties = [obj.NumericProperties, {'ColumnSpacing', 'RowSpacing', 'Padding'}];
            
            % g1625958 - Workaround for the issue where proxyview and
            % controllers are deleted when tree-nodes are inserted at
            % specific indexes/ re-ordered
            component.setControllerHandle(obj);
            
            % When the app is created in R2020a or earlier releases, the saved 
            % Position of the Grid is incorrect.  We need to trigger a Position 
            % update here so that Axes in a Grid appears correctly.

            % The ServerReady event is sent to the client, which is picked up 
            % in the design-time GridController.js; this file then initiates a
            % sequence that updates Position of a grid.
            obj.fireServerReadyEvent(proxyView);
        end
        
        function populateView(obj, proxyView)
            populateView@matlab.ui.container.internal.controller.GridLayoutController(obj, proxyView);
            
            % Destroy the visual component's runtime listeners.  We will
            % not be needing these during design time.
            delete(obj.Listeners);
            obj.Listeners = [];
            
            % Create controllers and design time listeners
            populateView@appdesigner.internal.componentcontroller.DesignTimeVisualComponentsController(obj, proxyView);
            populateView@appdesservices.internal.interfaces.controller.DesignTimeParentingController(obj, proxyView);
        end
    end
    
    methods (Access = 'protected')
        function deleteChild(obj, model, child)
            delete( child );
        end
        
        function model = getModel(obj)
            model = obj.Model;
        end

        function fireServerReadyEvent(obj, proxyView)
            % Dispatch event directly via given peer node because ProxyView.PeerNode
            % will not be set yet so we can't use obj.ClientEventSender
            if ~isempty(proxyView) && ~isempty(proxyView.PeerNode)
                eventData.Name = 'ServerReady';
                viewmodel.internal.factory.ManagerFactoryProducer.dispatchEvent( ...
                    proxyView.PeerNode, 'peerEvent', eventData, proxyView.PeerNode.Id);
            end
        end
        
        function unhandledProperties = handlePropertiesChanged(obj, changedPropertiesStruct)
            changedProperties = fieldnames(changedPropertiesStruct);
            if (ismember('RowHeight', changedProperties))
                value = changedPropertiesStruct.RowHeight;
                if (~iscell(value))
                    value = num2cell(value);
                end
                obj.Model.RowHeight = value;
                changedPropertiesStruct = rmfield(changedPropertiesStruct, 'RowHeight');
            end
            if(ismember('ColumnWidth', changedProperties))
                
                value = changedPropertiesStruct.ColumnWidth;
                if (~iscell(value))
                    value = num2cell(value);
                end
                obj.Model.ColumnWidth = value;
                changedPropertiesStruct = rmfield(changedPropertiesStruct, 'ColumnWidth');
            end
            
            if isfield(changedPropertiesStruct,'Position')
                obj.Model.Position = changedPropertiesStruct.Position;
            end
            
            handlePropertiesChanged@matlab.ui.container.internal.controller.GridLayoutController(obj, changedPropertiesStruct);
        end

        function changedPropertiesStruct = handleSizeLocationPropertyChange(obj, changedPropertiesStruct)
            % At design-time, we do not change the size/location of a
            % GridLayout on the server.

            if isfield(changedPropertiesStruct,'Size')
                changedPropertiesStruct = rmfield(changedPropertiesStruct, 'Size');
            end

            if isfield(changedPropertiesStruct,'OuterSize')
                changedPropertiesStruct = rmfield(changedPropertiesStruct, 'OuterSize');
            end            
            
            if isfield(changedPropertiesStruct,'Location')
                changedPropertiesStruct = rmfield(changedPropertiesStruct, 'Location');
            end            
            
            if isfield(changedPropertiesStruct,'OuterLocation')
                changedPropertiesStruct = rmfield(changedPropertiesStruct, 'OuterLocation');
            end
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
            
            if(strcmp(event.Data.Name, 'PropertyEditorEdited'))
                
                wasHandled = obj.handlePropertyEditorEdited(src, event);
                if(wasHandled)
                    return;
                end
            end
            
            if strcmp(event.Data.Name,'positionChangedEvent')
                obj.Model.Position = event.Data.valuesInUnits.OuterPosition.Value;
            end
            
            handleEvent(obj, src, event);
        end
    end
    
    methods(Hidden, Access = 'public')
        function isChildOrderReversed = isChildOrderReversed(obj)
            % App Designer flips order of GridLayout's children unintentially, forgetting to 
            % override default implementation of this method used to be in DesignTimeController,
            % which returns false by default.
            % Therefore, all saved apps with GridLayout have flipped children on the disk.
            % To avoid loading existing apps to be dirty, keep returning true for isChildOrderReversed()
            % for design-time only.
            % We should assess if we'd like to remove this to make it back to correct behavior, 
            % so that:
            % 1) consistent with runtime behavior of children order
            % 2) avoid unncessary children order flipping and arranging in design-time
            isChildOrderReversed = true;
        end
    end

    methods
        function wasHandled = handlePropertyEditorEdited(obj, src, event)
            
            wasHandled = false;
            
            propertyName = event.Data.PropertyName;
            propertyValue = event.Data.PropertyValue;
            
            if(strcmp(propertyName, 'ColumnWidth') || ...
                    strcmp(propertyName, 'RowHeight'))
                
                % When editing from the Inspector, value will be a
                % comma separated string or a cell array of individual
                % entries
                %
                % Ex: '1x, 200, 1x'
                %
                % To parse this, will split around ',' and convert each
                % element to a number
                
                % Split if its a char (and not alreayd a cell)
                % g1898623
                if(ischar(propertyValue))
                    splitString = split(propertyValue, ',');
                    splitString = cellfun(@(str) strtrim(str), splitString, 'UniformOutput',false);
                    propertyValue = convertClientNumbertoServerNumber(obj, splitString);
                end
                
                if(isnumeric(propertyValue))
                    % This handles the case when the values entered
                    % were all pure numbers
                    %
                    % Ex: '100, 200, 100'
                    propertyValue = num2cell(propertyValue);
                end
                
                wasHandled = true;
                
                % update the model
                setModelProperty(obj, ...
                    propertyName, ...
                    propertyValue, ...
                    event ...
                    );
                
                
            end
        end
    end
end

