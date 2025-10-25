classdef (Hidden) LayoutContainer < ...
        ... Framework classes
        matlab.ui.container.internal.model.CanvasContainerModel 
    
    % LayoutContainer is the base class of all layout containers
    
    % Copyright 2018 The MathWorks, Inc.
    
    methods
        function obj = LayoutContainer(varargin)
            
        end
        
    end
    
    methods(Access = 'protected')
        
        function addChildLayoutPropChangedListener(obj, child)
            child.addLayoutPropertyValueChangeObserver(obj);
        end
        
        function removeChildLayoutPropChangedListener(obj, child)
            child.removeLayoutPropertyValueChangeObserver(obj);
        end
        
    end
    
    % ---------------------------------------------------------------------
    % Parenting Validation
    % ---------------------------------------------------------------------
    
    methods(Abstract = true, ...
            Static, ...
            Access = {?matlab.ui.internal.mixin.ComponentLayoutable, ...
                      ?matlab.ui.container.internal.model.LayoutContainer})
        layoutOptionsClass = getValidLayoutOptionsClassId()
    end
    
    methods(Access = {?matlab.graphics.mixin.Layoutable, ...
                      ?matlab.ui.container.internal.model.LayoutContainer})
    
        % Override this function in order to handle 
        % a change in the value of the Layout property on a child component
        function handleChildLayoutPropChanged(~, ~)            
            % Noop
        end
        
        function ret = validateChildsLayoutOptions(obj, layoutOptions)
            layoutOptionsClass = obj.getValidLayoutOptionsClassId();
            ret = isa(layoutOptions, layoutOptionsClass);
        end

    end
    
    
end


