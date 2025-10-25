classdef Section < matlab.ui.internal.toolstrip.Section
    %SECTION

%   Copyright 2020-2021 The MathWorks, Inc.
    
    properties (Hidden, SetAccess = protected)
        Widgets = struct;
    end
    
    properties (Hidden)
        % Hold a handle to the Tab in order to throw good events.
        Tab
    end
    
    events
        PropertyChanged
        ButtonPressed
    end
    
    methods
        function this = Section(id)
            this@matlab.ui.internal.toolstrip.Section;
            if endsWith(id, 'Section')
                postFix = 'Title';
            else
                postFix = 'SectionTitle';
            end
            this.Title = getString(this, id, postFix);
            this.Tag = id;
        end
        
        function setProperty(this, prop, value)
            w = this.Widgets;
            % Ignore missing properties.
            if ~isfield(w, prop)
                return;
            end
            w = w.(prop);
            if isa(w, 'matlab.ui.internal.toolstrip.DropDownButton') || isa(w, 'matlab.ui.internal.toolstrip.ListItemWithPopup')
                setRadioProperty(this, prop, value);
            else
                for indx = 1:numel(w)
                    w(indx).Value = value;
                end
                notifyPropertyChanged(this, prop);
            end
        end
        
        function value = getProperty(this, prop)
            if isfield(this.Widgets, prop)
                w = this.Widgets.(prop)(1);
            else
                allProps = fieldnames(this.Widgets);
                indx = find(strncmp(allProps, prop, numel(prop)));
                w = this.Widgets.(allProps{indx(1)});
            end
            if isa(w, 'matlab.ui.internal.toolstrip.ListItemWithRadioButton') || ...
                    isa(w, 'matlab.ui.internal.toolstrip.DropDownButton') || ...
                    isa(w, 'matlab.ui.internal.toolstrip.ListItemWithPopup')
                value = getRadioProperty(this, prop);
            elseif isa(w, 'matlab.ui.internal.toolstrip.GridPickerButton')
                value = w.Selection;
            else
                value = w.Value;
            end
        end
        
        function setText(this, id, text, varargin)
            %setText(obj, ID, TXT) set the widget associated with ID's Text
            %property to match the output of getString(obj, text)
            w = this.Widgets;
            if nargin < 3
                if isa(w.(id), 'matlab.ui.internal.toolstrip.ListItemWithPopup')
                    text = getListItemWithPopupRadioListText(this, id, getProperty(this, id));
                else
                    text = getString(this, id, 'Text');
                end
            else
                text = getString(this, text);
            end
            setWidgetProperty(this, id, 'Text', text, varargin{:});
        end

        function setDescription(this, id, desc, varargin)
            setWidgetProperty(this, id, 'Description', getString(this, desc, 'Description'), varargin{:});
        end
        
        function setIcon(this, id, icon, varargin)
            setWidgetProperty(this, id, 'Icon', getIcon(this, icon), varargin{:});
        end
        
        function setRadioProperty(this, prop, value)
            w = getRadioWidgets(this, prop);
            w = findobj(w, '-not', 'Tag', [prop value]);
            [w.Value] = deal(false);
            if isfield(this.Widgets, [prop value])
                this.Widgets.([prop value]).Value = true;
            end
            if isfield(this.Widgets, prop)
                setText(this, prop);
            end
            notifyPropertyChanged(this, prop);
        end
        
        function value = getRadioProperty(this, id)
            w = getRadioWidgets(this,id);

            % If there are no widgets for this radio button return '' as
            % there is no current selection.
            if isempty(w)
                value = '';
            else
                v = [w.Value];
                if ~any(v)
                    % If no widget selected, use the first
                    value = w(1).Tag;
                else
                    % Get the selection from the active widget.
                    value = w(v).Tag;
                end
                value = strrep(value, id, '');
            end
        end
        
        function setWidgetProperty(this, id, prop, value, ind)
            w = this.Widgets.(id);
            if nargin > 4
                w = w(ind);
            end
            [w.(prop)] = deal(value);
        end
    end
    
    methods (Access = protected)
        
        function w = getRadioWidgets(this, id)
            w = this.Widgets;
            f = fieldnames(w);
            % Find all widgets that start with id, but dont match it
            % exactly as that is the parent node.
            ind = xor(strcmp(f, id), strncmp(f, id, numel(id)));
            c = struct2cell(w);
            w = [c{ind}];
        end
        
        function catalog = getCatalog(~)
            catalog = 'Spcuilib:application';
        end
        
        function idPrefix = getCatalogEntryPrefix(~)
            idPrefix = '';
        end
        
        function p = getIconPath(~)
            p = fullfile(toolboxdir('shared'), 'spcuilib', 'applications', '+matlabshared', '+application');
        end
        
        function icon = getIcon(this, icon)
            if ~isempty(icon) && (ischar(icon) || isstring(icon))
                [~,~,ext] = fileparts(icon);

                % If there is no file extension then the icon info must be an SVG icon
                if isempty(ext)
                    icon = matlab.ui.internal.toolstrip.Icon(icon);
                else
                    icon = matlab.ui.internal.toolstrip.Icon(fullfile(getIconPath(this), icon));
                end
            end
        end
    end
    
    methods (Hidden)

        function gridPicker = createGridPickerButton(this, id, icon)
            if nargin < 3
                icon = matlab.ui.internal.toolstrip.Icon.LAYOUT_24;
            end
            gridPicker = matlab.ui.internal.toolstrip.GridPickerButton(getString(this, id), getIcon(this, icon));
            gridPicker.Tag = id;
            gridPicker.ValueChangedFcn = @(~, ~) propertyCallback(this, id);
            saveWidget(this, gridPicker, id);
        end

        function empty = createEmptyControl(this, id)
            empty = matlab.ui.internal.toolstrip.EmptyControl;
            saveWidget(this, empty, id)
        end

        function label = createLabel(this, id, icon)
            id = [id 'Label'];
            label = matlab.ui.internal.toolstrip.Label(getString(this, id));
            if nargin > 2
                label.Icon = getIcon(this, icon);
            end
            saveWidget(this, label, id);
        end
        
        function str = getString(this, id, postfix)
            if nargin < 3
                postfix = 'Text';
            end
            str = getString(message([getCatalog(this) ':' getCatalogEntryPrefix(this) id postfix]));
        end
        
        function edit = createEditField(this, id, varargin)
            edit = matlab.ui.internal.toolstrip.EditField(varargin{:});
            edit.ValueChangedFcn = @(~, ~) propertyCallback(this, id);
            saveWidget(this, edit, id);
        end
        
        function toggle = createToggleButton(this, id, icon)
            toggle = matlab.ui.internal.toolstrip.ToggleButton(...
                getString(this, id), getIcon(this, icon));
            toggle.ValueChangedFcn = @(~, ev) propertyCallback(this, id, ev);
            saveWidget(this, toggle, id);
        end
        
        function button = createButton(this, id, icon)
            button = matlab.ui.internal.toolstrip.Button( ...
                getString(this, id), getIcon(this, icon));
            button.ButtonPushedFcn = @(~, ~) buttonCallback(this, id);
            saveWidget(this, button, id);
        end
        
        function split = createToggleSplitButton(this, id, icon, varargin)
            split = matlab.ui.internal.toolstrip.ToggleSplitButton( ...
                getString(this, id), getIcon(this, icon));
            split.Tag = id;
            split.ValueChangedFcn = @(~, ev) propertyCallback(this, id, ev);
            addItemsToWidget(split, varargin{:});
            saveWidget(this, split, id);
            addItemsToWidget(split, varargin{:});
        end
        
        function split = createSplitButton(this, id, icon, varargin)
            split = matlab.ui.internal.toolstrip.SplitButton( ...
                getString(this, id), getIcon(this, icon));
            split.ButtonPushedFcn = @(~, ~) buttonCallback(this, id);
            saveWidget(this, split, id);
            addItemsToWidget(split, varargin{:});
        end
        
        function combo = createComboBox(this, varargin)
            combo = this.createDropDown(varargin{:});
            combo.Editable = true;
        end
        
        function dropdown = createDropDown(this, id, items, strings)
            % createDropDown(this, id, items[, autoCreate]) creates a
            % dropdown widget with Tag set to id and items. If autoCreate
            % is true (the default) the items' second column will be
            % populated with the output of getString(this, [id item{indx}])
            if nargin < 4 || islogical(strings)
                items = items(:);
                for indx = 1:numel(items)
                    items{indx, 2} = getString(this, [id items{indx}]);
                end
                if nargin > 3 && strings
                    items(:, 1) = lower(items(:, 1));
                end
            else
                items = [items strings];
            end
            dropdown = matlab.ui.internal.toolstrip.DropDown(items);
            dropdown.SelectedIndex = 1;
            dropdown.ValueChangedFcn = @(~, ~) propertyCallback(this, id);
            saveWidget(this, dropdown, id);
        end
        
        function dropdown = createDropDownButton(this, id, icon, varargin)
            %createDropDownButton(this, id, icon, item1, item2, etc.)
            
            % Create the dropdown, using the id to populate the text
            dropdown = matlab.ui.internal.toolstrip.DropDownButton(...
                getString(this, id, 'Text'), getIcon(this, icon));
            
            saveWidget(this, dropdown, id);
            addItemsToWidget(dropdown, varargin{:});
        end
        
        function spinner = createSpinner(this, id, range, value)
            spinner = matlab.ui.internal.toolstrip.Spinner(range, value);
            spinner.ValueChangedFcn = @(~,~) propertyCallback(this, id);
            saveWidget(this, spinner, id);
        end
        
        function box = createCheckBox(this, id, varargin)
            box = matlab.ui.internal.toolstrip.CheckBox(...
                getString(this, id), varargin{:});
            box.ValueChangedFcn = @(~, ~) propertyCallback(this, id);
            saveWidget(this, box, id);
        end
        
        function slider = createSlider(this, id, limits, value)
            slider = matlab.ui.internal.toolstrip.Slider(limits, value);
            slider.ValueChangedFcn = @(~, ~) propertyCallback(this, id);
            saveWidget(this, slider, id);
        end
        
        function listitem = createListItem(this, id)
            listitem = matlab.ui.internal.toolstrip.ListItem(getString(this, id));
            listitem.ItemPushedFcn = @(~,~) buttonCallback(this, id);
            saveWidget(this, listitem, id);
        end
        
        function listitem = createListItemWithCheckBox(this, id, value)
            listitem = matlab.ui.internal.toolstrip.ListItemWithCheckBox(getString(this, id));
            listitem.Value = value;
            listitem.ValueChangedFcn = @(~, ev) propertyCallback(this, id, ev);
            saveWidget(this, listitem, id);
        end
        
        function listitem = createListItemWithEditField(this, id, value)
            listitem = matlab.ui.internal.toolstrip.ListItemWithEditField(getString(this, id));
            listitem.Value = value;
            listitem.ValueChangedFcn = @(~, ~) propertyCallback(this, id);
            saveWidget(this, listitem, id);
        end
        
        function listitem = createListItemWithRadioButton(this, group, propid, id, value)
            listitem = matlab.ui.internal.toolstrip.ListItemWithRadioButton(group, getString(this, [propid id]));
            listitem.Value = value;
            listitem.ValueChangedFcn = @(h, ev) radioPropertyCallback(this, propid, id, ev);
            saveWidget(this, listitem, [propid id]);
        end
        
        function listitem = createListItemWithPopup(this, id, varargin)
            listitem = matlab.ui.internal.toolstrip.ListItemWithPopup(getString(this, id));
            addItemsToWidget(listitem, varargin{:});
            saveWidget(this, listitem, id);
        end
        
        function listitem = createListItemWithPopupRadioList(this, id, values, default)
            items = cell(size(values));
            group = matlab.ui.internal.toolstrip.ButtonGroup;
            for indx = 1:numel(items)
                items{indx} = this.createListItemWithRadioButton(group, id, values{indx}, strcmp(default, values{indx}));
            end

            listitem = createListItemWithPopup(this, id, items{:});
            listitem.Text = getListItemWithPopupRadioListText(this, id, default);
        end

        function listitem = createListItemWithDynamicPopupRadioList(this, id, default, callback)
            listitem = createListItemWithPopup(this, id);
            listitem.Text = getListItemWithPopupRadioListText(this, id, default);
            listitem.DynamicPopupFcn = callback;
        end

        function popup = updateListItemWithPopupRadioList(this, id, values, default)
            items = cell(size(values));
            widgets = this.Widgets;
            group = matlab.ui.internal.toolstrip.ButtonGroup;
            for indx = 1:numel(items)
                wId = [id values{indx}];
                if isfield(widgets, wId)
                    items{indx} = widgets.(wId);
                    items{indx}.Text = getString(this, wId);
                else
                    items{indx} = this.createListItemWithRadioButton(group, id, values{indx}, strcmp(default, values{indx}));
                end
            end
            listitem = this.Widgets.(id);
            listitem.Text = getListItemWithPopupRadioListText(this, id, default);
            addItemsToWidget(listitem, items{:});
            popup = listitem.Popup;
        end

        function txt = getListItemWithPopupRadioListText(this, id, default)
            if ~isempty(default)
                default = getString(this, [id default], 'Text');
            end
            txt = sprintf('%s : %s', getString(this, id, 'Text'), default);
        end

        function notifyPropertyChanged(this, propName)
            notify(this, 'PropertyChanged', matlabshared.application.PropertyChangedEventData(propName));
        end
        
        function notifyButtonPressed(this, buttonName)
            notify(this, 'ButtonPressed', matlabshared.application.ButtonPressedEventData(buttonName));
        end
        
        function radioPropertyCallback(this, propName, propValue, ev)
            % Make sure the other widgets are set to false, the group
            % doesn't do it "in time"
            if ev.EventData.NewValue
                setRadioProperty(this, propName, propValue);
            end
        end
        
        function propertyCallback(this, propName, ev)
            if nargin > 2
                setProperty(this, propName, ev.EventData.NewValue);
            else
                notifyPropertyChanged(this, propName);
            end
        end
        
        function buttonCallback(this, buttonName)
            notifyButtonPressed(this, buttonName);
        end
        
        function saveWidget(this, widget, id)
            widget.Tag = id;
            w = this.Widgets;
            if isfield(w, id)
                w.(id) = [w.(id) widget];
            else
                w.(id) = widget;
            end
            this.Widgets = w;
        end
    end
end

function addItemsToWidget(widget, varargin)

% If optional items are passed, create a popuplist and populate
% it with the items passed.
if numel(varargin) > 0
    popup = matlab.ui.internal.toolstrip.PopupList;
    popup.Tag = [widget.Tag '.PopupList'];
    for indx = 1:numel(varargin)
        add(popup, varargin{indx});
    end
    widget.Popup = popup;
end

end

% [EOF]
