classdef (Hidden) AltTextComponent < appdesservices.internal.interfaces.model.AbstractModelMixin
    % This undocumented class may be removed in a future release.
    
    % This is a mixin parent class for all visual components that support
    % alt (alt) text to be read by a screen reader.
    %
    % This class provides all implementation and storage for 'AltText'
    
    % Copyright 2022 The MathWorks, Inc.
    
    properties (Dependent, AbortSet)
        %AltText - Web page address or file location to open in new browser when hyperlink is clicked
        AltText = '';
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

        PrivateAltText = '';
    end            
    
    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        function set.AltText(obj, newValue)
            % Error Checking
            try
                newValue = matlab.ui.control.internal.model.PropertyHandling.validateText(newValue);
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidTextValue', ...
                    'AltText');

                % MnemonicField is last section of error id
                mnemonicField = 'invalidAltText';
                
                % Use string from object
                messageText = getString(messageObj);

                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throwAsCaller(exceptionObject);

            end
            
            % Property Setting
            obj.PrivateAltText = newValue;
            
            % Update View
            markPropertiesDirty(obj, {'AltText'});
        end
        
        function value = get.AltText(obj)
            value = obj.PrivateAltText;
        end
    end
end