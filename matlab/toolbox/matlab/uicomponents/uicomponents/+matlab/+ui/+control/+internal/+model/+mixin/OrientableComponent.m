classdef (Hidden) OrientableComponent < appdesservices.internal.interfaces.model.AbstractModelMixin
    % This undocumented class may be removed in a future release.

    % Copyright 2021 The MathWorks, Inc.

    % This is a mixin parent class for all visual components that have the
    % 'Orientation' property.
    properties(Dependent, AbortSet)
        Orientation
    end
    
    properties(Access= {
            ?appdesservices.internal.interfaces.model.AbstractModel, ...
            ?appdesservices.internal.interfaces.model.AbstractModelMixin})
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, beacuse sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set
        
        PrivateOrientation
        
    end

    % Subclasses must override these properties to implement
    % - the orientation values this component will accept (e.g. north/south/east/west or horizontal/vertical)
    % - the exception message that will be shown when the orientation is invalid.
    properties (Abstract, Access = protected, Constant)
        ValidOrientations cell % Cellstr of valid orientations this component will accept
    end
    
    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        function set.Orientation(obj, orientation)
            
            oldOrientation = obj.Orientation;
            
            % Error Checking
            try
                newOrientation = matlab.ui.control.internal.model.PropertyHandling.processEnumeratedString(...
                    obj, ...
                    orientation, ...
                    obj.ValidOrientations);
            catch ME
                messageObj = obj.getExceptionMessage();
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidOrientation';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            % Property Setting
            obj.PrivateOrientation = newOrientation;
            
            % properties to mark dirty
            commonDirtyProperties = {'Orientation'};
            
            % Additional updates like Value or ScaleColorLimits
            additionalDirtyProperties = obj.updatePropertiesAfterOrientationChanges(oldOrientation, newOrientation);
            
            % combine list properties
            combinedProperties = [additionalDirtyProperties,commonDirtyProperties];

            obj.markPropertiesDirty(combinedProperties);
        end
        
        function orientation = get.Orientation(obj)
            orientation = obj.PrivateOrientation;
        end
    end
    
    methods (Abstract, Access = protected)
        
        % Hook to make any additional updates and mark additional
        % properties dirty.  Subclasses that mix in PositionableComponent
        % should call 'updatePositionPropertiesAfterOrientationChange'
        % from this method.
        dirtyProperties = updatePropertiesAfterOrientationChanges(obj, oldOrientation, newOrientation)
    end

    methods (Access = private)
        function exceptionMessage = getExceptionMessage(obj)
            enumValuesList = sprintf('''%s''', strjoin(obj.ValidOrientations(1:end-1), ''', '''));
            lastValue = sprintf('''%s''', obj.ValidOrientations{end});

            if length(obj.ValidOrientations) > 2
                % add Oxford comma to the list of enum values
                enumValuesList = [enumValuesList ','];
            end

            exceptionMessage = message('MATLAB:ui:components:invalidManyStringEnum', ...
                    'Orientation', enumValuesList, lastValue);
        end
    end
end