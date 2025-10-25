classdef  AppDesignerModel < ...
        appdesigner.internal.model.AbstractAppDesignerModel &...
        appdesservices.internal.interfaces.model.ParentingModel

    % The "Model" class of appdesigner
    %
    % This class is responsible for holding onto all open AppModels.
    %

    % Copyright 2013-2023 The MathWorks, Inc.

    properties( GetAccess=public, SetAccess=private)
        % a map of all component adapters registered in the Design
        % Environment.  The keys in the map are component's type
        % (including package info) and the value is that component type's
        % adapter name
        % For example:
        %   key = 'matlab.ui.control.Lamp'
        %   value = appdesigner.internal.componentadapter.uicomponents.adapter.LampAdapter
        ComponentAdapterMap
    end

    properties(Constant)
        % PeerModel manager namespace for App Designer
        NameSpace = '/appdesigner'
    end

    properties (Access = private, Transient = true)
        % listener on the PeerModelManager's rootSet event
        % so the AppDesignerModel object can create ProxyView and Controller
        % appropriately
        PeerModelRootSetListener

        % the PeerModelManager
        % it could be either a PeerModelManager or ViewModelManager. Once
        % we fully migrate to ViewModelManager, rename it to
        % ViewModelManager.
        PeerModelManager

        % Tracks the "actions" we need to run after the peer model root is set.
        % Responsible for opening apps, creating a new app and opening a tutorial.
        DesktopActionQueue                
    end

    properties (Access = {...
            ?appdesigner.internal.application.AppDesignEnvironment, ...
            ?appdesigner.internal.controller.AppDesignerController})
        CompletionObserver
    end

    methods
        function obj = AppDesignerModel(componentAdapterMap)

            narginchk(1,1);

            % validate the input arg
            if ~isempty(componentAdapterMap)
                validateattributes(componentAdapterMap, ...
                    {'containers.Map'}, ...
                    {});
            end

            % save the Map
            obj.ComponentAdapterMap = componentAdapterMap;

            % Initialize with a peer model manager
            obj.initialize()

            obj.DesktopActionQueue = appdesigner.internal.application.DesktopActionQueue();

            obj.CompletionObserver = appdesigner.internal.application.observer.AppActionObserver();
        end

        function delete(obj)

            delete@appdesigner.internal.model.AbstractAppDesignerModel(obj);
            delete@appdesservices.internal.interfaces.model.ParentingModel(obj);

            delete(obj.PeerModelRootSetListener);

            % In debug or test workflow, PeerModelManager may be deleted
            % from outside first.
            if appdesservices.internal.peermodel.PeerNodeProxyView.isValidNode(obj.PeerModelManager)
                delete(obj.PeerModelManager);
            end
        end

%         % Todo: when AysncTask uses backgroundPool(), do the following.
%         % the below setComponentAdatperMap() could be removed too.
%         function adapterMap = get.ComponentAdapterMap(obj)
%             if isempty(obj.ComponentAdapterMap)
%                 obj.ComponentAdapterMap = obj.ComponentAdapterMapTask.fetch(1);
%             end
%             
%             adapterMap = obj.ComponentAdapterMap;
%         end
        
        function setComponentAdapterMap(obj, adapterMap) 
            obj.ComponentAdapterMap = adapterMap;
        end
        
        function openApp(obj, filePath)
            obj.DesktopActionQueue.openApp(filePath);
            obj.runDesktopActionsIfStartupComplete();
        end

        function createNewApp(obj, appFeatures)
            obj.DesktopActionQueue.createNewApp(appFeatures);
            obj.runDesktopActionsIfStartupComplete();
        end

        function openTutorial(obj, tutorialName, appToOpen)
            arguments
                obj,
                tutorialName,
                appToOpen = '';
            end

            obj.DesktopActionQueue.openTutorial(tutorialName, appToOpen);
            obj.runDesktopActionsIfStartupComplete();
        end

        function openAppDetails(obj, filePath)
            obj.DesktopActionQueue.openAppDetails(filePath);
            obj.runDesktopActionsIfStartupComplete();
        end
    end

    methods(Access = 'public')
        function controller = createController(obj, proxyView)
            % Creates the controller

            % create the controller with the proxyView
            controller = appdesigner.internal.controller.AppDesignerController(...
                obj, proxyView, obj.PeerModelManager);

            controller.populateView(proxyView);
        end

        function setDataOnSerializer(obj, serializer)
            % No-op. This model doesn't save any data to the disk
        end
    end

    methods(Access = ?appdesigner.internal.controller.AppDesignerController)
        function runDesktopActionsIfStartupComplete(obj)
            % wait for controller and client side ready to process actions
            if isempty(obj.Controller) || ~isvalid(obj.Controller) || ~obj.Controller.IsClientReady
                return;
            end

            obj.DesktopActionQueue.flush(obj.Controller.ClientEventSender);
        end
    end

    methods (Access = private)
        function initialize(obj)
            % Tells AppDesignerModel to initialize itself, and start
            % observing peer model events.
            %
                        
            % This method will be called in the very beginning of starting
            % AppDesigner, and at that time connector probably would not be
            % fully on, related connector java class path not being set
            % correctly. getClientInstance() call would fail, especially in
            % the cluster, runlikebat much more likely to fail.
            % So ensure connector fully on, and the following call would be
            % no-op if connector already fully started, otherwise wait
            % until fully loaded
            connector.ensureServiceOn();

            uniqueNameSpace = appdesigner.internal.model.AppDesignerModel.NameSpace;
            isServerDriven = false;
            
            serviceProvider = appdesigner.internal.application.getAppDesignerServiceProvider();
            obj.PeerModelManager = serviceProvider.ViewModelManagerFactory.getViewModelManager(uniqueNameSpace, isServerDriven, 'batch');

            % listen to event when the client's root peer node has been
            % created to create Controller and ProxyView accordingly
            obj.PeerModelRootSetListener = addlistener(obj.PeerModelManager, ...
                    'rootSet',@(src,event)obj.handlePeerModelRootSet(event));            
        end                
        
        function handlePeerModelRootSet(obj,event)

            % create a proxyView with the root peer node
            peerNode = event.getTarget();
            proxyView = appdesigner.internal.view.DesignTimeProxyView(peerNode);            

            % create the controller
            obj.createController(proxyView);
        end
    end
end
