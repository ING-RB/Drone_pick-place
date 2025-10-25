classdef (Hidden) DesignTimeComponentFactory < appdesservices.internal.interfaces.model.DesignTimeModelFactory & ...
     matlab.ui.internal.componentframework.services.optional.ControllerInterface
    % DesignTimeComponentFactory  Factory to create component MCOS component objects
    %                               with a proxyView
    
    % Copyright 2017 The MathWorks, Inc.

    methods
        function component = createModel(obj, parentModel, peerNode)
            % create a component as a child of parentModel
            
            import appdesigner.internal.componentmodel.DesignTimeComponentFactory;
            
            % get component type from the peer node
            componentType = char(peerNode.getType());
            
            component = DesignTimeComponentFactory.createComponent(componentType, parentModel, peerNode);
        end
    end
    
    methods(Static)
        function controller = createController(componentType, component, parentController, proxyView, adapterInstance)
            % Make this method be resued by TestFramework for creating
            % designtime controller by passing TestProxyView
            
            import appdesigner.internal.componentmodel.DesignTimeComponentFactory;
            
            % DesignTimeComponentFactory.createComponent (in here) always passes in the adapter
            % instance because it creates it anyway. Other clients won't necessarily have an
            % adapter instance so the parameter is optional and the right adapter will be created
            % if needed; for example, ComponentObjectToStructConverter, AppDesignerTestFramework,
            % GBTTestFramework.
            if nargin < 5
                adapterInstance = DesignTimeComponentFactory.createAdapter(componentType);
            end

            controllerClass = adapterInstance.getComponentDesignTimeController();
            
            controller = feval(controllerClass, ...
                component, parentController, proxyView, adapterInstance);
            
            controller.populateView(proxyView);
        end
        

        function adapter = createAdapter(componentType)
            import appdesigner.internal.componentmodel.DesignTimeComponentFactory;
            
            appDesignEvironment = appdesigner.internal.application.getAppDesignEnvironment();
            adapterMap = appDesignEvironment.getComponentAdapterMap();
            
            if ~isKey(adapterMap, componentType)
                % For user components, create it with the component type
                % 
                % Ex: new UserComponentAdapter(componentType)                
                adapter = appdesigner.internal.componentadapter.uicomponents.adapter.UserComponentAdapter(componentType);
            else
                adapterClass = adapterMap(componentType);
                adapter = feval(adapterClass);
            end
        end
    end
    
    methods (Static, Access = private)            
        function component = createComponent(componentType, parentModel, peerNode)
            
            import appdesigner.internal.componentmodel.DesignTimeComponentFactory;
            
            % Create the component with the given parent or get the 
            % component from loaded objects
            codeName = peerNode.getProperty('CodeName');
            appModel = DesignTimeComponentFactory.getAppModel(parentModel);
            
            isNewComponent = false;
            % Try to get the component from the loaded app data first
            component = appModel.popComponent(codeName);
            
            if isempty(component)
                % It's a new component in a loaded app or a new app, and
                % need to create the component model
                isNewComponent = true;
                
                cleanupObj = appdesigner.internal.componentadapter.uicomponents.adapter.figureutil.listenAndConfigureUIFigure();
                
                if strcmp(componentType, 'matlab.ui.Figure')
                    component = appdesigner.internal.componentadapter.uicomponents.adapter.createUIFigure();
                elseif strcmp(componentType, 'matlab.ui.container.TreeNode')
                        % Pass NodeId to the run time class, so that it
                        % will not assign a different id to tree node.
                        % Node Id should be same at the client and server 
                        % to fetch the TreeNode objects using the id.
                        component = feval(componentType,...
                        'NodeId', convertCharsToStrings(viewmodel.internal.factory.ManagerFactoryProducer.getProperty(peerNode, 'NodeId')),...
                        'Parent', parentModel,...
                        'CreateFcn', []);
                else
                    component = feval(componentType,...
                        'Parent', parentModel,...
                        'CreateFcn', []);
                end
            end
            
            if strcmp(componentType, 'matlab.ui.Figure')
                % Add AppModel property to figure model
                appModelProp = addprop(component, 'AppModel');
                
                % Properties will be transient so that they are not saved
                % to disk
                appModelProp.Transient = true;
                component.AppModel = parentModel;
                % Tell the App Model that it owns this figure
                parentModel.UIFigure = component;
            end
            
            % Set the flag that the peernode now has an associated MATLAB
            % side MCOS component object
            % This flag is to be used by controller, for example,
            % DesignTimeParentingController to check if a PeerNode has a
            % component model created or not.
            % App Designer has received many tech support escalations about
            % duplicated components in the customer's apps. It happens in
            % such a following scenario:
            % 1) Create a Button and a Panel in an app
            % 2) Drag the button into the Panel
            % 3) Save and re-open the app
            % Two buttons would be seen in the Panel.
            % When Panel is added and Button is moved under Panel, two
            % PeerNode events will be fired - 'childAdded' and 'childMoved'
            % from Java PeerNode. During MATLAB side callback is still 
            % handling 'childAdded' event, PeerNode has already synced with
            % client-side, therefore 'childAdded' MATLAB callback would
            % grab the children PeerNodes under Panel and think they are
            % new to create a MATLAB component model for it. Later,
            % 'childMoved' callback would move the button under Figure to
            % the Panel. So two buttons appear under the Panel, one is
            % newly created, and the other is moved.
            % It happens when adding and moving are conducted very fast.
            % see g1918110.
            peerNode.setProperty('IsAttachedtoComponentModel', 'true');

            adapter = DesignTimeComponentFactory.createAdapter(componentType);

            notify(appModel, 'ComponentAdded',  appdesigner.internal.application.ComponentAddedEventData(component));

            % Create the design time proxy view and controller
            hasSyncedToModel = ~isNewComponent;
            designTimeProxView = appdesigner.internal.view.DesignTimeProxyView(peerNode, ...
                hasSyncedToModel); 
            
            DesignTimeComponentFactory.createController(componentType, component, ...
                parentModel.getControllerHandle(), designTimeProxView, adapter);
        end
        
        function appModel = getAppModel(model)
            % Get AppModel through the design time model hierarchy
            appModel = model;
            while ~isa(appModel, 'appdesigner.internal.model.AppModel')
                if isa(appModel, 'matlab.ui.Figure')
                    appModel = appModel.AppModel;
                else
                    appModel = appModel.Parent;
                end
            end            
        end
    end
end

