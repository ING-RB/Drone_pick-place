classdef  AbstractAppDesignerModel < ...
        appdesservices.internal.interfaces.model.AbstractModel & ...
        matlab.mixin.Heterogeneous & ...
        matlab.ui.internal.componentframework.services.optional.ControllerInterface % Give access to getControllerHandle in GBT component
    % Parent class for all App Designer design time models
    %
    % This class provides the implementation for AbstractModel abstract
    % classes.
    %
    % Additionally, it provides a "Controller" property as a convenience of
    % not having to directly use getController / setController.  As these
    % model objects are not part of the HG hierarchy, there is no name
    % collison.
    
    % Copyright 2014-2015 The MathWorks, Inc.
    
    properties(...
            SetAccess = { ...
            ?appdesservices.internal.interfaces.model.AbstractModel, ...
            ?appdesservices.internal.interfaces.model.AbstractModelMixin, ...
            ?appdesservices.internal.interfaces.controller.AbstractController},  ...
            ...
            GetAccess = { ...
            ?appdesservices.internal.interfaces.model.AbstractModel, ...
            ?appdesservices.internal.interfaces.model.AbstractModelMixin, ...
            ?appdesservices.internal.interfaces.controller.AbstractController},  ...
            ...
            Transient=true ...
            )
        % A appdesservices.internal.interfaces.model.AbstractController
        Controller;
    end
    
    methods(Abstract, Access = 'public')
        % CREATECONTROLLER(OBJ, PARENTCONTROLLER, PROXYVIEW) creates the
        % controller for the AppDesigner specific models.
        % 
        controller = createController(obj, parentController, proxyView)

        % SETDATAONSERIALIZER(OBJ, SERIALIZER) Used by the App Designer design time models
        % that contains data which needs to be saved to disk.
        %
        setDataOnSerializer(obj, serializer)
    end

    
    % Implementations of parent class interface
    methods(Access = { ...
            ?appdesservices.internal.interfaces.model.AbstractModel, ...
            ?appdesservices.internal.interfaces.model.AbstractModelMixin, ...
            ?appdesservices.internal.interfaces.controller.AbstractController, ...
            ?appdesservices.internal.interfaces.controller.AbstractControllerMixin })
        
        function controller = getController(obj)
            controller = obj.Controller;
        end
        
        function markViewPropertiesDirty(obj, propertyNames)
            % no-op for design-time model, which is called by AbstractModel
            % markPropertiesDirty() and is a method for performance optimization
            % with view property cache
        end
        
        function notifyPropertyChange(obj, propertyNames)
            % no-op for design-time model, which is called by AbstractModel
            % this method informs figure for property change of component
        end
    end
    
    methods(Access = { ...
            ?appdesservices.internal.interfaces.model.AbstractModel, ...
            ?appdesservices.internal.interfaces.model.AbstractModelMixin, ...
            ?appdesservices.internal.interfaces.controller.AbstractController, ...
            ?appdesservices.internal.interfaces.controller.AbstractControllerMixin })
        
        function setController(obj, controller)
            obj.Controller = controller;
        end
    end
    
    methods(Access = { ...
			?appdesservices.internal.interfaces.controller.AbstractController, ...
			?appdesservices.internal.interfaces.controller.AbstractControllerMixin, ...
            ?appdesigner.internal.application.AppDesignerWindowController, ...
            ?appdesservices.internal.interfaces.model.DesignTimeModelFactory})
        
        function controller = getControllerHandle(obj)
            %  return this model's controller.  This method was added as
            %  an alias to standardize how to access a model's controller 
            %  in the code. With this method all models, both component and
            %  appdesigner, have a common way to access their controllers.
            controller = obj.getController();
        end
    end  
    
end