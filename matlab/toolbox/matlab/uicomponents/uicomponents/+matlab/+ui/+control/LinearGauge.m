classdef (Sealed, ConstructOnLoad=true) LinearGauge < ...
        matlab.ui.control.internal.model.AbstractGaugeComponent & ...        
        matlab.ui.control.internal.model.mixin.FontStyledComponent & ...
        matlab.ui.control.internal.model.mixin.OrientableComponent & ...
        matlab.ui.control.internal.model.mixin.Layoutable 
    %
    
    % Do not remove above white space
    % Copyright 2011-2023 The MathWorks, Inc.
    
    properties (Access = protected, Constant)
        ValidOrientations cell = {'horizontal', 'vertical'};
    end
    
    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = LinearGauge(varargin)

            scaleLineLength = 90;
            obj = obj@matlab.ui.control.internal.model.AbstractGaugeComponent(scaleLineLength);

            % Default for Orientation
            obj.PrivateOrientation = 'horizontal';
            
            obj.Type = 'uilineargauge';
            
            % Initialize Layout Properties
            defaultSize = [120, 40];
            obj.PrivateInnerPosition(3:4) = defaultSize;
            obj.PrivateOuterPosition(3:4) =  defaultSize;
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
                'ScaleColors',...
                'ScaleColorLimits',...
                'Orientation'};
                
        end
        
        function str = getComponentDescriptiveLabel(obj)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            str = num2str(obj.Value);

        end
    end

    methods (Access = protected)
        function dirtyProperties = updatePropertiesAfterOrientationChanges(obj, oldOrientation, newOrientation)
            % Update position related properties 
            obj.updatePositionPropertiesAfterOrientationChange(...
                oldOrientation, newOrientation);
            
            % Push to view values that are certain
            % Do not push estimated OuterPosition to the view
            dirtyProperties = {	...
                'AspectRatioLimits',...
                'InnerPosition', ...
                };
        end
    end
    methods (Hidden, Static) 
        function modifyOutgoingSerializationContent(sObj, obj) 

           % sObj is the serialization content for obj 
           modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj, obj);
           modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.BackgroundColorableComponent(sObj, obj);
        end
        function modifyIncomingSerializationContent(sObj) 

           % sObj is the serialization content that was saved for obj 
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj);
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.BackgroundColorableComponent(sObj);
        end 

    end
    
end

