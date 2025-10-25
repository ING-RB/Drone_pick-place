classdef (Sealed, ConstructOnLoad=true) DiscreteKnob < ...
        matlab.ui.control.internal.model.AbstractStateComponent & ...  
        matlab.ui.control.internal.model.mixin.FontStyledComponent & ...
        matlab.ui.control.internal.model.mixin.PositionableComponent & ...
        matlab.ui.control.internal.model.mixin.Layoutable & ...
        matlab.ui.control.internal.model.mixin.FocusableComponent
    %
    
    % Do not remove above white space
    % Copyright 2011-2023 The MathWorks, Inc.
    
    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = DiscreteKnob(varargin)                       
            %
            
            % Do not remove above white space
            % Discrete Knobs states can be between [2, Inf]
            sizeConstraints = [2, Inf];
            obj = obj@matlab.ui.control.internal.model.AbstractStateComponent(sizeConstraints);
            
            % Selection strategy for the discrete knob is always ExactlyOne
            obj.SelectionStrategy = matlab.ui.control.internal.model.ExactlyOneSelectionStrategy(obj);
            
            % Position defaults
            locationOffset = [27 0];
            obj.PrivateOuterPosition(1:2) = obj.PrivateInnerPosition(1:2) - locationOffset;
            obj.PrivateOuterPosition(3:4) = [127 78];
            obj.PrivateInnerPosition(3:4) = [60 60];
            obj.AspectRatioLimits = [1,1];
            obj.HasMargins = true;
            
            
            % DiscreteKnob has specific default values for properties
            obj.PrivateItems = {  getString(message('MATLAB:ui:defaults:offState')), ... 
                            getString(message('MATLAB:ui:defaults:lowState')), ... 
                            getString(message('MATLAB:ui:defaults:mediumState')), ... 
                            getString(message('MATLAB:ui:defaults:highState')) }; 
                
            obj.PrivateSelectedIndex = 1;
            
            obj.Type = 'uidiscreteknob';
            
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
            
            names = {...
                'Value',...
                'Items',...
                'ItemsData',...
                ...Callbacks
                'ValueChangedFcn'};
                
        end
        
        function str = getComponentDescriptiveLabel(obj)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.

            % Return the text of the selected item
            % Note that this is the same as Value when ItemsData is empty
            index = obj.SelectedIndex;
            str = obj.SelectionStrategy.getSelectedTextGivenIndex(index); 

        end
    end
    
    % ---------------------------------------------------------------------
    % Theme Functions
    % ---------------------------------------------------------------------
    methods (Hidden, Access='protected', Static)
        function map = getThemeMap
            % GETTHEMEMAP - This method returns a struct describing the 
            % relationship between class properties and theme attributes.

            %             Knob Prop    Theme Attribute
            map = struct('FontColor', '--mw-color-primary');
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

