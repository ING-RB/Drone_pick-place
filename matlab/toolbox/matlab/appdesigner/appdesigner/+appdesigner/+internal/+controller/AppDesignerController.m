classdef AppDesignerController < ...
        appdesservices.internal.interfaces.controller.AbstractController & ...
        appdesservices.internal.interfaces.controller.AppDesignerParentingController & ... 
        matlab.ui.internal.componentframework.services.optional.ControllerInterface
        
    % AppDesignerController is the controller for AppDesigner.

    % Copyright 2013-2023 The MathWorks, Inc.
    properties (SetAccess = ?matlab.ui.internal.componentframework.services.optional.ControllerInterface, ...
        GetAccess = public)
        % indicate that AppDesignerModel is ready on the client
        IsClientReady = false
    end
    methods
        
        function obj = AppDesignerController(model, proxyView, peerModelManager)
            % OBJ = APPDESIGNERCONTROLLER(model) creates
            % a new instance of the App DesignerController.
            
            % There is no parent controller because the AppDesigner is the
            % "root"
            parentController = [];
            obj = obj@appdesservices.internal.interfaces.controller.AbstractController(model, parentController, proxyView);
            
            % construct the DesignTimeParentingController with the factory to
            % create child model objects
            factory = appdesigner.internal.model.AppDesignerChildModelFactory();
            
            obj = obj@appdesservices.internal.interfaces.controller.AppDesignerParentingController(factory);
        end
        
        function populateView(obj, proxyView)
            populateView@appdesservices.internal.interfaces.controller.AbstractController(obj, proxyView);
            populateView@appdesservices.internal.interfaces.controller.AppDesignerParentingController(obj, proxyView);
        end
        
        function delete(obj)
            delete@appdesservices.internal.interfaces.controller.AbstractController(obj);
            delete@appdesservices.internal.interfaces.controller.AppDesignerParentingController(obj);
        end

        % Provides a window UUID for the App Designer Window
        %
        % Uses the root ViewModel ID
        function uuid = getWindowUUID(obj)
            uuid = 'appdesigner_binary_channel';
        end
    end
    
    methods(Access = 'protected')
                  
        function handleEvent(obj, source, event)
            if ~viewmodel.internal.factory.ManagerFactoryProducer.isEventFromClient(event)
                return;
            end

             switch (event.Data.Name)
                case 'AppDesignerModelClientSideReady'
                    obj.handleClientSideReady()
                 case 'AppModelOpened'
                    obj.handleAppModelOpened(event.Data.Filename);
             end
        end
    
        function excludedPropertyNames = getExcludedPropertyNamesForView(obj)
            % By default, all public properties are pushed to the view
            % Remove all of them since no properties are needed by the view 
            excludedPropertyNames = properties(obj.Model);
        end
        
        function pvPairsForView = getPropertiesForView(obj, ~)
            %  No-op
            pvPairsForView = {};
        end
        
    end

    methods (Access = private)
        function handleClientSideReady(obj)
            % process actions (open app, new app, etc) that were waiting for client side ready
            obj.IsClientReady = true;
            obj.Model.runDesktopActionsIfStartupComplete();
        end
        function handleAppModelOpened(obj, filename)
            childModel = findobj(obj.Model.Children, 'FullFileName', filename, '-depth', 1);

            if numel(childModel) > 1
                % There's a chance that the last one is still in closing processing 
                % when 'AppModelOpened' event is sent to server from client.
                % In such a situation, the last one should be the one to use
                childModel = childModel(end);
            end

            obj.Model.CompletionObserver.notify('AppOpened', appdesigner.internal.application.observer.AppOpenedEventData(childModel));
        end
    end
end
