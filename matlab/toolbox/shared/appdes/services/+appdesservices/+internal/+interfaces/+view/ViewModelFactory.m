classdef ViewModelFactory < matlab.ui.internal.componentframework.services.optional.ControllerInterface
    %VIEWMODELFACTORY Facotry class to help to create ViewModel object 
    % for components
    %   

    % Copyright 2023 - 2024 MathWorks, Inc.
    
    properties (Constant)
        UACBaseClassName = "matlab.ui.componentcontainer.ComponentContainer";
        UACClientDrivenPropertyName = "IsClientDriven";
    end

    methods 
        function viewModel = create(obj, component, controller, parentController, parentViewModel)
            viewModel = appdesservices.internal.interfaces.view.EmptyViewModel.Instance;
            
            if obj.isUnderClientDrivenUAC(component)
                viewModel = obj.retrieveChildViewModel(component, parentViewModel, parentController);
            else
                if ~isempty(parentViewModel) && isvalid(parentViewModel)
                    % Under scenario of getting defaults, there would be no view to be created,
                    % so ViewModel would not be created.
                    viewProperties = controller.getPropertiesForViewDuringConstruction(component);
                    type = controller.getViewModelType(component);
    
                    viewModel = obj.addChildViewModel(parentViewModel, type, viewProperties);
                end
            end
        end

        function isClientDriven = isUnderClientDrivenUAC(obj, component)
            isClientDriven = false;

            ancestorUACModel = ancestor(component, obj.UACBaseClassName);
            
            if ~isempty(ancestorUACModel)
                uacCtrl = ancestorUACModel.getControllerHandle();
                
                if ~isempty(uacCtrl) && ~isempty(uacCtrl.ViewModel) && isvalid(uacCtrl.ViewModel)
                    isClientDriven = (uacCtrl.ViewModel.getProperty(obj.UACClientDrivenPropertyName) == true);
                end
            end
        end
    end

    methods(Access = protected)
        function viewModel = retrieveChildViewModel(obj, compModel, parentViewModel, parentController)
            viewModel = [];
            
            parentComponent = compModel.Parent;
            childrenViewModel = parentViewModel.getChildren();

            if isempty(childrenViewModel)
                return;
            end

            % Get all model children
            childrenComponents = appdesservices.internal.interfaces.view.ViewModelFactory.getAllChildren(parentComponent, parentController);
            
            % Get index of model child
            for ix = 1:numel(childrenComponents)
                if eq(compModel, childrenComponents(ix))
                    viewModel = childrenViewModel(ix);
                    break;
                end
            end
        end

        function viewModel = addChildViewModel(~, parentViewModel, type, varargin)
            viewModel = viewmodel.internal.factory.ManagerFactoryProducer.addChild(parentViewModel, type,varargin{:});
        end
    end
    
    methods(Static)
        function children = getAllChildren(parentModel, ctrl, varargin)
            children = [];
            if nargin == 1
                ctrl = parentModel.getControllerHandle();
            end

            findallParams = {'-not', '-isa', 'matlab.graphics.primitive.canvas.HTMLCanvas', '-not','Type', 'annotationpane'};
            if nargin > 2
                findallParams = [findallParams, varargin];
            end

            % Get all model children
            if isa(parentModel, appdesservices.internal.interfaces.view.ViewModelFactory.UACBaseClassName)
                % NodeChildren returns all children regardless HandleVisibility being set to 'on/off'
                children = parentModel.NodeChildren;
            elseif isprop(parentModel, "Children")
                children = allchild(parentModel); 
            end

            % Remove AnnotationPane from children list and Axes
            if ~isempty(children)
                children = findall(children, 'flat', findallParams{:});
            end

            if isempty(children)
                return;
            end

            if ~isempty(ctrl)
                if ctrl.isChildOrderReversed()
                    children = flip(children);
                end
            elseif isa(parentModel, "matlab.ui.container.FIFOContainer")
                children = flip(children);
            end
        end

        function childrenList = getDescendants(parent, childrenList)
            % Returns all the children of the object, including the
            % grand children, great grand children, etc.

            if isvalid(parent)
                if nargin == 1
                    childrenList = [];
                end

                % Add entry to childrenList
                childrenList = [childrenList, parent];
                
                    modelChildren = appdesservices.internal.interfaces.view.ViewModelFactory.getAllChildren(parent);

                    % loop through children and add their children to the list
                    for index = 1:numel(modelChildren)
                        child = modelChildren(index);
                        % Add grand children to the list with depth first
                        % recursively

                        % Do not get the sub-objects of UIAxes because
                        % this is not a Container component
                        if(strcmpi(class(child), 'matlab.ui.control.UIAxes'))
                            % Add UIAxes itself to childrenList
                            childrenList = [childrenList, child];
                        else
                            % Child itself will be added into the list in the
                            % recursive calling
                            childrenList = appdesservices.internal.interfaces.view.ViewModelFactory.getDescendants(child, childrenList);
                        end
                    end
            end
        end
    end
end

