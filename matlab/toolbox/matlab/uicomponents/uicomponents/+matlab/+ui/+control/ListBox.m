classdef (Sealed, ConstructOnLoad=true) ListBox < ...
        matlab.ui.control.internal.model.AbstractStateComponent & ...
        matlab.ui.control.internal.model.mixin.FontStyledComponent & ...
        matlab.ui.control.internal.model.mixin.BackgroundColorableComponent & ...
        matlab.ui.control.internal.model.mixin.PositionableComponent & ...
        matlab.ui.control.internal.model.mixin.Layoutable & ...
        matlab.ui.control.internal.model.mixin.StyleableComponent & ...
        matlab.ui.control.internal.model.mixin.FocusableComponent & ...
        matlab.ui.control.internal.model.mixin.ClickableComponent & ...
        matlab.ui.control.internal.model.mixin.DoubleClickableComponent
    %
    
    % Do not remove above white space
    % Copyright 2014-2023 The MathWorks, Inc.
    
    properties(Dependent, AbortSet)
        % When set to 'on', the user can select multiple entries
        Multiselect matlab.internal.datatype.matlab.graphics.datatype.on_off = 'off';
    end        
    
    properties(Access = 'private')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set
        
        PrivateMultiselect matlab.internal.datatype.matlab.graphics.datatype.on_off = 'off';
    end
    
    properties(Access = {?matlab.ui.control.internal.controller.ListBoxController})
        
        % Stored index to scroll.  This value is used to store scroll index 
        % if user calls scroll method before view is ready. 
       InitialIndexToScroll = []; 
    end

    properties (Transient, Access = {?appdesservices.internal.interfaces.model.AbstractModelMixin})
        TargetEnums = ["listbox", "item"];
        TargetDefault = "listbox";
    end
    
    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = ListBox(varargin)
            %
            
            % Do not remove above white space
            % List states can be between [0, Inf]
            sizeConstraints = [0, Inf];
            obj = obj@matlab.ui.control.internal.model.AbstractStateComponent(sizeConstraints);

            defaultSize = [100, 74];
            obj.PrivateOuterPosition(3:4) = defaultSize;
            obj.PrivateInnerPosition(3:4) = defaultSize;
            
            % Initialize the selection strategy
            obj.updateSelectionStrategy();
            
            % ListBox has specific default values for properties
            obj.PrivateItems = {  getString(message('MATLAB:ui:defaults:item1State')), ...
                getString(message('MATLAB:ui:defaults:item2State')), ...
                getString(message('MATLAB:ui:defaults:item3State')), ...
                getString(message('MATLAB:ui:defaults:item4State')) };
            
            obj.PrivateSelectedIndex = 1;
            
            obj.Type = 'uilistbox';
            
            obj.attachCallbackToEvent('Clicked', 'PrivateClickedFcn');
            obj.attachCallbackToEvent('DoubleClicked', 'PrivateDoubleClickedFcn');

            parsePVPairs(obj,  varargin{:});
            
        end
    end
    
    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        
        function set.Multiselect(obj, newMultiselect)
            % Since this setting directly affects the Value,
            % and the current Value may violate this constraint, we update
            % the Value silently instead of the throwing an error message
            % which would have asked the user to change Value before updating this
            % property.
            % Eg:
            % Lets say, the Value were currently {'Item 1', 'Item 2'}
            % Now, the user sets Multiselect to false
            % The code below updates value to be the first item from cell
            % array above. So it will become a scalar like so: 'Item 1'
            
            % Error Checking done through the datatype specification
            
            % Property Setting
            obj.PrivateMultiselect = newMultiselect;
            
            % Update selection strategy
            obj.updateSelectionStrategy();
            
            % Update selected index based on this new Selection Strategy            
            obj.SelectionStrategy.calibrateSelectedIndexAfterSelectionStrategyChange();
            
            % marking dirty to update view
            obj.markPropertiesDirty({'Multiselect', 'SelectedIndex', 'Value'});
        end
        
        function value = get.Multiselect(obj)
            value = obj.PrivateMultiselect;
        end                
        
        function scroll(obj, scrollTarget)
            % SCROLL - Scroll to location within list box
            %
            %   SCROLL(component,location) scrolls list box to the specified
            %   location within a listbox. The location can be 'top',
            %   'bottom' or an entry in Items or ItemsData.
            %
            %   See also UILISTBOX
    

            narginchk(2, 2);
            scrollTarget = convertStringsToChars(scrollTarget);
            
            % Scroll target will be matched with ItemsData first, then
            % Items.  Find will return the first value that matches.
            targetIndex = obj.ValueStrategy.getIndexGivenValue(scrollTarget);
            
            % If ItemsData exists, ValueStrategy will not check Items.  
            % Check if scrollTarget is in Items
            if ~isempty(obj.ItemsData) && isempty(targetIndex)
                targetIndex = find(cellfun(@(items) isequal(scrollTarget, items), obj.Items), 1);
            end
            
            % For top and bottom, replace target with numeric index
            matchesKeyword = strcmpi(scrollTarget, {'top', 'bottom'});
            if ischar(scrollTarget) && any(matchesKeyword)
                if isempty(targetIndex) || targetIndex == -1
                    lowIndex = 1;
                    maxIndex = numel(obj.Items);

                    if maxIndex < 1
                        % Items property was empty; abort scroll without error
                        return;
                    else
                        % targets are top or bottom
                        keywordTargets = [lowIndex, maxIndex];
                        targetIndex = keywordTargets(matchesKeyword);
                    end
                end
            end

            % Do error checking and throw error if necessary
            if isempty(targetIndex) || targetIndex == -1 
                % throw error
                messageObj =  message('MATLAB:ui:components:invalidScrollTarget');
                
                % Use string from object
                messageText = getString(messageObj);

                error('MATLAB:ui:ListBox:invalidScrollTarget', messageText);
            end

            if isempty(obj.Controller)
                % If the view has not been created, store the targetIndex
                % for use when the view is created.
                obj.InitialIndexToScroll = targetIndex;
            else
                % g1894176 - scroll was not working for the listbox if the following actions were performed back to back
                % 1) append (add to end) an item to the listbox with a vertical scrollbar
                % 2) scroll to the bottom of the listbox 
                % This is because, the item property of the listbox widget is not yet updated with the new item
                % to which a scroll is attempted. Hence, a call to flushDirtyProperties() is made to update the items property
                % as scroll depends on it.
                obj.flushDirtyProperties(); 
                % Forward scroll to view
                obj.Controller.scroll(targetIndex);
            end
        end
    end
    
    methods(Access = private)
        
        % Update the Selection Strategy property
        function updateSelectionStrategy(obj)           
            if(strcmp(obj.PrivateMultiselect, 'on'))
                obj.SelectionStrategy = matlab.ui.control.internal.model.ZeroToManySelectionStrategy(obj);
            else
                obj.SelectionStrategy = matlab.ui.control.internal.model.ZeroToOneSelectionStrategy(obj);
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
            
            names = {...
                'Value',...
                'Items',...
                'ItemsData',...
                'Multiselect',...
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

           % sObj is the serialization content that was saved for obj 
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj);
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.BackgroundColorableComponent(sObj);
        end 

    end
end

