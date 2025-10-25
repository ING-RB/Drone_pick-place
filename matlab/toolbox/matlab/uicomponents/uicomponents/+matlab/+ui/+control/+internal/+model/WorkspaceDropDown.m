classdef (Sealed, ConstructOnLoad=true) WorkspaceDropDown < ...
        matlab.ui.control.internal.model.AbstractStateComponent & ...
        matlab.ui.control.internal.model.mixin.FontStyledComponent & ...
        matlab.ui.control.internal.model.mixin.BackgroundColorableComponent & ...
        matlab.ui.control.internal.model.mixin.PositionableComponent & ...
        matlab.ui.control.internal.model.mixin.StyleableComponent & ...
        matlab.ui.control.internal.model.mixin.Layoutable & ...
        matlab.ui.control.internal.model.mixin.ClickableComponent
    %

    % Do not remove above white space
    % Copyright 2018-2024 The MathWorks, Inc.

    properties(Dependent)
        % When true, the user can type in a string in addition to selecting
        % an item from the list.
        % This property allows switching between the regular drop down and
        % the combo box.
        Editable matlab.internal.datatype.matlab.graphics.datatype.on_off = 'off';

        % This property returns the current value of the selected variable
        % from the base workspace
        WorkspaceValue = [];

        % This is an optional callback function that if specified will be
        % called when the dropdown opens, giving the author an opportunity
        % to filter the variables that are presented to the user. This
        % should be a function handle to a function that given a workspace
        % variable returns true if that variable should be shown in the
        % dropdown or false otherwise.
        FilterVariablesFcn = [];

        % This controls whether the placeholder item says "select" or
        % "default". In certain use cases the author may opt-in to show
        % "default" instead of "select" by setting this property to true
        % during construction.
        UseDefaultAsPlaceholder = false;

        % Controls whether to allow a non-existent variable to be set as the
        % Value of the dropdown. This can be useful in Live Tasks, for example,
        % where a variable may not exist when the task is reopened.
        ShowNonExistentVariable (1,1) logical = false;
    end

    properties
        % This controls what workspace variables will be populated from
        Workspace = "base";
    end

    properties(Hidden)
        % If ShowNonExistentVariable is set to true, this contains the variable
        % name value which is selected in the dropdown, even if it doesn't exist
        % in the workspace.  (Not setting a size so we can assign strings(0)
        % which is size [0,0]).
        NonExistentVariableName string {mustBeScalarOrEmpty} = strings(0);
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

        PrivateFilterVariablesFcn = [];
        PrivateUseDefaultAsPlaceholder = false;
        PrivateShowNonExistentVariable (1,1) logical = false;
    end

    properties(Access = private, Constant)
        DEFAULT_VALUE = 'default value';
        SELECT_VARIABLE = 'select variable';
        DEFAULT_VALUE_TEXT = getString(message('MATLAB:ui:defaults:default'));
        SELECT_VARIABLE_TEXT = getString(message('MATLAB:ui:defaults:select'));
    end

    properties (Transient, Access = {?appdesservices.internal.interfaces.model.AbstractModelMixin})
        TargetEnums = ["dropdown", "item"];
        TargetDefault = "dropdown";
    end

    events(NotifyAccess = {?appdesservices.internal.interfaces.model.AbstractModel})
        DropDownOpening
    end


    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = WorkspaceDropDown(varargin)
            %

            % Do not remove above white space
            % Drop Down states can be between [0, Inf]
            sizeConstraints = [0, Inf];

            obj = obj@matlab.ui.control.internal.model.AbstractStateComponent(...
                sizeConstraints);

            defaultSize = [100, 22];
            obj.PrivateOuterPosition(3:4) = defaultSize;
            obj.PrivateInnerPosition(3:4) = defaultSize;

            % Initialize the selection strategy
            obj.updateSelectionStrategy();

            parsePVPairs(obj,  varargin{:});

            if obj.UseDefaultAsPlaceholder
                obj.Items = {matlab.ui.control.internal.model.WorkspaceDropDown.DEFAULT_VALUE_TEXT};
                obj.ItemsData = {matlab.ui.control.internal.model.WorkspaceDropDown.DEFAULT_VALUE};
            else
                obj.Items = {matlab.ui.control.internal.model.WorkspaceDropDown.SELECT_VARIABLE_TEXT};
                obj.ItemsData = {matlab.ui.control.internal.model.WorkspaceDropDown.SELECT_VARIABLE};
            end

            obj.Type = 'uiworkspacedropdown';
            obj.populateVariables();

            obj.attachCallbackToEvent('Clicked', 'PrivateClickedFcn');

            obj.updateValueStrategy();
        end
    end

    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods

        function set.Editable(obj, newValue)

            % Error Checking done through the datatype specification

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

        function set.FilterVariablesFcn(obj, newFilterVariablesFcn)
            % Property Setting
            obj.PrivateFilterVariablesFcn = newFilterVariablesFcn;
            try
                obj.populateVariables();
            catch ME
                % fail silently
            end
            obj.markPropertiesDirty({'FilterVariablesFcn'});
        end

        function value = get.FilterVariablesFcn(obj)
            value = obj.PrivateFilterVariablesFcn;
        end

        function set.ShowNonExistentVariable(obj, newShowNonExistentVariable)
            obj.PrivateShowNonExistentVariable = newShowNonExistentVariable;
            obj.updateValueStrategy();
        end

        function value = get.ShowNonExistentVariable(obj)
            value = obj.PrivateShowNonExistentVariable;
        end

        function value = get.UseDefaultAsPlaceholder(obj)
            value = obj.PrivateUseDefaultAsPlaceholder;
        end

        function set.UseDefaultAsPlaceholder(obj, newValue)
            obj.PrivateUseDefaultAsPlaceholder = newValue;
        end

        function value = get.WorkspaceValue(obj)
            if obj.UseDefaultAsPlaceholder
                placeholder = matlab.ui.control.internal.model.WorkspaceDropDown.DEFAULT_VALUE;
            else
                placeholder = matlab.ui.control.internal.model.WorkspaceDropDown.SELECT_VARIABLE;
            end

            if isempty(obj.Value) || strcmp(obj.Value, placeholder)
                value = [];
            else
                try
                    value = evalin(obj.Workspace, obj.Value);
                catch ME
                    value = [];
                end
            end
        end
    end

    methods(Access = {?matlab.ui.control.internal.controller.ComponentController, ...
            ?matlab.ui.control.internal.model.AbstractStateComponent})

        function value = getValueGivenIndex(obj, index)
            % Returns the Value given the index

            obj.updateValueStrategy();

            % defer to the strategy
            value = obj.ValueStrategy.getValueGivenIndex(index);
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

        function updateValueStrategy(obj)
            % Update to use ValueStrategy classes specific to the Workspace
            % Dropdown
            if obj.ShowNonExistentVariable && ...
                    ~(isa(obj.ValueStrategy, 'matlab.ui.control.internal.model.WSDropDownValueStrategy') || ...
                    isa(obj.ValueStrategy, 'matlab.ui.control.internal.model.WSDropDownDataStrategy'))

                if isempty(obj.PrivateItemsData)
                    obj.ValueStrategy = matlab.ui.control.internal.model.WSDropDownValueStrategy(obj);
                else
                    obj.ValueStrategy = matlab.ui.control.internal.model.WSDropDownDataStrategy(obj);
                end
            end
        end
    end

    methods(Access = public, Hidden)
        % This method is public and hidden to facilitate testing, this should be made private once g2033944 is done
        function populateVariables(obj)
            try
                workspaceVariables = evalin(obj.Workspace, 'who');

                oldValue = obj.Value;
                oldIndex = find(strcmp(obj.ItemsData, oldValue));
                valueWasEdited = ~isempty(obj.ItemsData) && ~any(ismember(obj.ItemsData, obj.Value));

                if ~isempty(obj.FilterVariablesFcn)
                    workspaceData = cellfun(@(x) evalin(obj.Workspace,[x,';']), workspaceVariables, 'UniformOutput', false);
                    if nargin(obj.FilterVariablesFcn) == 2
                        % When value and variable name are used
                        validVariables = cellfun(@obj.FilterVariablesFcn, workspaceData, workspaceVariables);
                    else
                        % Use case where only value is used
                        validVariables = cellfun(@obj.FilterVariablesFcn, workspaceData, ...
                            "ErrorHandler", @(varargin) false);
                    end

                    if obj.UseDefaultAsPlaceholder
                        placeholderValue = matlab.ui.control.internal.model.WorkspaceDropDown.DEFAULT_VALUE;
                        obj.ItemsData = [{placeholderValue}, workspaceVariables{validVariables}];
                        obj.Items = [{matlab.ui.control.internal.model.WorkspaceDropDown.DEFAULT_VALUE_TEXT}, workspaceVariables{validVariables}];
                    else
                        placeholderValue = matlab.ui.control.internal.model.WorkspaceDropDown.SELECT_VARIABLE;
                        obj.ItemsData = [{placeholderValue}, workspaceVariables{validVariables}];
                        obj.Items = [{matlab.ui.control.internal.model.WorkspaceDropDown.SELECT_VARIABLE_TEXT}, workspaceVariables{validVariables}];
                    end
                else
                    if obj.UseDefaultAsPlaceholder
                        placeholderValue = matlab.ui.control.internal.model.WorkspaceDropDown.DEFAULT_VALUE;
                        obj.ItemsData = [{placeholderValue}, workspaceVariables{:}];
                        obj.Items = [{matlab.ui.control.internal.model.WorkspaceDropDown.DEFAULT_VALUE_TEXT}, workspaceVariables{:}];
                    else
                        placeholderValue = matlab.ui.control.internal.model.WorkspaceDropDown.SELECT_VARIABLE;
                        obj.ItemsData = [{placeholderValue}, workspaceVariables{:}];
                        obj.Items = [{matlab.ui.control.internal.model.WorkspaceDropDown.SELECT_VARIABLE_TEXT}, workspaceVariables{:}];
                    end
                end

                if obj.ShowNonExistentVariable && ~isempty(obj.NonExistentVariableName) && ...
                    (isscalar(obj.Items) || ~any(strcmp(obj.NonExistentVariableName, obj.Items(2:end))))

                    % Add in the non-existent variable name if it isn't in the list.  Don't compare with
                    % the first element because that is always "select" or "default"
                    obj.Items = [obj.Items char(obj.NonExistentVariableName)];
                    obj.ItemsData = [obj.ItemsData char(obj.NonExistentVariableName)];
                    if strcmp(obj.NonExistentVariableName, oldValue)
                        % obj.Value could have been reset above when the
                        % Items/ItemsData were updated.  So it needs to be reset
                        % to the NonExistentVariableName if it was previously
                        % selected.
                        obj.Value = oldValue;
                    end
                end

                newIndex = find(strcmp(obj.ItemsData, oldValue));

                if valueWasEdited
                    % the value has been manually edited by the user, and we do
                    % not want to overwrite the entry. do nothing.
                elseif ~any(ismember(obj.ItemsData, obj.Value))
                    % the value no longer exists in the item list. revert to
                    % placeholder value
                    obj.Value = placeholderValue;
                elseif newIndex ~= oldIndex
                    % a workspace variable has been created since the last time
                    % the variables were populated, and it came before the
                    % previous selection. to maintain the current selection, we
                    % need to set the value again explicitly
                    obj.Value = oldValue;
                end
            catch ex
                if isvalid(obj)
                    rethrow(ex)
                end
            end
        end

        % This method is public and hidden to facilitate testing, this should be removed once g2033944 is done
        function triggerValueChanged(obj)
            obj.Controller.triggerValueChanged();
        end

        function handleNonExistentVariables(obj, newValue)
            import matlab.ui.control.internal.model.WorkspaceDropDown;
            if obj.ShowNonExistentVariable && ~strcmp(newValue, WorkspaceDropDown.SELECT_VARIABLE) && ~strcmp(newValue, WorkspaceDropDown.DEFAULT_VALUE)
                if isscalar(obj.Items) || ~any(strcmp(obj.Items(2:end), newValue))
                    % Add in the non-existent variable name if it isn't in the list.  Don't compare with
                    % the first element because that is always "select" or "default"
                    obj.Items = [obj.Items newValue];
                    obj.ItemsData = [obj.ItemsData newValue];
                    obj.NonExistentVariableName = newValue;
                elseif ~strcmp(obj.NonExistentVariableName, newValue)
                    % reset the non-existent variable name, as a different
                    % variable has been selected
                    obj.NonExistentVariableName = strings(0);
                end
            end
        end
    end

    % ---------------------------------------------------------------------
    % Custom Display Functions
    % ---------------------------------------------------------------------
    methods(Access = protected)

        function names = getPropertyGroupNames(~)
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
                'ValueChangedFcn',...
                'FilterVariablesFcn'};
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

           % sObj is the serialization content that was saved for obj
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj);
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.BackgroundColorableComponent(sObj);
        end

    end
end
