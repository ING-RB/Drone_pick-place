classdef (Hidden) PlaceholderComponent < appdesservices.internal.interfaces.model.AbstractModelMixin
    % This undocumented class may be removed in a future release.
    
    % This is a mixin parent class for all visual components that have a
    % 'Placeholder' property which supports text wrapping.
    %
    % This class provides all implementation and storage for 'Placeholder'
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties(Dependent, AbortSet)
        Placeholder = '';
    end
    
    properties(Access = 'private')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control for each property
        %
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set
        
        PrivatePlaceholder = '';
    end
            
    
    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        function set.Placeholder(obj, newValue)
            % Error Checking
            try
                newValue = matlab.ui.control.internal.model.PropertyHandling.validateText(newValue);
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidTextValue', ...
                    'Placeholder');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidPlaceholder';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            % Property Setting
            obj.PrivatePlaceholder = newValue;
            
            % Update View
            markPropertiesDirty(obj, {'Placeholder'});
        end
        
        function value = get.Placeholder(obj)
            value = obj.PrivatePlaceholder;
        end
    end
end
