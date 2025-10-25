classdef (Hidden) ParentableComponent < ...
        appdesservices.internal.interfaces.model.AbstractModelMixin
    % ParentableComponent is the parent class of a component that can be
    % parented to other components.
    
    % Copyright 2012-2018 The MathWorks, Inc.
    
    methods
        function obj = ParentableComponent()
            
        end
    end
    
    methods(Access = 'protected')
        function validateParentAndState(obj, newParent)
            % Validator for 'Parent'
            %
            % Can be extended / overriden to provide additional validation
            
            % Error Checking
            %
            % A valid parent is one of:
            % - a parenting component
            % - empty []
            
            % Only validate if the value is non empty
            %
            % Empty values are acceptible for not having a parent
            if(~isempty(newParent))
                
                isAcceptableParent = ...
                    ... Canvas container is the common superclass for components
                    ... like Panel and Tab which accept components.  It does
                    ... not include specialized containers like menu, tree, treenode, tabgroup
                    isa(newParent, 'matlab.ui.internal.mixin.CanvasHostMixin') && ...
                    ... Containers that are also a canvas container, but not a valid parent
                    ~isa(newParent, 'matlab.ui.container.internal.UIFlowContainer')  && ...
                    ~isa(newParent, 'matlab.ui.container.internal.UIGridContainer') || ...
                    ...
                    isa(newParent, 'matlab.ui.container.internal.AccordionPanel') || ...
                    isa(newParent, 'matlab.ui.container.internal.SidePanel') || ...
                    ...
                    isa(newParent, 'matlab.ui.controls.ToolbarDropdown') || ...
                    isa(newParent, 'matlab.ui.controls.AxesToolbar') || ...
                    ...
                    isa(newParent, 'matlab.ui.container.internal.model.LayoutContainer') && ...
                    isa(obj, 'matlab.ui.control.internal.model.mixin.Layoutable');
                
                if( ~isAcceptableParent )
                    
                    if (isa(newParent, 'matlab.ui.container.internal.UIFlowContainer')  || ...
                        isa(newParent, 'matlab.ui.container.internal.UIGridContainer') )                    
                        
                        % Different error message for the undocumented containers                        
                        newParentClassName = matlab.ui.control.internal.model.PropertyHandling.getComponentClassName(newParent);
                        childClassName = matlab.ui.control.internal.model.PropertyHandling.getComponentClassName(obj);                        
                        messageObj = message('MATLAB:ui:components:invalidLayoutContainer', ...
                            newParentClassName, childClassName, 'GridLayout', 'uigridlayout');
                    else 
                        messageObj = message('MATLAB:ui:components:invalidParent', ...
                            'Parent');
                    end
                    
                    % MnemonicField is last section of error id
                    mnemonicField = 'invalidParent';
                    
                    % Use string from object
                    messageText = getString(messageObj);
                    
                    % Create and throw exception
                    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                    throw(exceptionObject);                    
                end

            end
            
        end

	end      
end



