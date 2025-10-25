classdef (Sealed, ConstructOnLoad=true) DropDown < ...
        matlab.ui.control.internal.model.AbstractStateComponent & ...                
        matlab.ui.control.internal.model.mixin.FontStyledComponent & ...
        matlab.ui.control.internal.model.mixin.BackgroundColorableComponent & ...
        matlab.ui.control.internal.model.mixin.PositionableComponent & ...
        matlab.ui.control.internal.model.mixin.PlaceholderComponent & ...
        matlab.ui.control.internal.model.mixin.Layoutable & ...
        matlab.ui.control.internal.model.mixin.StyleableComponent & ...
        matlab.ui.control.internal.model.mixin.FocusableComponent & ...
        matlab.ui.control.internal.model.mixin.ClickableComponent
    %
    
    % Do not remove above white space
    % Copyright 2013-2024 The MathWorks, Inc.
    
    properties(Dependent, AbortSet)
        % When true, the user can type in a string in addition to selecting
        % an item from the list. 
        % This property allows switching between the regular drop down and
        % the combo box.
        Editable matlab.internal.datatype.matlab.graphics.datatype.on_off = 'off';
    end        
    
    properties(Access = 'private')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set
        
        PrivateEditable matlab.internal.datatype.matlab.graphics.datatype.on_off = 'off';
    end
    
    
    properties(NonCopyable, Dependent, AbortSet)
		DropDownOpeningFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end
    
    events(NotifyAccess = {?appdesservices.internal.interfaces.model.AbstractModel})        
        DropDownOpening
    end
    
    properties(NonCopyable, Access = {...
			?matlab.ui.control.internal.model.AbstractStateComponent, ...
			?matlab.ui.control.internal.model.StateComponentSelectionStrategy,...
			?matlab.ui.control.internal.model.StateComponentValueStrategy,...
			?appdesservices.internal.interfaces.controller.AbstractController})
		
		PrivateDropDownOpeningFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
        		
    end

    properties (Transient, Access = {?appdesservices.internal.interfaces.model.AbstractModelMixin})
        TargetEnums = ["dropdown", "item"];
        TargetDefault = "dropdown";
    end
    
    
    
    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = DropDown(varargin)                       
            %
            
            % Do not remove above white space
            % Drop Down states can be between [0, Inf]
            sizeConstraints = [0, Inf];
            
            obj = obj@matlab.ui.control.internal.model.AbstractStateComponent(...
                sizeConstraints);
            
            defaultSize = [100, 22];
            obj.PrivateOuterPosition(3:4) = defaultSize;
            obj.PrivateInnerPosition(3:4) = defaultSize;
            
            if strcmp(obj.Editable, 'off')
                % Set default BackgroundColor
                obj.BackgroundColor_I = obj.DefaultGray;
            end
            
            % Initialize the selection strategy
            obj.updateSelectionStrategy();
            
            % ComboBox has specific default values for properties
            obj.PrivateItems = {  getString(message('MATLAB:ui:defaults:option1State')), ... 
                            getString(message('MATLAB:ui:defaults:option2State')), ... 
                            getString(message('MATLAB:ui:defaults:option3State')), ... 
                            getString(message('MATLAB:ui:defaults:option4State')) }; 
            
            obj.PrivateSelectedIndex = 1;

            obj.Type = 'uidropdown';
            
            parsePVPairs(obj,  varargin{:});
            
            obj.attachCallbackToEvent('DropDownOpening', 'PrivateDropDownOpeningFcn');
            obj.attachCallbackToEvent('Clicked', 'PrivateClickedFcn');

        end
    end
    
    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        
        function set.Editable(obj, newValue)
            
            % Error Checking done through the datatype specification
            
            % If the user has not updated the color, change the color to
            % the factory default when toggling the Editable property.
            % Also apply a theme mapping if the component is in a themed
            % Figure.
            tc = ancestor(obj,'matlab.graphics.mixin.ThemeContainer');
            isThemed = ~isempty(tc) && ~isempty(tc.Theme);
            if strcmp(newValue, 'on') && strcmp(obj.PrivateEditable, 'off')...
                    && isequal(obj.BackgroundColorMode, 'auto')
                obj.BackgroundColor_I = obj.DefaultWhite;
                if isThemed || isempty(tc)
                    % In the Editable case, also apply the mapping if the
                    % parent is empty to assure that toggling Editable "on"
                    % in the constructor has the appropriate affect in
                    % themed cases.
                    mapping = "--mw-backgroundColor-input";
                    matlab.graphics.internal.themes.specifyThemePropertyMappings(...
                        obj,'BackgroundColor',mapping);
                end
            elseif strcmp(newValue, 'off') && strcmp(obj.PrivateEditable, 'on')...
                    && isequal(obj.BackgroundColorMode, 'auto')
                obj.BackgroundColor_I = obj.DefaultGray;
                if isThemed
                    mapping = "remove"; % when mapping is removed, the semantic variable from getThemeMap will be used instead
                    matlab.graphics.internal.themes.specifyThemePropertyMappings(...
                        obj,'BackgroundColor',mapping);
                end
            end

            % Property Setting
            obj.PrivateEditable = newValue;
            
            % Update selection strategy
            obj.updateSelectionStrategy();
            
            % Update selected index based on this new Selection Strategy            
            obj.SelectionStrategy.calibrateSelectedIndexAfterSelectionStrategyChange();            
            
            % marking dirty to update view
            obj.markPropertiesDirty({'Editable', 'SelectedIndex'});
        end
        
        function value = get.Editable(obj)
            value = obj.PrivateEditable;
        end
        
        
        function set.DropDownOpeningFcn(obj, newDropDownOpeningFcn)
			% Property Setting
			obj.PrivateDropDownOpeningFcn = newDropDownOpeningFcn;
			obj.markPropertiesDirty({'DropDownOpeningFcn'});
		end
		
		function value = get.DropDownOpeningFcn(obj)
			value = obj.PrivateDropDownOpeningFcn;
		end
    end
    
    methods(Access = private)
        
        % Update the Selection Strategy property
        function updateSelectionStrategy(obj)
            if(strcmp(obj.PrivateEditable, 'on'))
                obj.SelectionStrategy = matlab.ui.control.internal.model.EditableSelectionStrategy(obj);
            else
                obj.SelectionStrategy = matlab.ui.control.internal.model.ExactlyOneSelectionStrategy(obj);
            end
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
                'Value',...
                'Items',...
                'ItemsData',...
                'Editable',...
                ...Callbacks
                'ValueChangedFcn'};
                
        end
        
        function str = getComponentDescriptiveLabel(obj)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.

            % Return the text of the selected item
            % Note that this is the same as Value when ItemsData is empty
            index = obj.SelectedIndex;
            str = obj.SelectionStrategy.getSelectedTextGivenIndex(index); 

        end
    end

    % ---------------------------------------------------------------------
    % Theme Method Overrides
    % ---------------------------------------------------------------------
    methods (Static, Access='protected')
        function map = getThemeMap
            % GETTHEMEMAP - This method returns a struct describing the 
            % relationship between class properties and theme attributes.
            
            %             DropDown Prop      Theme Attribute
            map = struct('BackgroundColor', '--mw-backgroundColor-primary',...
                         'FontColor',       '--mw-color-primary');
        end
    end

    % ---------------------------------------------------------------------
    % StyleableComponent Method Overrides
    % ---------------------------------------------------------------------
    methods (Access='protected')
        % STYLEABLE Methods
        function index = validateStyleIndex(obj, target, index)
            if strcmpi(target, 'item') || ...
                    (iscategorical(target) && target == "item")

                if isValidItem(obj, index)
                    % Ensure index is a row vector
                    index = reshape(index, 1, []);
                else
                    messageObject = message('MATLAB:ui:style:invalidItemTargetIndex', ...
                        target);
                    % MnemonicField is last section of error id
                    mnemonicField = 'invalidItemTargetIndex';

                    % Use string from object
                    messageText = getString(messageObject);

                    % Create and throw exception
                    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                    throwAsCaller(exceptionObject);
                end
            end
        end
    end

    methods (Access = private)
        function isValid = isValidItem(~, idx)
            % An 'item' is valid if it is a scalar or array of positive integers
            try
                validateattributes(idx,{'numeric'},{'positive','integer','real','finite','vector'});
                isValid = true;
            catch
                isValid = false;
            end
        end
    end
    methods (Hidden, Static) 
        function modifyOutgoingSerializationContent(sObj, obj) 

           % sObj is the serialization content for obj 
           modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj, obj);
           modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.BackgroundColorableComponent(sObj, obj);
        end
        function modifyIncomingSerializationContent(sObj)               
            if ~sObj.hasNameValue('BackgroundColorMode') && sObj.hasNameValue('PrivateEditable')
                % BackgroundColorableComponent handles the non-editable
                % case so check for the non-editable case here
                if isequal(sObj.getValue('PrivateEditable'), 'off') ...
                    color = matlab.ui.control.internal.model.mixin.BackgroundColorableComponent.DefaultGray;
                else
                    color = matlab.ui.control.internal.model.mixin.BackgroundColorableComponent.DefaultWhite;
                end
                if ~sObj.hasNameValue('BackgroundColor')
                    sObj.addNameValue('BackgroundColor',color);
                end
                if isequal(sObj.getValue('BackgroundColor'), color)
                    sObj.addNameValue('BackgroundColorMode','auto');
                end
            end
           % sObj is the serialization content that was saved for obj 
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj);
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.BackgroundColorableComponent(sObj);
        end 

    end
end
