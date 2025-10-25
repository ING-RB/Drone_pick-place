classdef (Hidden) TooltipWithModeComponent < appdesservices.internal.interfaces.model.AbstractModelMixin
    % This undocumented class may be removed in a future release.
    %
    % This is a mixin parent class for all visual components that have an
    % 'Tooltip' property that has an associated 'TooltipMode' property
    %
    % This class provides all implementation and storage for 'Tooltip' and
    % 'TooltipMode'
    
    % Copyright 2021 The MathWorks, Inc.
    
    properties(Dependent)
        Tooltip = '';
    end

    properties(Hidden, Dependent)
        TooltipMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
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
        PrivateTooltipMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
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

            % Update TooltipMode to manual
            obj.TooltipMode = 'manual';
        end
        
        function value = get.Tooltip(obj)
            value = obj.PrivateTooltip;
        end
        % ----------------------------------------------------------------------
        function set.TooltipMode(obj, newValue)
            
            % Property Setting
            obj.PrivateTooltipMode = newValue;
            
            markPropertiesDirty(obj, {'TooltipMode'});
        end
        % ----------------------------------------------------------------------
        function formatMode = get.TooltipMode(obj)
            formatMode = obj.PrivateTooltipMode;
        end
        
    end
end
