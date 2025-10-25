classdef (Hidden) TooltipComponent < appdesservices.internal.interfaces.model.AbstractModelMixin
    % This undocumented class may be removed in a future release.
    
    % This is a mixin parent class for all visual components that have an
    % 'Tooltip' property
    %
    % This class provides all implementation and storage for 'Tooltip'
    
    % Copyright 2014-2021 The MathWorks, Inc.
    
    properties(Dependent, AbortSet)
        Tooltip = '';
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
        
        PrivateTooltip = '';
    end
    
    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        function set.Tooltip(obj, newValue)
            % Error Checking
            try
                newValue = matlab.ui.control.internal.model.PropertyHandling.validateMultilineText(newValue);
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidMultilineTextValue', ...
                    'Tooltip');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidTooltip';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throwAsCaller(exceptionObject);
                
            end
            
            % Property Setting
            obj.PrivateTooltip = newValue;
            
            % Update View
            markPropertiesDirty(obj, {'Tooltip'});
        end
        
        function value = get.Tooltip(obj)
            value = obj.PrivateTooltip;
        end
    end
end
