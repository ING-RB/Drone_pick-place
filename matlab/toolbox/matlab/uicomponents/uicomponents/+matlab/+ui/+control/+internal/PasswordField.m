classdef (Sealed, Hidden, ConstructOnLoad=true) PasswordField < ...        
        matlab.ui.control.internal.model.ComponentModel & ...        
        matlab.ui.control.internal.model.mixin.FontStyledComponent & ...
        matlab.ui.control.internal.model.mixin.BackgroundColorableComponent & ...
        matlab.ui.control.internal.model.mixin.PositionableComponent & ...
        matlab.ui.control.internal.model.mixin.EnableableComponent & ...
        matlab.ui.control.internal.model.mixin.VisibleComponent & ...
        matlab.ui.control.internal.model.mixin.TooltipComponent & ...
        matlab.ui.control.internal.model.mixin.PlaceholderComponent & ...
        matlab.ui.control.internal.model.mixin.Layoutable & ...     
        matlab.ui.control.internal.model.mixin.FocusableComponent
    %

    % Do not remove above white space
    % Copyright 2020-2023 The MathWorks, Inc.
    
    % TODO: Help text
    
    properties(NonCopyable, Dependent, AbortSet)
        PasswordEnteredFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end

    properties(NonCopyable, Transient, ...
            Access = {?matlab.ui.control.internal.controller.PasswordFieldController})
        ChannelID
    end
    
    properties(NonCopyable, Access = 'private')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set        
        
        PrivatePasswordEnteredFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end

    properties(AbortSet)
        EnablePlainTextControl matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState.off;
    end
    
    events(NotifyAccess = {?appdesservices.internal.interfaces.model.AbstractModel})        
        PasswordEntered
    end
    
    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = PasswordField(varargin)
            %

            % Do not remove above white space
            % Defaults
            defaultSize = [100, 22];
			obj.PrivateInnerPosition(3:4) = defaultSize;
			obj.PrivateOuterPosition(3:4) = defaultSize;
            obj.Type = 'uipasswordfield';
            
            parsePVPairs(obj,  varargin{:});
            
            % Wire callbacks
            obj.attachCallbackToEvent('PasswordEntered', 'PrivatePasswordEnteredFcn');
        end
        % ----------------------------------------------------------------------
        
        function set.PasswordEnteredFcn(obj, newValue)
            % Property Setting            
            obj.PrivatePasswordEnteredFcn = newValue;
            
            % Dirty
            obj.markPropertiesDirty({'PasswordEnteredFcn'});
        end
        
        
        function value = get.PasswordEnteredFcn(obj)
            value = obj.PrivatePasswordEnteredFcn;
        end

        function set.EnablePlainTextControl(obj, newValue)
            obj.EnablePlainTextControl = newValue;

            markPropertiesDirty(obj, {'EnablePlainTextControl'});
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
            
            names = {
                'EnablePlainTextControl',...
                'PasswordEnteredFcn'
            }; 
        end
        
        function str = getComponentDescriptiveLabel(obj)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            str = obj.Type;
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
