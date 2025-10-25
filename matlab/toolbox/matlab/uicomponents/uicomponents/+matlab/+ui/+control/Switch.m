classdef (Sealed, ConstructOnLoad=true) Switch < ...
        matlab.ui.control.internal.model.AbstractSwitchComponent & ...
        matlab.ui.control.internal.model.mixin.Layoutable & ...
        matlab.ui.control.internal.model.mixin.FocusableComponent
    %
    
    % Do not remove above white space
    % Copyright 2011-2024 The MathWorks, Inc.
    
    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = Switch(varargin)

            obj = obj@matlab.ui.control.internal.model.AbstractSwitchComponent(...
                'horizontal');
            
            % Initialize Layout Properties
            locationOffset = [21, 0];
            obj.PrivateOuterPosition(1:2) = obj.PrivateInnerPosition(1:2) - locationOffset;
            obj.PrivateInnerPosition(3:4) = [45 20];
            obj.PrivateOuterPosition(3:4) = [88 20];
            obj.AspectRatioLimits = [45/20 45/20];
            obj.HasMargins = true;
            
            obj.Type = 'uiswitch';
            
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
                'ItemsData', ...
                'Orientation',...
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

