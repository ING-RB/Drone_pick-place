classdef (Sealed, ConstructOnLoad=true) ColorPicker < ...
        matlab.ui.control.internal.model.ComponentModel & ...
        matlab.ui.control.internal.model.mixin.IconableComponent & ...
        matlab.ui.control.internal.model.mixin.PositionableComponent & ...
        matlab.ui.control.internal.model.mixin.EnableableComponent & ...
        matlab.ui.control.internal.model.mixin.VisibleComponent & ...
        matlab.ui.control.internal.model.mixin.TooltipComponent  & ...
        matlab.ui.control.internal.model.mixin.Layoutable & ...
        matlab.ui.control.internal.model.mixin.ButtonBackgroundColorableComponent & ...
        matlab.ui.control.internal.model.mixin.FocusableComponent
    %

    % Do not remove above white space
    % Copyright 2023 The MathWorks, Inc.

    properties(Dependent, AbortSet)
		Value matlab.internal.datatype.matlab.graphics.datatype.RGBColor = [1 0 0];
	end
	
	properties(NonCopyable, Dependent, AbortSet)
		ValueChangedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end
    
    properties(Access = {?appdesservices.internal.interfaces.model.AbstractModel})
		PrivateValue matlab.internal.datatype.matlab.graphics.datatype.RGBColor = [1 0 0];
    end
    
    properties(NonCopyable, Access = 'private')
        PrivateValueChangedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end
    
    events(NotifyAccess = {?appdesservices.internal.interfaces.model.AbstractModel})        
        ValueChanged;
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = ColorPicker(varargin)
            %
            
            % Do not remove above white space
            % Override the default values
            
            obj.Type = 'uicolorpicker';
            
            % Initialize Layout Properties
            defaultSize = [38, 22];
            obj.PrivateInnerPosition(3:4) = defaultSize;
            obj.PrivateOuterPosition(3:4) = defaultSize;

            % Specify allowed predefined icons
            obj.AllowedPresets = matlab.ui.internal.IconUtils.ColorPickerIcon;
            
            parsePVPairs(obj,  varargin{:});
            
            % Wire callbacks
            obj.attachCallbackToEvent('ValueChanged', 'PrivateValueChangedFcn');
        end
        
        function set.Value (obj, val)
            obj.PrivateValue = val;
            obj.markPropertiesDirty({'Value'});
        end
        
        function value = get.Value(obj)
            value = obj.PrivateValue;
        end
     
        function set.ValueChangedFcn(obj, newValueChangedFcn)
			% Property Setting
			obj.PrivateValueChangedFcn = newValueChangedFcn;
			obj.markPropertiesDirty({'ValueChangedFcn'});
		end
		
		function value = get.ValueChangedFcn(obj)
			value = obj.PrivateValueChangedFcn;
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
            
            names = {'Value',...
                'Icon',...
                'ValueChangedFcn',...
                };
        end
        
        function str = getComponentDescriptiveLabel(obj)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            
            str = mat2str(round(obj.Value,4));
        end

    end
    
    methods(Access='public', Static=true, Hidden=true)
        function varargout = doloadobj(hObj)
            % DOLOADOBJ - Graphics framework feature for loading graphics
            % objects

            % on component loading, property set will not trigger marking
            % dirty, so disable view property cache
            % Todo: enable it when we have a better design for loading
            % Todo: need a better way to disable cache instead of in invidudal
            % subclass
            hObj.disableCache();

            hObj = doloadobj@matlab.ui.control.internal.model.mixin.IconableComponent(hObj);
            varargout{1} = hObj;
        end
    end

    methods (Hidden, Static)
        function modifyOutgoingSerializationContent(sObj, obj)
            % sObj is the serialization content for obj
            modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.ButtonBackgroundColorableComponent(sObj, obj);
        end

        function modifyIncomingSerializationContent(sObj)
            % sObj is the serialization content that was saved for obj
            modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.ButtonBackgroundColorableComponent(sObj);
        end
    end
end
