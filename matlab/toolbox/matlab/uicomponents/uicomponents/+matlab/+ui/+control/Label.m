classdef (Sealed, ConstructOnLoad=true) Label < ...
        matlab.ui.control.internal.model.ComponentModel & ...
        matlab.ui.control.internal.model.mixin.BackgroundColorableWithNoneComponent & ...
        matlab.ui.control.internal.model.mixin.HorizontallyAlignableComponent & ...
        matlab.ui.control.internal.model.mixin.HorizontalClippingComponent & ...
        matlab.ui.control.internal.model.mixin.VerticallyAlignableComponent & ...
        matlab.ui.control.internal.model.mixin.MultilineTextComponent & ...
        matlab.ui.control.internal.model.mixin.WordWrapComponent & ...
        matlab.ui.control.internal.model.mixin.FontStyledComponent & ...
        matlab.ui.control.internal.model.mixin.PositionableComponent& ...
        matlab.ui.control.internal.model.mixin.EnableableComponent & ...
        matlab.ui.control.internal.model.mixin.VisibleComponent & ...
        matlab.ui.control.internal.model.mixin.TooltipComponent & ...
        matlab.ui.control.internal.model.mixin.Layoutable & ...     
        matlab.ui.control.internal.model.mixin.FocusableComponent & ...
        matlab.ui.control.internal.model.mixin.InterpretableComponent
    %
    
    % Do not remove above white space
    % Copyright 2011-2023 The MathWorks, Inc.
        
    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = Label(varargin)
            %
            
            % Do not remove above white space
            % Defaults
            defaultSize = [31, 22];
			obj.PrivateInnerPosition(3:4) = defaultSize;
			obj.PrivateOuterPosition(3:4) = defaultSize;
			obj.Type = 'uilabel';
            
            % Override the default values                        
            defaultText =  getString(message('MATLAB:ui:defaults:labelText')); 
            obj.doSetPrivateText(defaultText);
                        
            parsePVPairs(obj,  varargin{:});
        end
             
    end        
    
    % ---------------------------------------------------------------------
    % Custom Display Functions
    % ---------------------------------------------------------------------
    methods(Access = protected)
        
        function names = getPropertyGroupNames(obj)
            % GETPROPERTYGROUPNAMES - This function returns common
            % properties for this class that will be displayed in the
            % curated list properties for all components implementing this
            % class.
            
            names = {'Text'};
                
        end
        
        function str = getComponentDescriptiveLabel(obj)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            str = obj.Text;
        
        end
    end
    methods (Hidden, Static) 
        function modifyOutgoingSerializationContent(sObj, obj) 

           % sObj is the serialization content for obj 
           modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj, obj);
           modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.BackgroundColorableWithNoneComponent(sObj, obj);
        end
        function modifyIncomingSerializationContent(sObj) 

           % sObj is the serialization content that was saved for obj 
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj);
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.BackgroundColorableWithNoneComponent(sObj);
        end 

    end
end
