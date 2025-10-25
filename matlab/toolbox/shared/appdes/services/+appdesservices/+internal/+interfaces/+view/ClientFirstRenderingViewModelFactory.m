classdef ClientFirstRenderingViewModelFactory < matlab.ui.internal.componentframework.services.optional.ControllerInterface
    %CLIENTFIRSTRENDERINGVIEWMODELFACTORY Factory class to help to create ViewModelPlaceholder object
    %   

    % Copyright 2024 MathWorks, Inc.
    
    properties (Access = private)
        FigureModel;
        AddtionalFigurePropsOnViewModel;
        
        ClientFirstRenderingComponents;
        ClientCreatedViewModels;

        ComponentViewProperties;
        FlattenedComponentViewProperties;
        NeedToGenFlattenedCompViewProps = false;
    end

    properties (Constant)
        DynamicCodeNameProp = 'AD_CodeName';
    end

    methods
        function obj = ClientFirstRenderingViewModelFactory(figureModel, additionalFigurePropsOnViewModel)
            obj.FigureModel = figureModel;
            obj.AddtionalFigurePropsOnViewModel = additionalFigurePropsOnViewModel;
            obj.ClientFirstRenderingComponents = dictionary;
            obj.ClientCreatedViewModels = dictionary;
        end

        function viewModel = create(obj, component, controller, ~, parentViewModel)
            type = controller.getViewModelType(component);
            viewProperties = [];
            
            if isprop(component, obj.DynamicCodeNameProp)
                codeName = component.(obj.DynamicCodeNameProp);                    
                viewProperties = obj.getViewPropertiesForComponentByCodeName(codeName);
            end

            if ~isempty(viewProperties)
                % Store component handle for future quick query
                obj.ClientFirstRenderingComponents{codeName} = component;

                % client/server in-parallel rendering workflow
                if strcmp(type, "matlab.ui.Figure")
                    if isa(parentViewModel, 'appdesservices.internal.interfaces.view.ClientFirstRenderingViewModelPlaceholder')
                        e.Data = struct('Name', 'ClientFirstRenderingViewModelCreated');
                        addlistener(parentViewModel, 'ViewModelAttached', @(~, ~)obj.attachViewModelFromClient(e, parentViewModel.ViewModel));
                    else
                        addlistener(parentViewModel, 'peerEvent', @(s, e)obj.attachViewModelFromClient(e, parentViewModel));
                    end
                end

                % Client side created ViewModel may have been synced to server 
                % when controller is going to be created.
                if isConfigured(obj.ClientCreatedViewModels) && isKey(obj.ClientCreatedViewModels, codeName)
                    viewModel = obj.ClientCreatedViewModels{codeName};
                else
                    viewModel = appdesservices.internal.interfaces.view.ClientFirstRenderingViewModelPlaceholder(parentViewModel, parentViewModel.getViewModelManager(), type, viewProperties);
                end

                if ~isConfigured(obj.ClientCreatedViewModels)
                    % Give ViewModel a chance to finish hand-shake
                    matlab.internal.yield("drawnowNoCallbacks");
                end
            else
                % normal server-driven workflow
                viewProperties = controller.getPropertiesForViewDuringConstruction(component);
                viewModel = viewmodel.internal.factory.ManagerFactoryProducer.addChild(parentViewModel, type, viewProperties);
            end
        end
    end

    methods (Access = private)
        function attachViewModelFromClient(obj, event, rootViewModel)
            function iterateChildren(children)
                for ix = 1 : numel(children)
                    viewModel = children(ix);
                    codeName = viewModel.getProperty(obj.DynamicCodeNameProp);

                    if ~isempty(codeName) && isKey(obj.ClientFirstRenderingComponents, codeName)
                        component = obj.ClientFirstRenderingComponents{codeName};
                        ctrl = component.getControllerHandle();
                        if ~isempty(ctrl)
                            if isa(ctrl.ViewModel, 'appdesservices.internal.interfaces.view.ClientFirstRenderingViewModelPlaceholder')
                                ctrl.ViewModel.attach(viewModel);
                            else
                                obj.ClientCreatedViewModels{codeName} = viewModel;
                            end
                        end
                    end

                    iterateChildren(viewModel.getChildren());
                end
            end

            if strcmp(event.Data.Name, "ClientFirstRenderingViewModelCreated")
                iterateChildren(rootViewModel.getChildren());

                eventData.Name = 'ClientFirstRenderingViewModelAttachedToServer';
                rootViewModel.dispatchEvent('peerEvent', eventData);
                rootViewModel.getViewModelManager().manualCommit();
            end
        end

        function compViewProp = getViewPropertiesForComponentByCodeName(obj, codeName)
            if isempty(obj.ComponentViewProperties)
                obj.ComponentViewProperties = obj.buildComponentViewProperties();
            end

            if ~obj.NeedToGenFlattenedCompViewProps && ...
                    strcmp(obj.ComponentViewProperties.PropertyValues.(obj.DynamicCodeNameProp), codeName)
                % This is figure, so we can return here ealier
                compViewProp = rmfield(obj.ComponentViewProperties, 'Children');

                obj.NeedToGenFlattenedCompViewProps = true;
            else
                compViewProp = obj.getCompViewPropertiesByGenFlattendData(codeName);
            end
        end

        function compViewProps = buildComponentViewProperties(obj)
            import matlab.ui.internal.FigureServices;

            data = FigureServices.getClientFirstRenderingDataForServer(obj.FigureModel, obj.AddtionalFigurePropsOnViewModel);
            
            viewPropResource = data.(FigureServices.CompViewPropsResourceKey);
            additionalFigureViewModelProps = data.(FigureServices.FigureAdditionalViewPropsKey);
            
            if ~isempty(viewPropResource)
                if isfile(viewPropResource)
                    compViewProps = obj.readAndUpdateComponentViewProperties(viewPropResource, additionalFigureViewModelProps);                    
                else
                    compViewProps = viewPropResource;
                end

                obj.ComponentViewProperties = compViewProps;                
            end
        end

        function compViewProps = readAndUpdateComponentViewProperties(~, viewPropResFile, additionalFigureViewModelProps)
            compViewProps = jsondecode(fileread(viewPropResFile));

            fdNames = fieldnames(additionalFigureViewModelProps);
            numField = numel(fdNames);

            for ix = 1 : numField
                key = fdNames{ix};
                compViewProps.PropertyValues.(key) = additionalFigureViewModelProps.(key);
            end
            % Update Uuid
            compViewProps.PropertyValues.Uuid = additionalFigureViewModelProps.Uuid;

            % add Id to figure view properties
            compViewProps.PropertyValues.Id = additionalFigureViewModelProps.FigureViewModelUuid;
        end

        function viewProps = getCompViewPropertiesByGenFlattendData(obj, codeName)
            viewProps = [];
            if isempty(obj.FlattenedComponentViewProperties)
                obj.FlattenedComponentViewProperties = obj.genFlattenedComponentViewProperties();
            end

            if ~isempty(obj.FlattenedComponentViewProperties) &&...
                    isConfigured(obj.FlattenedComponentViewProperties) && isKey(obj.FlattenedComponentViewProperties, codeName)
                viewProps = obj.FlattenedComponentViewProperties{codeName};
            end
        end

        function flattenedCompViewProps = genFlattenedComponentViewProperties(obj)
            function iterateChildren(children)
                numChild = numel(children);
                
                for ix = 1 : numChild
                    childComponentData = children(ix);
                    
                    codeName = childComponentData.PropertyValues.(obj.DynamicCodeNameProp);

                    if isfield(childComponentData, 'Children')
                        flattenedCompViewProps{codeName} = rmfield(childComponentData, 'Children');
                        if ~isempty(childComponentData.Children)
                            iterateChildren(childComponentData.Children);
                        end
                    else
                        flattenedCompViewProps{codeName} = childComponentData;
                    end
                end
            end
            
            if isfield(obj.ComponentViewProperties.PropertyValues, obj.DynamicCodeNameProp)
                flattenedCompViewProps = dictionary;
                iterateChildren(obj.ComponentViewProperties);
            else
                flattenedCompViewProps = [];
            end
        end
    end    
end

