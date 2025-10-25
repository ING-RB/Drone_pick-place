classdef (Hidden) ComponentModel < ...
        matlab.ui.control.WebComponent & ...
        matlab.ui.control.internal.model.AbstractComponent
    % COMPONENTMODEL is the parent class of all non-figure component
    % models used in HMI.
    %
    % It defers to a factory for creating all controllers.
    
    % Copyright 2012-2023 The MathWorks, Inc.
    
    methods
        function obj = ComponentModel()
            
        end
    end
    % ---------------------------------------------------------------------
    % Parenting Validation
    % ---------------------------------------------------------------------
    
    methods(Access = 'protected')
        function validateParentAndState(obj, newParent)
            % MATLAB Component Framework (MCF) triggers this method at the time
            % of parenting.
            
            % Default validation is owned by ParentableComponent mixin
            validateParentAndState@matlab.ui.control.internal.model.mixin.ParentableComponent(obj, newParent)
        end
        
        function ret = sendPropertyChangeToView(obj, propertyName)
            % This method will be called by WebComponent base class
            % When a property defined in through GBT/C++ infrastructure is
            % changed (currently includes position related properties,
            % Layout Manager related properties and
            % common GBT properties inherited through mixins)
            % (@TODO: Identical method exists in 
            %   matlab.ui.container.internal.model.ContainerModel
            %   This method CANNOT be moved into AbstractComponent.) 
            obj.markPropertiesDirty({propertyName});
            ret = 'true';
        end
    end

    methods(Hidden)
        function markContextMenuDirty(obj)
            obj.markViewPropertiesDirty({'ContextMenu'});
        end
    end
    
    
    % ---------------------------------------------------------------------
    % Framework Requirements:
    % Assumes both WebComponent and AppDes AbstractModel exist
    % ---------------------------------------------------------------------
    methods(Access = 'public', Hidden = true)
        function controller = createController(obj, parentController, ~)
            % CREATECONTROLLER(OBJ) Creates a controller for the model.
            %
            % Running figure with HG, there are two inputs:
            %
            % parentController, and []
            % Todo: When HG removed the last [] argument, clean the related
            % code
            %
            
            assert(~isempty(parentController), ...
                'Parent Controller should not be empty for component.');
            
            % Defer to the factory
            controllerFactory = matlab.ui.control.internal.controller.ComponentControllerFactoryManager.Instance.ControllerFactory;
            % Todo: Remove ComponentControllerFactory and singleton ComponentControllerFactoryManager
            % because there's probably no need for them since decoupling
            % the design time logic
            controller = controllerFactory.createController(...
                obj, ...
                parentController);
            
        end
        
    end
    
    methods(Access = { ...
            ?appdesservices.internal.interfaces.model.AbstractModel, ...
            ?appdesservices.internal.interfaces.model.AbstractModelMixin, ...
            ?appdesservices.internal.interfaces.controller.AbstractController, ...
            ?appdesservices.internal.interfaces.controller.AbstractControllerMixin})
        
        function controller = getController(obj)
            controller = obj.Controller;
        end
    end
    
    methods(Access = { ...
            ?appdesservices.internal.interfaces.model.AbstractModel, ...
            ?appdesservices.internal.interfaces.model.AbstractModelMixin, ...
            ?appdesservices.internal.interfaces.controller.AbstractController, ...
            ?appdesservices.internal.interfaces.controller.AbstractControllerMixin})
        
        function setController(obj, controller)
            obj.Controller = controller;
        end
    end
    
    % ---------------------------------------------------------------------
    % Framework Requirements:
    % Assumes WebComponent exists
    % ---------------------------------------------------------------------
    
    methods (Access = 'public')
        function reset(obj)
            % RESET - This function overrides functionality provided by
            % the graphics base class.  For UI Components, reset is not
            % currently supported.
            
            messageObj = message('MATLAB:ui:components:functionOrPropertyNotSupported', ...
                'reset', class(obj));
            
            % MnemonicField is last section of error id
            mnemonicField = 'functionOrPropertyNotSupported';
            
            % Use string from object
            messageText = getString(messageObj);
            
            % Create and throw exception
            exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
            throw(exceptionObject);
        end
        
    end

    methods (Access = 'protected')
        function doUpdate(obj)
            % DOUPDATE - This function overrides
            % default no-op functionality provided by UIComponent.  For
            % MATLAB-implemented components, properties changed in the
            % Model must explicitly be flushed to the controller.
            
            obj.flushDirtyProperties();
        end
    end
    
    methods (Access = {...
            ?appdesservices.internal.interfaces.model.AbstractDirtyPropertyStrategy})
        function doMarkDirty(obj, flag)
            obj.markDirty(flag);
        end
    end

    methods(Access = {...
            ?matlab.ui.control.internal.model.ComponentModel, ...
            ?matlab.ui.internal.componentframework.services.optional.BehaviorAddOn, ...
            ?appdesservices.internal.interfaces.controller.AbstractController, ...
            ?appdesservices.internal.interfaces.controller.AbstractControllerMixin, ...            
            })

        function isDirty = isPropertyMarkedDirty(obj, propertyName)
            % Override of the c++ implementation for the MATLAB-based
            % components
            isDirty = obj.isInDirtyProperties(propertyName);
        end

    end
    methods(Access='public', Static=true, Hidden=true)
        function hObj = doloadobj( hObj)
            % hObj may be an Iconable Object or struct
            hObj.disableCache();
        end
    end
end


