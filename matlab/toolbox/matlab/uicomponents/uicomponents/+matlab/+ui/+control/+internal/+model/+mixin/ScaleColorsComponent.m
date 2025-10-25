classdef (Hidden) ScaleColorsComponent < appdesservices.internal.interfaces.model.AbstractModelMixin & ...
        matlab.graphics.mixin.internal.GraphicsDataTypeContainer
    % This undocumented class may be removed in a future release.
    
    % This is a mixin parent class for all visual components that have an
    % the ScaleColors/ScaleColorLimits property
    %
    % This class provides all implementation and storage for
    % 'ScaleColors' and 'ScaleColorLimits'.
    
    % Copyright 2018-2021 The MathWorks, Inc.
    
    properties(Dependent, AbortSet)
        ScaleColors = [];
        
        ScaleColorLimits = [];
    end
    
     properties(Access = 'protected')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, beacuse sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set
        
        PrivateScaleColors = [];
        
        PrivateScaleColorLimits = [];
        
        PrivateScaleColorLimitsMode = 'auto';
     end
    methods
       
        % -----------------------------------------------------------------
        
        function set.ScaleColors(obj, newScaleColors)
            % Error Checking
            try
                newScaleColors = matlab.ui.control.internal.model.PropertyHandling.validateColorsArray(obj, newScaleColors);
            catch ME %#ok<NASGU>
                messageObj =  message('MATLAB:ui:components:invalidColorArray', ...
                    'ScaleColors');
                
                % Use string from object
                messageText = getString(messageObj);
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidScaleColors';
                              
                % Create and throw exception 
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, '%s', messageText);
                throwAsCaller(exceptionObject);
                
            end
            
            % Property Setting
            obj.PrivateScaleColors = newScaleColors;
            
            % Updates
            obj.updateScaleColorLimits();
            
            obj.markPropertiesDirty({'ScaleColors', 'ScaleColorLimits'});
        end
        
        function value = get.ScaleColors(obj)
            value = obj.PrivateScaleColors;
        end
        
        % -----------------------------------------------------------------
        
        function set.ScaleColorLimits(obj, scaleColorLimits)
            
            % validateattributes() does not handle cases like "It can be an
            % Nx2 OR empty", so it is easiest to check explicitly.
            
            %  Special check for []
            if(isempty(scaleColorLimits) && isnumeric(scaleColorLimits))
                obj.PrivateScaleColorLimits = [];
                obj.markPropertiesDirty({'ScaleColorLimits'});
                
                obj.PrivateScaleColorLimitsMode = 'manual';
                return;
            end
            
            % Error Checking
            try
                % Ensure the input is a N x 2
                validateattributes(scaleColorLimits, ...
                    {'numeric'}, ...
                    {'size', [NaN, 2]});
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidScaleColorLimits', ...
                    'ScaleColorLimits');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidScaleColorLimits';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception 
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            % Ensure that every row is increasing
            isFirstElementLessThanSecond = scaleColorLimits(:, 1) < scaleColorLimits(:, 2);
            
            if(~all(isFirstElementLessThanSecond))
                messageObj = message('MATLAB:ui:components:nonIncreasingScaleColorLimits', ...
                    'ScaleColorLimits');
                
                % MnemonicField is last section of error id
                mnemonicField = 'nonIncreasingScaleColorLimits';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception 
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);

            end
            
            % Property Setting
            obj.PrivateScaleColorLimits = scaleColorLimits;
            obj.PrivateScaleColorLimitsMode = 'manual';
            
            obj.markPropertiesDirty({'ScaleColorLimits'});
        end
        
        function colorLimits = get.ScaleColorLimits(obj)
            colorLimits = obj.PrivateScaleColorLimits;
        end
    end
    
    % ---------------------------------------------------------------------
    % Scale Color Limits generating functions
    % ---------------------------------------------------------------------
    methods(Access = 'private')
        
        function updateScaleColorLimits(obj)
            % Generates ScaleColorLimits
            
            if(~strcmp(obj.PrivateScaleColorLimitsMode, 'auto'))
                return;
            end
            
            % Ex: 3 colors
            numberOfColors = size(obj.PrivateScaleColors, 1);
            
            % Special check for no colors
            %
            % Otherwise, the code below generates a: Empty matrix: 0-by-2
            % instead of []
            if(numberOfColors == 0)
                obj.PrivateScaleColorLimits = [];
                return;
            end
            
            % Ex: If limits were [0 30], then interval is 10
            interval = (obj.Limits(2) - obj.Limits(1)) / numberOfColors;
            
            % Ex: Start Points would be [0 10 20]
            startPoints = obj.Limits(1) : interval : obj.Limits(2) - interval;
            
            % Ex: End Points would be [10 20 30]
            endPoints = obj.Limits(1) + interval : interval : obj.Limits(2);
            
            % Ex: Create limits by turning into columns and combining
            %
            % [  0  10
            %   10  20
            %   20  30 ]
            obj.PrivateScaleColorLimits = [startPoints' endPoints'];
        end
        
    end
    
    methods(Access = 'protected')
        
        function updatedProperties = updatePropertiesAfterLimitsChange(obj)
            %Update the Scale Color Limits
            obj.updateScaleColorLimits();
            updatedProperties = {'ScaleColorLimits'};
        end
        
        function [scaleColors, scaleColorLimits] = getScaleColorForDisplay(obj)
            % The properties ScaleColors and ScaleColorLimits might not be
            % of the same number of rows.
            % For the custom display, we need both arrays to have the same
            % number of rows. If one array has more rows than the other, the
            % additional rows are discarded for display purpose.
            % This function returns both arrays, truncated if necessary.
            
            scaleColors = obj.ScaleColors;
            scaleColorLimits = obj.ScaleColorLimits;
            
            nScaleColors = size(scaleColors,1);
            nScaleColorLimits = size(scaleColorLimits,1);
            
            if (nScaleColors > nScaleColorLimits)
                scaleColors = obj.ScaleColors(1: nScaleColorLimits, :);
            elseif (nScaleColorLimits > nScaleColors)
                scaleColorLimits = obj.ScaleColorLimits(1: nScaleColors, :);
            end
            
        end
    end
end
