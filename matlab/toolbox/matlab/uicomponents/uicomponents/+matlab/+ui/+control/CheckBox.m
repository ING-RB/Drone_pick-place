classdef (Sealed, ConstructOnLoad=true) CheckBox < ...
        matlab.ui.control.internal.model.AbstractBinaryComponent & ...
        matlab.ui.control.internal.model.mixin.PositionableComponent& ...
        matlab.ui.control.internal.model.mixin.EnableableComponent & ...
        matlab.ui.control.internal.model.mixin.MultilineTextComponent & ...
        matlab.ui.control.internal.model.mixin.WordWrapComponent & ...
        matlab.ui.control.internal.model.mixin.FontStyledComponent & ...
        matlab.ui.control.internal.model.mixin.Layoutable & ...     
        matlab.ui.control.internal.model.mixin.FocusableComponent
    %
    
    % Do not remove above white space
    % Copyright 2011-2024 The MathWorks, Inc.
    
    
    
    methods
        % -----------------------------------------------------------------
        % Constructor
        % -----------------------------------------------------------------
        function obj = CheckBox(varargin)
            %
            
            % Do not remove above white space
            % Defaults
            defaultSize = [84 22];
            obj.PrivateInnerPosition(3:4) = defaultSize;
            obj.PrivateOuterPosition(3:4) = defaultSize;
            
            % Override the default values
            defaultText =  getString(message('MATLAB:ui:defaults:checkboxText'));
            obj.doSetPrivateText(defaultText);
            
            obj.Type = 'uicheckbox';
            
            parsePVPairs(obj, varargin{:});
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
            
            names = {'Value',...
                'Text',...
                ...Callbacks
                'ValueChangedFcn'};
                
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
        end
        function modifyIncomingSerializationContent(sObj) 

           % sObj is the serialization content that was saved for obj 
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj);
        end 

    end
    
end
