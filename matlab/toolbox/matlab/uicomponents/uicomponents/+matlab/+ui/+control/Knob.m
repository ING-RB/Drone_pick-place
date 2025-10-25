classdef (Sealed, ConstructOnLoad=true) Knob < ...
        matlab.ui.control.internal.model.LimitedValueComponent & ...
        matlab.ui.control.internal.model.mixin.TickComponent & ...
        matlab.ui.control.internal.model.mixin.FontStyledComponent & ...
        matlab.ui.control.internal.model.mixin.FocusableComponent
    %

    % Do not remove above white space
    % Copyright 2011-2023 The MathWorks, Inc.

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = Knob(varargin)
            %

            % Do not remove above white space
            %Tick related constants
            scaleLineLength = 200;

            obj = obj@matlab.ui.control.internal.model.mixin.TickComponent(...
                scaleLineLength);

            % Initialize Layout Properties
            locationOffset = [26 19];
            obj.PrivateOuterPosition(1:2) = obj.PrivateInnerPosition(1:2) - locationOffset;
            obj.PrivateOuterPosition(3:4) = [114 103];
            obj.PrivateInnerPosition(3:4) = [60 60];
            obj.AspectRatioLimits = [1 1];
            obj.HasMargins = true;

            obj.Type = 'uiknob';

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
                'Limits',...
                'MajorTicks',...
                'MajorTickLabels',...
                ...Callbacks
                'ValueChangedFcn', ...
                'ValueChangingFcn'};

        end

        function str = getComponentDescriptiveLabel(obj)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.

            str = num2str(obj.Value);
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

