classdef ParamTabHandler < handle
    %PARAMTABHANDLER
    %  The PARAMTABHANDLER class manages a toolstrip tab that shows fields
    %  specified in a parameter descriptor.
    %
    % The main responsibilities of this class are:
    % 1. To create a parameter tab
    % 2. Put widgets on the parameter tab based on the parameters specified
    % in the descriptor
    % 3. Fire callbacks for edit box and drop down value change events`
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    
    properties (Constant)
        % NUMFIELDSPERCOLUMN - The number of fields that will be displayed
        % in each toolstrip tab column
        NumFieldsPerColumn = 3;
        % COLUMNWIDTH - The width of each toolstrip tab column in pixels
        ColumnWidth = 100;
    end
    
    properties (Access = private)
        % TABGROUP - The tabgroup containing all the hwmgr tabs
        TabGroup
        % PARAMTAB - The tab that is owned and managed by this class
        ParamTab
        % PARAMSSECTION - The tab section that will have the fields and
        % labels
        ParamsSection
        % LABELSCOLUMNS - All the columns that will house label widgets
        LabelsColumns
        % FIELDSCOLUMS - All the columns that will house field widgets
        FieldsColumns
        % PARAMDESCRIPTOR - The param descriptor object that defines tab
        % contents and behavior
        ParamDescriptor
        % LABELMAP - A containers.Map() object that contains handles to
        % label widgets
        LabelMap
        % VALUEWIDGETMAP - A containers.Map() object that contains handles
        % to value widgets. Value widgets are edit fields, drop-downs.
        ValueWidgetMap
        % CONFIRMBUTTON - Handle to the confirm button widget
        ConfirmButton
        % CANCELBUTTON - Handle to the cancel button widget
        CancelButton
        % PARAMVALMAP - A containers.Map() object that contains parameter
        % names and values. The values are contained as a struct of new and
        % old values.
        ParamValMap
        % TOOLSTRIPCONFIRMHOOK - A function handle to be invoked when the
        % confirm button is clicked
        ToolstripConfirmHook
        % TOOLSTRIPCANCELHOOK - A function handle to be invoked when the
        % cancel button is clicked
        ToolstripCancelHook
        % APPCONTAINER - The handle to the appcontainer object for use as a
        % dialog parent
        AppContainer
        % CurrentDevice - Device that is being configured by the tab
        CurrentDevice
    end
    
    properties (Access = private)
        % Flag to indicate whether the developer has used the ColumnNum
        % argument to customize their columns
        ColumnCustomized = false
    end

    methods
        function obj = ParamTabHandler(tabGroup, pDescriptor, confirmCbk, cancelCbk, appContainer, varargin)
            % Constructor
            %
            % Input argument descriptions
            %
            % tabGroup - handle to the hardware manager tabgroup object
            %
            % pDescriptor - handle to the param descriptor object
            %
            % confirmCbk - function handle of the callback to be invoked on
            %              "confirm" button click
            %
            % cancelCbk - function handle of the callback to be invoked on
            %             "cancel" button click
            
            obj.TabGroup = tabGroup;
            obj.ParamDescriptor = pDescriptor;
            obj.ToolstripConfirmHook = confirmCbk;
            obj.ToolstripCancelHook = cancelCbk;
            obj.AppContainer = appContainer;
            
            % Initialize the maps
            obj.ValueWidgetMap = containers.Map();
            obj.LabelMap = containers.Map();

            if nargin == 6
                obj.CurrentDevice = varargin{1};
                obj.ParamDescriptor.CurrentDevice = obj.CurrentDevice;
            else
                obj.CurrentDevice = [];
            end

            % Load the previously used paramValMap, if any.
            lastUsedParamValMap = obj.getLastUsedMapForDescriptor(obj.ParamDescriptor.getName());
            
            % If there data that was no data saved previously then use an
            % empty paramValMap
            if isempty(lastUsedParamValMap)
                initMap = containers.Map();
                allParams = obj.ParamDescriptor.getParamDescriptorMap().keys;
                for i = 1:numel(allParams)
                    initMap(allParams{i}) = struct('OldValue', '', 'NewValue', '');
                end
            else
            % There was some user config data found. Use it as the initial
            % paramValMap
                initMap = lastUsedParamValMap;
            end
            
            obj.ParamValMap = initMap;
            
            % Assign the bring to front function which provides the dialog
            % parent for client teams needing to show a dialog from the non
            % enum device config page
            obj.ParamDescriptor.setBringToFrontFcn(@(descriptor)obj.descriptorBringToFrontHook(descriptor));

            % Create the tab object
            obj.createTab();
            
            % Place the widgets according to the param descriptor on the
            % tab
            obj.populateTab();
            
            % Finally, add the tab after it has been constructed. Adding a
            % tab renders it so it has to be done at the very end
            obj.addTabToGroup();
        end
        
        function valueChangedCallback(obj, src, event)
            % This is the callback that is invoked if any field widget's
            % value changes. This callback will delegate by invoking, in
            % order, all of the allowedValueFcns and enableFcns of each
            % widget and setting the value and enable properties of the
            % widget respectively
            
            
            % Get the parameter name from the tag since we've baked the
            % parameter name into the tag and uppercased it - we need to
            % lower case it and find it in the set of keys
            lowerCaseKey = lower(strtok(src.Tag, '_'));
            allParamKeys = obj.ParamValMap.keys();
            
            [~, index] = ismember(lowerCaseKey, lower(allParamKeys));
            paramForCallback = allParamKeys{index};
            
            paramDescMap = obj.ParamDescriptor.getParamDescriptorMap();
            paramStruct = paramDescMap(paramForCallback);
            isButton = strcmp(paramStruct.Type, 'PushButton');
            
            % If param is a button, then invoke the custom callback with
            % the paramValMap
            if isButton
                % Call the function and get the new value for the button
                % parameter
                newVal = feval(paramStruct.ButtonPushedFcn, obj.ParamValMap);
                % Update the button old and new values
                valStruct = obj.ParamValMap(paramForCallback);
                valStruct.OldValue = valStruct.NewValue;
                valStruct.NewValue = newVal;
                obj.ParamValMap(paramForCallback) = valStruct;
            else
                % Update the paramValueMap with the old and new value of
                % the widget the user just updated
                obj.ParamValMap(paramForCallback) = rmfield(event.EventData, 'Property');
            end
            
            
            % Next invoke allowed value and enable functions of all the
            % widgets in response to the user initiated change above
            obj.invokeParameterCallbacks();
            
            % Next update the param value map with the latest widget values
            % for the next user initiated sequence updates
            obj.updateParamValMapWithCurrentWidgetValues();
            
            % Any edit fields that are disabled should have the "Not
            % Applicable" text
            obj.addNotApplicableToDisabledEditFields();
            
        end
        
        function confirmCallback(obj, ~, ~)
            % This is the callback method that is invoked when the confirm
            % button is clicked by the user to confirm the parameters
            % entered
            
            % Disable both confirm and cancel buttons while validating the
            % user provided non enum device config params
            obj.ConfirmButton.Enabled = false;
            obj.CancelButton.Enabled = false;

            oc = onCleanup(@()restoreButtons(obj));

            % Ensure the paramValMap is up to date
            obj.updateParamValMapWithCurrentWidgetValues();
            
            % Validate params
            try
                obj.ParamDescriptor.validateParams(obj.ParamValMap);
            catch ex
                % Show error dialog and return
                obj.showValidateError(ex.message);
                return;
            end
            
            % Configure or create the device
            if isempty(obj.CurrentDevice)
                % Create the hardware manager device
                device = obj.ParamDescriptor.createAndInitDevice(obj.ParamValMap);
            else
                % Configure the hardware manager device
                device = obj.ParamDescriptor.configureHwmgrDevice(obj.CurrentDevice, obj.ParamValMap);
            end
            
            % Filter values from ParamValMap that should not be saved
            filteredMap = obj.filterParamValMap(obj.ParamValMap);
            
            % Save the paramValMap for the next time this device is
            % configured and created
            paramValMapStruct = struct('DescriptorName', obj.ParamDescriptor.getName(), 'ParamValMap', filteredMap);

            matlab.hwmgr.internal.util.PrefDataHandler.writeParamValMapToCache(paramValMapStruct);

            % Remove the tab from the tabGroup
            obj.removeTabFromGroup();
            
            % Invoke the confirm handler on the Toolstrip module
            if ~isempty(obj.ToolstripConfirmHook)
                obj.ToolstripConfirmHook(device);
            end
            
            % Cleanup function to restore the state of the buttons
            function restoreButtons(obj)
                % If the param validation succeeded then the param tab
                % handler will be destroyed as the non enum device config
                % is done so check for validity of the config tab
                if isvalid(obj)
                    obj.ConfirmButton.Enabled = true;
                    obj.CancelButton.Enabled = true;
                end
            end

            
        end
        
        function cancelCallback(obj, ~, ~)
            % This is the method that is invoked when the user clicks the
            % cancel button to abort creation of a non enumerable device
            
            % Remove the modal tab from the tabGroup
            obj.removeTabFromGroup();
            
            if ~isempty(obj.ToolstripCancelHook)
                obj.ToolstripCancelHook();
            end
        end

        function dlgParent = descriptorBringToFrontHook(obj, ~)
            % This method is called by the client descriptors to get the
            % dialog parent
            dlgParent = obj.AppContainer;
        end
        
    end
    
    % Methods accessible only by Test
    methods (Access = ?tParamTabHandler)
        function map = getValueWidgetMap(obj)
            map = obj.ValueWidgetMap;
        end
        
        function map = getParamValMap(obj)
            map = obj.ParamValMap;
        end
        
        function map = getLabelWidgetMap(obj)
            map = obj.LabelMap;
        end
        
        function tab = getParamTab(obj)
            tab = obj.ParamTab;
        end
        
        function sections = getParamsSection(obj)
           sections = obj.ParamsSection;
        end
    end
    
    methods (Access = private)
                
        function populateTab(obj)
            % This method will populate the modal tab with the widgets
            % requested by the param descriptor object.
            %
            % The main steps are as follows:
            % 1. Get the param descriptor map from the descriptor object
            %
            % 2. Loop through all parameter descriptions. For each
            % parameter description, create the appropriate widgets
            %
            % 3. Once all widgets are created, create the tab section and
            % the section columns that will house the widgets
            %
            % 4. Add all the widgets to the section columns
            %
            % 5. Create the section and columns to house the "Cancel" and
            % "Confirm" buttons
            %
            % 6. Create the "Cancel" and "Confirm" buttons and wire the
            % callbacks
            
            % Step 1: Get all param names and order the parameters in the
            % order they were added by the client device provider
            paramDescriptorMap = obj.ParamDescriptor.getParamDescriptorMap();
            
            unOrderedParamIDs= paramDescriptorMap.keys();
            
            % Order the params in the order they were added by the client
            orderedParamIDs = orderParams(unOrderedParamIDs);
         
                        
            % Step 2: Loop through each param, and create the appropriate widget.
            % Set the value changed callback to the callback method defined
            % in this class.
            % 
            % In this step, we also get the name of the section that
            % parameters should be shown in
            
            % Initialize section name array to collect all the section names
            % and order them
            sectionLabels = repmat("", size(orderedParamIDs));
            
            % Initialize map of section to ordered parameter IDs. We'll use
            % this map to populate the sections with parameters in order
            sectionToParamMap = containers.Map();
            
            for i = 1:numel(orderedParamIDs)
                currID = orderedParamIDs{i};
                paramStruct = paramDescriptorMap(currID);
                
                % Get the section name
                sectionLabels(i) = convertCharsToStrings(paramStruct.SectionLabel);
                
                % Add the parameter ID to the section map
                sectionToParamMap = addParamToSectionMap(sectionToParamMap, sectionLabels(i), currID);
                
                valueWidget = createWidget(paramStruct);
                
                assignCallbackToWidget(paramStruct, valueWidget);
                
                % Create the label widget for the parameter
                labelWidget = createLabelWidget(currID, paramStruct);
                
                % Cache the widget handles
                obj.LabelMap(currID) = labelWidget;
                obj.ValueWidgetMap(currID) = valueWidget;
            end
            
            obj.addNotApplicableToDisabledEditFields();
            
            % Remove duplicates and get list of unique section names, and
            % maintain the order they were added in by the client
            sectionLabels = unique(sectionLabels, 'stable');
            
            % For each section label, create the section and add the
            % columns and widgets into them
            for secNum = 1:numel(sectionLabels)
                currSectionLabel = sectionLabels(secNum);
                % Step 3: Create the Section
                section = createSection(currSectionLabel);

                % Step 3-4: Create the Columns and add the widgets
                placeWidgetsInSection(section, currSectionLabel, sectionToParamMap);
            end
            
            
            % Steps 5-6: Add the buttons
            
            % Create the "Confirm Parameters" section
            confirmParamsSectionTitle = message('hwmanagerapp:framework:ConfirmParamsSectionLabel').getString();
            confirmParamsSection = createSection(confirmParamsSectionTitle);
            confirmParamsSection.Tag = 'modaltab_confirmparamssection';
            
            
            confirmButtonLabel = message('hwmanagerapp:framework:ConfirmParamsBtnLabel').getString();
            obj.ConfirmButton = matlab.ui.internal.toolstrip.Button(confirmButtonLabel, "validated");
            obj.ConfirmButton.ButtonPushedFcn = @obj.confirmCallback;
            obj.ConfirmButton.Description = message('hwmanagerapp:framework:ConfirmParamsTooltip').getString();
            obj.ConfirmButton.Tag = 'Proto_Desc_Confirm_Button';
            
            cancelButtonLabel = message('hwmanagerapp:framework:CancelBtnLabel').getString();
            obj.CancelButton = matlab.ui.internal.toolstrip.Button(cancelButtonLabel, "close");
            obj.CancelButton.ButtonPushedFcn = @obj.cancelCallback;
            
            confirmColumn = confirmParamsSection.addColumn('HorizontalAlignment', 'right');
            cancelColumn = confirmParamsSection.addColumn('HorizontalAlignment', 'right');
            confirmColumn.add(obj.ConfirmButton);
            cancelColumn.add(obj.CancelButton);
            obj.CancelButton.Description = message('hwmanagerapp:framework:CancelParamsTooltip').getString();
            obj.CancelButton.Tag = 'Proto_Desc_Cancel_Button';
            
            %-------------------------------------------------------------%
            %                   Nested utility functions                  %
            %-------------------------------------------------------------%
            
            function sectionMap = addParamToSectionMap(sectionMap, sectionLabel, paramID)
               % Get the param array from the sectionMap for the given
               % section label
               if sectionMap.isKey(sectionLabel)
                   % Get the existing array
                   paramArray = sectionMap(sectionLabel);
                   % Add to the array
                   paramArray{end+1} = paramID;
                   % Update map
                   sectionMap(sectionLabel) = paramArray;
               else
                   % Initialize
                  sectionMap(sectionLabel) = {paramID};
               end
            end
            
            function assignCallbackToWidget(paramStruct, valueWidget)
                if isEmptyControl(paramStruct)
                    return
                end
                if strcmp(paramStruct.Type, 'PushButton')
                    valueWidget.ButtonPushedFcn = @(s,e)obj.valueChangedCallback(valueWidget,e);
                else
                    addParamValStructToMap(currID, valueWidget);
                    % Set the callback on the widget
                    valueWidget.ValueChangedFcn = @(s,e)obj.valueChangedCallback(valueWidget,e);
                end
            end
            
            function addParamValStructToMap(paramID, widget)                
                % Initialize the param value map for the given parameter by
                % inspecting the widget. When the widget was created, the
                % default or starting value may have been provided by the
                % client so use that as the old and new values. Note that
                % the old and new values are the same at initialization
                
                newValue = widget.Value;
                paramValStruct = struct('OldValue', obj.ParamValMap(paramID).OldValue , 'NewValue', newValue);
                obj.ParamValMap(paramID) = paramValStruct;
            end
            
            function valueWidget = createWidget(paramStruct)
                if isDropDown(paramStruct)                    
                    valueWidget = createDropDown(paramStruct.ParamID);
                elseif isEditableDropDown(paramStruct)
                    valueWidget = createEditableDropDown(paramStruct.ParamID);    
                elseif isEditField(paramStruct)
                    valueWidget = createEditField(paramStruct.ParamID);
                elseif isNonEditableField(paramStruct)
                    valueWidget = createNonEditableField(paramStruct.ParamID);
                elseif isButton(paramStruct)
                    valueWidget = createButton(paramStruct);
                elseif isCheckBox(paramStruct)
                    valueWidget = createCheckBox(paramStruct.ParamID);
                elseif isEmptyControl(paramStruct)
                    valueWidget = matlab.ui.internal.toolstrip.EmptyControl;
                    return
                else
                    error('Unknown parameter type %s', paramStruct.Type);
                end
                valueWidget.Description = paramStruct.Description;
            end
            
            function orderedParams = orderParams(unOrderedParams)
                % Initialize
                orderedParams = cell(size(unOrderedParams));
                
                for unorderedIdx = 1:numel(unOrderedParams)
                    currParam = unOrderedParams{unorderedIdx};
                    orderedParams{paramDescriptorMap(currParam).ParamIndex} = currParam;
                end
            end

            
            function currSection = createSection(sectionLabel)
                   currSection = obj.ParamTab.addSection(sectionLabel);
                   obj.ParamsSection = [obj.ParamsSection; currSection];
            end
            
            function bool = isEmptyControl(pStruct)
                bool = strcmp(pStruct.Type, 'EmptyControl');
            end

            function bool = isDropDown(pStruct)
                bool = strcmp(pStruct.Type, 'DropDown');
            end
            
            function bool = isEditableDropDown(pStruct)
                bool = strcmp(pStruct.Type, 'EditableDropDown');
            end
            
            function bool = isEditField(pStruct)
                bool = strcmp(pStruct.Type, 'EditField');
            end
            
            function bool = isNonEditableField(pStruct)
               bool = strcmp(pStruct.Type, 'NonEditableField'); 
            end
            
            function bool = isButton(pStruct)
               bool = strcmp(pStruct.Type, 'PushButton');
            end

            function bool = isCheckBox(pStruct)
                bool = strcmp(pStruct.Type, 'CheckBox');
            end
            
            function valueWidget = createButton(buttonStruct)
                valueWidget = matlab.ui.internal.toolstrip.Button();
                
                 % Set the tag to the param name for identification
                valueWidget.Tag = [upper(buttonStruct.ParamID) '_PARAM_TAB_FIELD'];
                
                valueWidget.Text = buttonStruct.Label;
                
                valueWidget.Icon = buttonStruct.Icon;
                
                valueWidget.Enabled = obj.invokeEnableFcnFor(buttonStruct.ParamID);
            end

            function valueWidget = createCheckBox(currID)
                valueWidget = matlab.ui.internal.toolstrip.CheckBox();

                % Set the tag to the param name for identification
                valueWidget.Tag = [upper(currID) '_PARAM_TAB_FIELD'];

                valueWidget.Enabled = obj.invokeEnableFcnFor(currID);

                % Get the default value from the param descriptor
                allowedValues = obj.invokeAllowedValuesFcnFor(currID);

                % Set the widget value
                if islogical(allowedValues)
                    valueWidget.Value  = allowedValues;
                end
            end

            function valueWidget = createEditableDropDown(currID)
                % Create a standard drop down
                valueWidget = createDropDown(currID);
                valueWidget.Editable = true;
            end
            
            function valueWidget = createDropDown(currID)
                % Create drop down
                valueWidget = matlab.ui.internal.toolstrip.DropDown;
                
                % Set the tag to the param name for identification
                valueWidget.Tag = [upper(currID) '_PARAM_TAB_FIELD'];
                
                % Get the list of drop down items from the param descriptor
                % interface
                callbackReturn = obj.invokeAllowedValuesFcnFor(currID);
                
                % Clients can provide a struct with "Value" and "List"
                % fields or a cell array of values to be used as the list
                specifiedValue = [];
                if isstruct(callbackReturn)
                    dropDownItems = callbackReturn.List;
                    specifiedValue = callbackReturn.Value;
                else
                    dropDownItems = callbackReturn;
                end
                
                % Fill the drop down with the items
                for k = 1:numel(dropDownItems)
                    valueWidget.addItem(dropDownItems{k});
                end
                
                % Select the first item as the selected value. Otherwise,
                % set the specified value
                if isempty(specifiedValue)
                    valueWidget.SelectedIndex = 1;
                else
                    valueWidget.Value = specifiedValue;
                end
                
                % Disable or enable the widget based on the param descriptor
                valueWidget.Enabled = obj.invokeEnableFcnFor(currID);
            end
            
            function valueWidget = createEditField(currID)
                % Create the edit field
                valueWidget = matlab.ui.internal.toolstrip.EditField();
                
                % Set the tag to the param name for identification
                valueWidget.Tag = [upper(currID) '_PARAM_TAB_FIELD'];
                
                % Get the default value from the param descriptor
                allowedValues = obj.invokeAllowedValuesFcnFor(currID);
                
                % Set the widget value
                valueWidget.Value  = allowedValues;
                
                % Enable or disable the widget via the param descriptor
                valueWidget.Enabled = obj.invokeEnableFcnFor(currID);
            end
            
            function valueWidget = createNonEditableField(currID)
                 % Create the edit field
                valueWidget = matlab.ui.internal.toolstrip.EditField();
                
                % Set the tag to the param name for identification
                valueWidget.Tag = [upper(currID) '_PARAM_TAB_FIELD'];
                
                % Get the default value from the param descriptor
                allowedValues = obj.invokeAllowedValuesFcnFor(currID);
                
                % Set the widget value
                valueWidget.Value  = allowedValues;
                
                % Set the widget to be non-editable
                valueWidget.Editable = false;
                
                % Enable or disable the widget via the param descriptor
                valueWidget.Enabled = obj.invokeEnableFcnFor(currID);
            end
            
            function labelWidget = createLabelWidget(currID, paramStruct)
                if strcmp(paramStruct.Type, 'PushButton') && strcmp(paramStruct.Style, 'Horizontal')
                    labelWidget = matlab.ui.internal.toolstrip.EmptyControl();
                elseif strcmp(paramStruct.Type, 'PushButton') && strcmp(paramStruct.Style, 'Vertical')
                    labelWidget = [];
                elseif isEmptyControl(paramStruct)
                    labelWidget = matlab.ui.internal.toolstrip.EmptyControl();
                else
                    labelWidget = matlab.ui.internal.toolstrip.Label(paramStruct.ParamName);
                end
                labelWidget.Tag = [upper(currID) '_PARAM_TAB_LABEL'];
            end
            
            function placeWidgetsInSection(section, sectionLabel, sectionParamMap)
                
                % Get the parameters for the current section. This param
                % array is ordered
                paramsForSection = sectionParamMap(sectionLabel);
                
                % Recursively place all the widgets in the current section
                recursivePlaceWidgetsInSection(section, [], [], paramsForSection, 0);
            end
            
            function recursivePlaceWidgetsInSection(section, labelColumn, fieldColumn, paramsForSection, columnNum)                
                
                % If the next param is empty, we're done so return - this is the end
                % of the recursion
                if isempty(paramsForSection)
                    if ~obj.ColumnCustomized
                        % fill the remaining rows and columns with empty
                        % controls if the columns have not been customized
                        % to maintain previous design
                        fillWithEmptyControl(labelColumn);
                        fillWithEmptyControl(fieldColumn);
                    end
                   return;
                end
                
                % Get the next param
                paramID = paramsForSection{1};
                
                
                % Get the paramStruct from the descriptor
                paramMap = obj.ParamDescriptor.getParamDescriptorMap();
                paramStruct = paramMap(paramID);

                % If the columnNum argument has been provided, set the
                % ColumnCustomized property to true
                if ~isempty(paramStruct.ColumnNum)
                    obj.ColumnCustomized = true;
                    % if the columnNum is higher than the current columnNum
                    % add a new Column
                    if paramStruct.ColumnNum > columnNum
                        [labelColumn, fieldColumn, columnNum] = initLabelAndFieldColumns(columnNum);
                        recursivePlaceWidgetsInSection(section, labelColumn, fieldColumn, paramsForSection, columnNum);
                        return
                    end
                end

                paramsForSection = paramsForSection(2:end);
                
                % If the widget type is a vertical button, then pad the
                % current columns with empty controls and create a
                % dedicated columns with the vertical button
                if isVerticalButton(paramStruct)
                    
                    % Maintain original vertical button behavior if the
                    % column propeties have not been customized by the
                    % client
                    if ~obj.ColumnCustomized
                        fillWithEmptyControl(labelColumn);
                        fillWithEmptyControl(fieldColumn);
                    end
                    
                    verticalButtonCol = section.addColumn('HorizontalAlignment' , 'center');
                    
                    verticalButton = obj.ValueWidgetMap(paramID);
                    verticalButtonCol.add(verticalButton);
                else
                   
                    % If this is the first parameter of this kind being
                    % added, the label and field columns may be empty so
                    % initialize them if necessary
                    if isempty(labelColumn) || isempty(fieldColumn) || (numel(labelColumn.getChildByIndex) == 3)
                        [labelColumn, fieldColumn, columnNum] = initLabelAndFieldColumns(columnNum);
                    end

                    % If the parameter is a button, add the empty control
                    % to the field column so that the button lives on the
                    % label column when the alignment is "left",
                    % otherwise add the labelColumn and fieldColumn as per
                    % usual
                    if isButton(paramStruct) && fieldColumn.HorizontalAlignment == "left"
                        labelColumn.add(obj.ValueWidgetMap(paramID));
                        fieldColumn.add(matlab.ui.internal.toolstrip.EmptyControl());
                    elseif isCheckBox(paramStruct)
                        fieldColumn.add(obj.LabelMap(paramID));
                        labelColumn.add(obj.ValueWidgetMap(paramID));
                    else
                        labelColumn.add(obj.LabelMap(paramID));
                        fieldColumn.add(obj.ValueWidgetMap(paramID));
                    end
                end
                
                recursivePlaceWidgetsInSection(section, labelColumn, fieldColumn, paramsForSection, columnNum);
 
            end
            
            function [labelColumn, fieldColumn, columnNum] = initLabelAndFieldColumns(columnNum)
                % Add a new Label and Field Columns with the provided Column
                % properties or the default properties
                columnNum = columnNum + 1;
                % default column properties
                colWidth = obj.ColumnWidth;
                colHorizontalAlignment = 'right';
                % get specific column properties if it exists
                key = currSectionLabel+"_"+columnNum;
                val = [];
                if isKey(obj.ParamDescriptor.ColumnProp, key)
                    val = obj.ParamDescriptor.ColumnProp(key);
                end
                if ~isempty(val)
                    colWidth = val.Width;
                    colHorizontalAlignment = val.HorizontalAlignment;
                end
                % create the new label and field column
                labelColumn = section.addColumn('HorizontalAlignment', 'right');
                fieldColumn = section.addColumn('width', colWidth, 'HorizontalAlignment' , colHorizontalAlignment);
            end
            
            function bool = isVerticalButton(paramStruct)
                bool = strcmp(paramStruct.Type, 'PushButton') && strcmp(paramStruct.Style, 'Vertical');
            end
            
            function fillWithEmptyControl(column)
                if isempty(column)
                   return; 
                end
                filledRows = column.getChildByIndex();
                rowsToFill = obj.NumFieldsPerColumn - numel(filledRows);
                for k = 1:rowsToFill
                   column.addEmptyControl(); 
                end
            end
                                    
        end
        
        function addTabToGroup(obj)
           % Add the param tab to the hardware manager tab group
           obj.TabGroup.add(obj.ParamTab); 
           drawnow;
        end
        
        function createTab(obj)
            % This method will create the toolstrip tab and set the title
            % appropriately
            title = message('hwmanagerapp:framework:NonEnumDevModalTabTitle').getString();
            obj.ParamTab = matlab.ui.internal.toolstrip.Tab(title);
        end
        
        function removeTabFromGroup(obj)
            obj.TabGroup.remove(obj.ParamTab);
            drawnow;
        end
        
        function showValidateError(obj, msg)
            % This is a utility method to show an error dialog with the
            % given MSG
            constructorName = obj.ParamDescriptor.getName();
            msgString = message('hwmanagerapp:framework:ValidateParamsErrorDlgTitle', constructorName).getString;
            dlgTitle = regexprep(msgString, '[\n\r]+', ' ');
            matlab.hwmgr.internal.DialogFactory.constructErrorDialog(obj.AppContainer, msg, dlgTitle);
        end
        
        function updateParamValMapWithCurrentWidgetValues(obj)
            % Update param val map with all the changes that were made to
            % the fields by the user + via the AllowedValueFcns.
            
            % Get the names of all the params
            paramDescriptorMap = obj.ParamDescriptor.getParamDescriptorMap();
            allParamIDs = paramDescriptorMap.keys();
            
            for i = 1:numel(allParamIDs)
                valueWidget = obj.ValueWidgetMap(allParamIDs{i});
                if ~isa(valueWidget, 'matlab.ui.internal.toolstrip.Button') && ~isa(valueWidget, 'matlab.ui.internal.toolstrip.EmptyControl') 
                    obj.ParamValMap(allParamIDs{i}) = struct('OldValue', valueWidget.Value, 'NewValue', valueWidget.Value);
                end
            end
        end
        
        function addNotApplicableToDisabledEditFields(obj)
            % This method will add the "Not Applicable" string to the 
            % Get the names of all the params
            paramDescriptorMap = obj.ParamDescriptor.getParamDescriptorMap();
            allParamIDs = paramDescriptorMap.keys();
            
            for i = 1:numel(allParamIDs)
                valueWidget = obj.ValueWidgetMap(allParamIDs{i});
                if isa(valueWidget,  'matlab.ui.internal.toolstrip.EmptyControl')
                    continue
                end
                if ~valueWidget.Enabled && isa(valueWidget,  'matlab.ui.internal.toolstrip.EditField')
                    valueWidget.Value = message('hwmanagerapp:framework:NotApplicable').getString;
                end
            end
            
        end
        
        function filteredMap = filterParamValMap(obj, paramMap)
            % For nonEditableFields and buttons, set OldValue and NewValue
            % fields to 0x0 char arrays.
            
            filteredMap = paramMap;
            allParamIDs = paramMap.keys();
            
            for i = 1:numel(allParamIDs)
                valueWidget = obj.ValueWidgetMap(allParamIDs{i});
                if isa(valueWidget, 'matlab.ui.internal.toolstrip.Button') || ...
                        (isa(valueWidget, 'matlab.ui.internal.toolstrip.EditField') && ~valueWidget.Editable)
                    filteredMap(allParamIDs{i}) = struct('OldValue', '', 'NewValue', '');
                end
            end
        end
        
        function invokeParameterCallbacks(obj)
            % For each widget, invoke AllowedValuesFcn with the paramValMap
            % constant - does not change between invocations of
            % AllowedValuesFcn. This is so that there is no
            % infinite cascade of AllowedValuesFcn.
            
            % At the end of the invocations, set the OldValue and NewValue
            % of all other params to the new value of the field widgets.
            
            % Get the names of all the params
            paramDescriptorMap = obj.ParamDescriptor.getParamDescriptorMap();
            allParamIDs = paramDescriptorMap.keys();
            
            for i = 1:numel(allParamIDs)
                % Get the widget handle
                valueWidget = obj.ValueWidgetMap(allParamIDs{i});

                % No values for empty control
                if isa(valueWidget, 'matlab.ui.internal.toolstrip.EmptyControl')
                    continue
                end
                
                % Invoke the allowed values function
                callbackReturn = obj.invokeAllowedValuesFcnFor(allParamIDs{i});
                allowedValues = callbackReturn;
                % Now that we have the allowed values, see if the value in
                % the widget needs to be updated
                
                if isa(valueWidget, 'matlab.ui.internal.toolstrip.DropDown')
                    
                    % Clients can either return a cell array of allowed
                    % values or a struct with fields "Value" and "List" to
                    % indicate the value to be set in the field and list of
                    % available values that can be sepected, respectively
                    if  isstruct(callbackReturn)
                        valueWidget.Value= callbackReturn.Value;
                        allowedValues = callbackReturn.List;
                    end
                    
                    % If there is no change to the drop down list,
                    % continue. 
                    if isempty(setxor(allowedValues, valueWidget.Items(:,1)))
                        continue;
                    end
                    
                    % There is a change in the list, so remove the existing
                    % values
                    if isrow(allowedValues)
                       % If a row vector cell array was returned then
                       % convert to n x 2 (one for value other for tooltip)
                       newItems = [allowedValues' allowedValues'];
                    else
                       % Assume the allowedValues is the correct size for
                       % drop down usage
                       newItems = allowedValues; 
                    end
                    
                    valueWidget.replaceAllItems(newItems);
                    
                    % Set the selected value to the first item in the list
                    valueWidget.SelectedIndex = 1;
                    
                    
                    % Enable or disable the widget based on the latest user
                    % selection
                    valueWidget.Enabled = obj.invokeEnableFcnFor(allParamIDs{i});
                elseif isa(valueWidget, 'matlab.ui.internal.toolstrip.EditField') || isa(valueWidget, 'matlab.ui.internal.toolstrip.CheckBox')
                    
                    % Set the default value from the param descriptor
                    valueWidget.Value = allowedValues;
                    
                    % Enable or disable the widget based on the latest user
                    % selection
                    valueWidget.Enabled = obj.invokeEnableFcnFor(allParamIDs{i});
                elseif isa(valueWidget, 'matlab.ui.internal.toolstrip.Button')
                    % Invoke enable fcn for the button
                    valueWidget.Enabled = obj.invokeEnableFcnFor(allParamIDs{i});
                else
                    error('Unknown widget type "%s"', class(valueWidget));
                end
                
                
            end
        end
        
        function allowedValues = invokeAllowedValuesFcnFor(obj, name)
            % This method will invoke all the "AllowedValueFcn"s for each
            % parameter
            paramDescriptorMap = obj.ParamDescriptor.getParamDescriptorMap();
            fcn = paramDescriptorMap(name).AllowedValuesFcn;
            if isempty(fcn)
                allowedValues = obj.ParamValMap(name).NewValue;
            else
                allowedValues = fcn(obj.ParamValMap);
            end
        end
        
        function isEnabled = invokeEnableFcnFor(obj, name)
            paramDescriptorMap = obj.ParamDescriptor.getParamDescriptorMap();
            fcn = paramDescriptorMap(name).EnableFcn;
            if isempty(fcn)
                isEnabled = true;
            else
                isEnabled = fcn(obj.ParamValMap);
            end
        end
        
    end
    
    methods (Static, Access = private)
        function lastUsedMap = getLastUsedMapForDescriptor(descriptorName)
            allMapData = matlab.hwmgr.internal.util.PrefDataHandler.loadParamValMapsFromCache();
            lastUsedMap = [];
            for i = 1:numel(allMapData)
                if strcmp(allMapData(i).DescriptorName, descriptorName)
                    lastUsedMap = allMapData(i).ParamValMap;
                end
            end
        end

    end
end
