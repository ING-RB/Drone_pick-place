classdef (Hidden) AbstractBinaryComponent < ...
        matlab.ui.control.internal.model.ComponentModel & ...
        matlab.ui.control.internal.model.mixin.VisibleComponent & ...
        matlab.ui.control.internal.model.mixin.TooltipComponent
    %

    % Copyright 2014-2021 The MathWorks, Inc.
    
    properties(Dependent, AbortSet)
        Value = false;
    end
    
    properties(NonCopyable, Dependent, AbortSet)
        ValueChangedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end
    
    properties(Access = {?appdesservices.internal.interfaces.model.AbstractModel, ...
            ?appdesservices.internal.interfaces.controller.AbstractController})
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set
        
        PrivateValue = false;
    end 
    
    properties(NonCopyable, Access = 'protected')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set
        
        PrivateValueChangedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end
    
    events(NotifyAccess = {?appdesservices.internal.interfaces.model.AbstractModel})
        ValueChanged
    end
    
    
    methods
        
        % -----------------------------------------------------------------
        % Constructor
        % ---------------------------------------------------------------------
        function obj = AbstractBinaryComponent(varargin)
            % call super            
            obj@matlab.ui.control.internal.model.ComponentModel(varargin{:});                        
            
            % Wire callbacks
            obj.attachCallbackToEvent('ValueChanged', 'PrivateValueChangedFcn');	             
        end
        
        
        % -----------------------------------------------------------------
        % Property Getters / Setters
        % -----------------------------------------------------------------
        function set.Value(obj, newValue)
            % Error Checking
            try
                newValue = matlab.ui.control.internal.model.PropertyHandling.validateLogicalScalar(newValue);
                
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidBooleanProperty', ...
                    'Value');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidSelected';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            % Property Setting
            obj.PrivateValue = newValue;
            
            % Update View
            markPropertiesDirty(obj, {'Value'});
        end
        
        function value = get.Value(obj)
            value = obj.PrivateValue;
        end
        
        % ---------------------------------------------------------------------
        function set.ValueChangedFcn(obj, newValueChangedFcn)
            % Property Setting
            obj.PrivateValueChangedFcn = newValueChangedFcn;
            
            obj.markPropertiesDirty({'ValueChangedFcn'});
        end
        
        function value = get.ValueChangedFcn(obj)
            value = obj.PrivateValueChangedFcn;
        end
        
    end
    
end
