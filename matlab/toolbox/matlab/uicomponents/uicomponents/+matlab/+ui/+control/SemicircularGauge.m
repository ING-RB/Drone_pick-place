classdef (Sealed, ConstructOnLoad=true) SemicircularGauge < ...
        matlab.ui.control.internal.model.AbstractScaleDirectionComponent & ...
        matlab.ui.control.internal.model.mixin.FontStyledComponent & ...
        matlab.ui.control.internal.model.mixin.Layoutable & ...
        matlab.ui.control.internal.model.mixin.OrientableComponent
    %
    
    % Do not remove above white space
    % Copyright 2011-2023 The MathWorks, Inc.
    
    properties (Access = protected, Constant)
        % Implement abstract property
        ValidOrientations cell = {'north', 'south', 'east', 'west'};
    end
    
    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = SemicircularGauge(varargin)

            scaleLineLength = 101;
            obj = obj@matlab.ui.control.internal.model.AbstractScaleDirectionComponent(...
                scaleLineLength);

            % Initialize Layout Properties
            defaultSize = [120, 65];
            obj.PrivateInnerPosition(3:4) = defaultSize;
            obj.PrivateOuterPosition(3:4) = defaultSize;
            obj.AspectRatioLimits = [120/65, 120/65];
            
            obj.Type = 'uisemicirculargauge';

            % Initialize Orientation
            obj.PrivateOrientation = 'north';
            
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
                'ScaleDirection',...
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
            % when orientation changes from south to north, east to west or vice
            % versa, keep the Size and OuterSize as is. otherwise transpose the
            % width and height of both the inner art and the outer art
            % (they are the same for the semicircular gauge).
            % this is because the south and north orientations have the same form factor.
            % Similarly, east and west have the same form factor.
            if(strcmpi(oldOrientation, 'north') && strcmpi(newOrientation, 'south')...
                    || strcmpi(oldOrientation, 'south') && strcmpi(newOrientation, 'north')...
                    || strcmpi(oldOrientation, 'east') && strcmpi(newOrientation, 'west')...
                    || strcmpi(oldOrientation, 'west') && strcmpi(newOrientation, 'east'))
                dirtyProperties = {};
            else
                % Update position related properties 
                obj.updatePositionPropertiesAfterOrientationChange(...
                    oldOrientation, newOrientation);
            
                % Push to view values that are certain
                % Do not push estimated OuterPosition to the view
                dirtyProperties = {...
                    'AspectRatioLimits',...
                    'InnerPosition', ...
                    };
            end
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

