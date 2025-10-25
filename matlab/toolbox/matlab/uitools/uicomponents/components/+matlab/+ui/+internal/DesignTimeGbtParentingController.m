classdef DesignTimeGbtParentingController < ...
        matlab.ui.internal.DesignTimeGBTComponentController & ...
        appdesservices.internal.interfaces.controller.DesignTimeParentingController & ...
        matlab.ui.internal.componentframework.services.optional.ControllerInterface
    %

    %  Copyright 2014-2020 The MathWorks, Inc.
    
    methods 
        
        function obj = DesignTimeGbtParentingController(varargin)
            obj = obj@matlab.ui.internal.DesignTimeGBTComponentController(varargin{:});
            
            factory = appdesigner.internal.componentmodel.DesignTimeComponentFactory;            
            obj = obj@appdesservices.internal.interfaces.controller.DesignTimeParentingController( factory );
        
            % Let the client side know the server is ready to receive 
            % any communication
            if nargin > 2
                proxyView = varargin{3};
                obj.fireServerReadyEvent(proxyView);
            end
        end
        
        function populateView(obj, proxyView)
            populateView@matlab.ui.internal.DesignTimeGBTComponentController(obj, proxyView);
            populateView@appdesservices.internal.interfaces.controller.DesignTimeParentingController(obj, proxyView);
        end
        
        function fireServerReadyEvent(obj, proxyView)
            % Dispatch event directly via given peer node because ProxyView.PeerNode
            % will not be set yet so we can't use obj.ClientEventSender
            if ~isempty(proxyView) && ~isempty(proxyView.PeerNode)
                eventData.Name = 'ServerReady';
                viewmodel.internal.factory.ManagerFactoryProducer.dispatchEvent( ...
                    proxyView.PeerNode, 'peerEvent', eventData);
            end
        end
    end
    
    methods (Access=protected)
             
        function deleteChild(~, ~, child)
            % implement the delete of a child
            delete( child );
        end
        
        function excludedPropertyNames = getExcludedPropertyNamesForView(obj)
            % Hook for subclasses to provide a list of property names that
            % needs to be excluded from the properties to sent to the view
            % 
            % Examples:
            % - ScrollableViewportLocation is for internal use only and is not updated by the view
            
            excludedPropertyNames = {'ScrollableViewportLocation'};            
            
            excludedPropertyNames = [excludedPropertyNames; ...
                getExcludedPropertyNamesForView@matlab.ui.internal.DesignTimeGBTComponentController(obj); ...
                ];
		end                             
        
        function handleDesignTimePropertiesChanged(obj, peerNode, valuesStruct)
            
            % Handle resize related properties
            resizePropertyNames = {'SizeChangedFcn', 'AutoResizeChildren'};
            if(any(isfield(valuesStruct, resizePropertyNames)))
                
                % Suppress the warning at the command line when setting
                % SizeChangedFcn or AutoResizeChildren at design time.
                % The warning would otherwise display if AutoResizeChildren
                % is set to 'on' and SizeChangedFcn is not empty or vice
                % versa
                ws = warning('off', 'MATLAB:ui:containers:SizeChangedFcnDisabledWhenAutoResizeOn');
                c = onCleanup(@()warning(ws));
                
                for k = 1:length(resizePropertyNames)                    
                    propertyName = resizePropertyNames{k};
                    
                    if(isfield(valuesStruct, propertyName))
                        % Update the model
                        updatedValue = valuesStruct.(propertyName);
                        obj.getModel().(propertyName) = updatedValue;

                        % Remove the property that was handled from the struct
                        valuesStruct = rmfield(valuesStruct, propertyName);
                    end
                end                
            end
            
            % let the base class handle the rest
            handleDesignTimePropertiesChanged@matlab.ui.internal.DesignTimeGBTComponentController(obj, peerNode, valuesStruct);
        end
    end
end
