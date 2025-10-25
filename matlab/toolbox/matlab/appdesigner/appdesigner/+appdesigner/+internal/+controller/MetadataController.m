classdef MetadataController < appdesservices.internal.interfaces.controller.AbstractController ...
        & appdesservices.internal.interfaces.controller.ServerSidePropertyHandlingController
    %METADATACONTROLLER Controller for App Metadata

    % Copyright 2020 The MathWorks, Inc

    properties (Access = private)
        PropertiesSetListener
    end

    methods
        function obj = MetadataController(model, proxyView)
            obj = obj@appdesservices.internal.interfaces.controller.AbstractController(model, [], proxyView);
            % Receive the view's properties and set them on the model.
            obj.populateView(proxyView);

            if ~isempty(proxyView) && ~isempty(proxyView.PeerNode)
                % Set up propertiesSet event listener
                obj.PropertiesSetListener = addlistener(proxyView.PeerNode, 'propertiesSet', ...
                    obj.wrapLegacyProxyViewPropertiesChangedCallback(@obj.handlePropertiesChanged));
            end

            % After setting the view's properties on the model, send the
            % corrected values back up to the view.
            obj.syncProperties();
        end
        
        function propertySetSuccess(obj, propertyName, commandId)
            % Set the property on the peer node to be the correct value
            % from the model.  The property set succeeded, so the view
            % should commit the values that are on the peer node.  This
            % ensures that the view and model agree on the metadata values.
            obj.ViewModel.setProperties({propertyName, obj.Model.(propertyName)});
            propertySetSuccess@appdesservices.internal.interfaces.controller.ServerSidePropertyHandlingController(obj, propertyName, commandId);
        end
    end

    methods(Access = protected)
        function pvPairs = getPropertiesForView(obj, propertyNames)
            % Do not modify the properties, return exactly what's on the
            % model as PV pairs.
            pvPairs = cell(1, 2 * length(propertyNames));

            for idx = 1:length(propertyNames)
                propertyName = propertyNames{idx};
                propertyValue = obj.Model.(propertyName);
                
                pvPairs{idx * 2 - 1} = propertyName;
                pvPairs{idx * 2} = propertyValue;
            end
        end

        function handleEvent(obj, src, event)
            if strcmp(event.Data.Name, 'PropertyEditorEdited')
                propertyName = event.Data.PropertyName;
                propertyValue = event.Data.PropertyValue;
                
                % Validate the property by trying to set it on the model.
                % If successful, the value will be committed and
                % confirmation will be sent to the view.  Otherwise, send a
                % rejection.  Note: if multiple properties are set at
                % once, rejection of one property set means rejection of
                % all property sets.
                setServerSideProperty(obj, ...
                    obj.Model, ...
                    propertyName, ...
                    propertyValue, ...
                    event.Data.CommandId...
                    );
                return;
            end
        end
    end
    
    methods (Access = private)
        function syncProperties(obj)
            % Get all properties from the model and set them on the
            % ProxyView.
            propertyNames = properties(obj.Model);
            pvPairs = obj.getPropertiesForView(propertyNames);
            obj.ViewModel.setProperties(pvPairs);
        end
    end
end
