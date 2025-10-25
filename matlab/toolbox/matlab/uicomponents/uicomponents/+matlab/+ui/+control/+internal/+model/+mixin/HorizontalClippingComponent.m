classdef (Hidden) HorizontalClippingComponent < appdesservices.internal.interfaces.model.AbstractModelMixin
    % This undocumented class may be removed in a future release.
    
    % This is a mixin parent class for all visual components that have an
    % 'HorizontalClipping' property
    %
    % This class provides all implementation and storage for
    % 'HorizontalClipping'
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties(Hidden, Dependent)
        HorizontalClipping = 'right';
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
        
        PrivateHorizontalClipping = 'right';
    end
      
    
    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        function set.HorizontalClipping(obj, newValue)
            % Error Checking
            try
                newHorizontalClipping = matlab.ui.control.internal.model.PropertyHandling.processEnumeratedString(...
                    obj, ...
                    newValue, ...
                    {'left', 'right'});
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidTwoStringEnum', ...
                    'HorizontalClipping', 'left', 'right');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidHorizontalClipping';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception 
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            % Property Setting
            obj.PrivateHorizontalClipping = newHorizontalClipping;
            
            % Update View
            markPropertiesDirty(obj, {'HorizontalClipping'});
        end
        
        function value = get.HorizontalClipping(obj)
            value = obj.PrivateHorizontalClipping;
        end
    end
end