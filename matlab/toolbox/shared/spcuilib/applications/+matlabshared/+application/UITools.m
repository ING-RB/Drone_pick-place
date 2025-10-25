classdef UITools < handle
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    methods (Access = protected)
        function [label, edit] = createLabelEditPair(this, fig, tag, varargin)
            
            useUIC = useUIControls(this);

            if ~useUIC
                label = createLabel(this, fig, tag);
            end
            edit  = createEditbox(this, fig, tag, varargin{:});
            if useUIC
                label = createLabel(this, fig, tag, 'Visible', edit.Visible);
            else
                label.Visible = edit.Visible;
            end
            if nargout < 2
                this.(['h' tag]) = edit;
            end
            if nargout < 1
                this.(['h' tag 'Label']) = label;
            end
        end
        
        function label = createLabel(this, fig, tag, varargin)
            useUIC = useUIControls(this);
            if useUIC
                if matlab.ui.internal.isUIFigure(ancestor(fig, 'figure'))
                    varargin = [{'FontName', 'Helvetica', 'FontUnits', 'pixels', 'FontSize', 11} varargin];
                end
                label = uicontrol(fig, ...
                    'Style', 'text', ...
                    'HorizontalAlignment', 'left', ...
                    'Tag', [getWidgetTagPrefix(this) tag 'Label'], ...
                    'String', getLabelString(this, tag), varargin{:});
            else
                label = uilabel(fig, ...
                    'FontName', 'Helvetica', ...
                    'FontSize', 11, ...
                    'HorizontalAlignment', 'left', ...
                    'Tag', [getWidgetTagPrefix(this) tag 'Label'], ...
                    'Text', getLabelString(this, tag), varargin{:});
            end
        end
        
        function edit = createEditbox(this, fig, tag, callback, type, varargin)
            useUIC = useUIControls(this);
            if nargin > 3 && ischar(callback)
                varargin = [{callback type} varargin];
                callback = [];
                type = 'edit';
            elseif rem(numel(varargin), 2) == 1
                varargin = [{type} varargin];
                type = 'edit';
            elseif nargin < 5
                type = 'edit';
            end
            pvPairs = {};

            if strcmp(type, 'table')
                edit = uitable(fig, ...
                    'ColumnEditable', true, ...
                    'CellEditCallback', callback, varargin{:});
            else
                if any(strncmp(type, {'listbox', 'popupmenu'}, numel(type)))
                    pvPairs = {'String', {' '}, 'Value', 1};
                    if nargin < 4 || isempty(callback)
                        callback = @this.defaultPopupCallback;
                    end
                    if ~useUIC
                        edit = uidropdown(fig, ...
                            'ValueChangedFcn', callback, ...
                            'Tag', [getWidgetTagPrefix(this) tag], ...
                            'Items', {' '}, ...
                            'Value', ' ', ...
                            varargin{:});
                    end
                elseif strncmp(type, 'radio', numel(type))
                    if useUIC
                        pvPairs = {'String', getLabelString(this, tag)};
                        if nargin < 4 || isempty(callback)
                            callback = @this.defaultRadioCallback;
                        end
                    else
                        if ~isa(fig, 'matlab.ui.container.ButtonGroup')
                            if nargin < 4 || isempty(callback)
                                callback = @this.defaultRadioCallback;
                            end
                            fig = matlab.ui.container.ButtonGroup('Parent', fig);
                            fig.SelectionChangedFcn = callback;
                        end
                        edit = uiradiobutton(fig, ...
                            'Text', getLabelString(this, tag));
                    end
                else
                    % Must be an editbox
                    if nargin < 4 || isempty(callback)
                        callback = @this.defaultEditboxCallback;
                    end
                    if ~useUIC
                        edit = uieditfield(fig, ...
                            'FontName', 'Helvetica', ...
                            'FontSize', 11, ...
                            'HorizontalAlignment', 'left', ...
                            'ValueChangedFcn', callback, ...
                            'Tag', [getWidgetTagPrefix(this) tag], ...
                            varargin{:});
                    end
                end
                if useUIC
                    if matlab.ui.internal.isUIFigure(ancestor(fig, 'figure'))
                        pvPairs = [{'FontName', 'Helvetica', 'FontUnits', 'pixels', 'FontSize', 11} pvPairs];
                    end
                    edit = uicontrol(fig, ...
                        'HorizontalAlignment', 'left', ...
                        'Callback', callback, ...
                        'Tag', [getWidgetTagPrefix(this) tag], ...
                        'Style', type, ...
                        pvPairs{:}, varargin{:});
                end
            end
            if nargout < 1
                this.(['h' tag]) = edit;
            end
        end
        
        function varargout = createPushButton(this, parent, tag, callback, varargin)
            useUIC = useUIControls(this); %matlab.ui.internal.isUIFigure(ancestor(parent, 'figure'));
            % Callback is required
            if useUIC
                button = uicontrol(parent, ...
                    'Style', 'pushbutton', ...
                    'Callback', callback, ...
                    'Tag', [getWidgetTagPrefix(this) tag], ...
                    varargin{:});
            else
                button = uibutton(parent, ...
                    'ButtonPushedFcn', callback, ...
                    'FontName', 'Helvetica', ...
                    'FontSize', 11, ...
                    'Tag', [getWidgetTagPrefix(this) tag], ...
                    varargin{:});
                  
            end
            if nargout > 0
                varargout = {button};
            else
                this.(['h' tag]) = button;
            end
        end
        
        function check = createCheckbox(this, parent, tag, callback, varargin)
            useUIC = useUIControls(this);
            if nargin > 3 && ischar(callback)
                varargin = [{callback} varargin];
                callback = @this.defaultCheckboxCallback;
            elseif nargin < 4
                callback = @this.defaultCheckboxCallback;
            end
            if useUIC
                check = uicontrol(parent, ...
                    'Style', 'checkbox', ...
                    'Tag', [getWidgetTagPrefix(this) tag], ...
                    'String', getLabelString(this, tag), ...
                    'Callback', callback, varargin{:});
            else
                check = uicheckbox(parent, ...
                    'Tag', [getWidgetTagPrefix(this) tag], ...
                    'Text', getLabelString(this, tag), ...
                    'ValueChangedFcn', callback, varargin{:});
            end
            if nargout < 1
                this.(['h' tag]) = check;
            end
        end
        
        function varargout = createToggleMenu(this, parent, tag, varargin)
            if iscell(tag)
                for indx = 1:numel(tag)
                    h(indx) = createToggleMenu(this, parent, tag{indx}, varargin{:}); %#ok<AGROW>
                    if nargout < 1
                        this.(['h', tag{indx}]) = h(indx);
                    end
                end
            else
                h = uimenu(parent, ...
                    'Tag', [getWidgetTagPrefix(this) tag], ...
                    'Callback', @this.toggleShowMenuCallback, ...
                    'Checked', this.(tag), ...
                    'Label', getLabelString(this, tag), ...
                    varargin{:});
                if nargout < 1
                    this.(['h' tag]) = h;
                end
            end
            
            if nargout > 0
                varargout = {h};
            end
        end
        
        function updateToggleMenu(this, tags, menus)
            for indx = 1:numel(tags)
                if nargin > 2
                    menu = findobj(menus, 'tag', tags{indx});
                else
                    menu = this.(['h' tags{indx}]);
                end
                menu.Checked = this.(tags{indx});
            end
        end
        
        function h = createToggle(this, parent, tag, varargin)
            
            if matlab.ui.internal.isUIFigure(ancestor(parent, 'figure'))
                h = uipanel('Parent', parent, ...
                    'BorderType', 'none', ...
                    'Units', 'pixels', ...
                    'AutoResizeChildren', 'off', ...
                    'Tag', [getWidgetTagPrefix(this) tag]);
                label = uicheckbox(h, ...
                    'FontSize', 11, ...
                    'Value', this.(tag), ...
                    'ValueChangedFcn', @this.toggleShowCallback, ...
                    'Text', getLabelString(this, tag), ...
                    'Tag', [getWidgetTagPrefix(this) tag 'Label'], ...
                    'Position', [1 1 400 17]);
                im = uiimage(h, ...
                    'ImageClickedFcn', @this.toggleShowCallback, ...
                    'Tag', [getWidgetTagPrefix(this) tag 'Image'], ...
                    'Position', [1 1 17 17]);
                setappdata(h, 'Value', this.(tag));
                setappdata(h, 'Image', im);
                setappdata(h, 'Label', label);
                for indx = 1:2:numel(varargin)
                    setappdata(h, varargin{indx:indx+1});
                end
                addlistener(ancestor(parent, 'figure'), 'ThemeChanged', @(~,~) matlabshared.application.setToggleCData(h));
            else
                h = uicontrol(parent, ...
                    'Style', 'checkbox', ...
                    'tag', [getWidgetTagPrefix(this) tag], ...
                    'String', getLabelString(this, tag), ...
                    'Callback', @this.toggleShowCallback, ...
                    'Value', this.(tag), ...
                    varargin{:});
            end
            matlabshared.application.setToggleCData(h);
            if nargout < 1
                this.(['h' tag]) = h;
            end
        end
        
        function setupWidgets(this, spec, names, enable, modifiers, propSuffix)
            if nargin < 6
                propSuffix = '';
            end
            if isempty(spec)
                enable = 'off';
            end
            useUIC = useUIControls(this);
            for indx = 1:numel(names)
                if isempty(spec)
                    if nargin < 5
                        value = '';
                    else
                        value = repmat(' ', numel(modifiers), 1);
                    end
                else
                    value = spec.([names{indx} propSuffix]);
                end
                if useUIC
                    if islogical(value)
                        prop = 'Value';
                    else
                        if nargin < 5 && ~isscalar(value)
                            value = mat2str(value);
                        end
                        prop = 'String';
                    end
                    if nargin < 5
                        set(this.(['h' names{indx}]), ...
                            prop, value, ...
                            'Enable', enable);
                    else
                        for jndx = 1:numel(modifiers)
                            set(this.(['h' names{indx} modifiers{jndx}]), ...
                                prop, value(jndx), ...
                                'Enable', enable);
                        end
                    end
                else
                    if ~islogical(value) && nargin < 5
                        value = mat2str(value);
                    end
                    if nargin < 5
                        set(this.(['h' names{indx}]), ...
                            'Value', value, ...
                            'Enable', enable);
                    else
                        for jndx = 1:numel(modifiers)
                            set(this.(['h' names{indx} modifiers{jndx}]), ...
                                'Value', value(jndx), ...
                                'Enable', enable);
                        end
                    end
                end
            end
        end
        
        function nextRow = insertPanel(this, layout, panelTag, nextRow, type)
            if nargin < 5
                type = '';
            end
            panel = this.(['h' type panelTag]);
            if this.(['Show' panelTag])
                if ~contains(layout, panel)
                    grid = layout.Grid;
                    if size(grid, 1) >= nextRow && any(~isnan(grid(nextRow, :)))
                        insert(layout, 'row', nextRow);
                    end
                    add(layout, panel, nextRow, [1 size(layout.Grid, 2)]);
                end
                nextRow = nextRow + 1;
                vis = 'on';
            else
                if contains(layout, panel)
                    remove(layout, panel);
                end
                vis = 'off';
            end
            panel.Visible = vis;
        end
        
        function setupPopup(this, widget, varargin)
            
            strings = cell(size(varargin));
            for indx = 1:numel(varargin)
                strings{indx} = getLabelString(this, [widget varargin{indx}]);
            end
            
            % Setup the string and cache the data.
            if useUIControls(this)
                set(this.(['h' widget]), 'String', strings, 'UserData', varargin);
            else
                set(this.(['h' widget]), 'Items', strings, 'UserData', varargin);
            end
        end
        
        function value = getToggleValue(this, prop)
            widget = this.(['h' prop]);
            if ishghandle(widget, 'uipanel')
                value = getappdata(widget, 'Value');
            else
                value = widget.Value;
            end
        end
        
        function setToggleValue(this, prop, value)
            widget = this.(['h' prop]);
            if ishghandle(widget, 'uipanel')
                setappdata(widget, 'Value', value);
            else
                widget.Value = value;
            end
        end
        
        % Can be overloaded by subclasses to switch to uilabel, uidropdown,
        % uieditfield, etc.
        function b = useUIControls(~)
            b = true; %~useAppContainer(this.Application); %
        end
        
        function b = usingWebFigure(~)
            b = matlabshared.application.usingWebFigures;
        end
    end
    
    methods (Hidden)
        function setPopupValue(this, property, value)
            
            if nargin < 3
                value = this.(property);
            end
            widget = this.(['h' property]);
            useUIC = useUIControls(this);
            validValues = get(widget, 'UserData');
            
            if useUIC
                % Should only be 1 match, but use first because we dont know
                % how this will be used
                index = find(strcmp(validValues, value), 1, 'first');
                widget.Value = index;
            else
                try
                    % index = find(strcmp(validValues, value), 1, 'first');
                    % widget.Value = widget.Items{index};
                    search_value = value(~isspace(value));
                    index = find(strcmp(validValues, search_value), 1, 'first');
                    widget.Value = widget.Items{index};
                catch ME
                    search_value = value(~isspace(value));
                    index = find(strcmp(validValues, search_value), 1, 'first');
                    widget.Value = widget.Items{index};
                    rethrow(ME)
                end
            end
        end
        
        function value = getPopupValue(this, property)
            widget = this.(['h' property]);
            value = widget.Value;
            validValues = get(widget, 'UserData');
            if ~useUIControls(this)
                value = find(strcmpi(value, widget.Items), 1, 'first');
            end
            if ~isempty(validValues) && iscellstr(validValues) %#ok<ISCLSTR>
                value = validValues{value};
            end
        end
        
        function toggleShowMenuCallback(this, hcbo, ~)
            prop = getPropertyFromTag(this, hcbo.Tag);
            newValue = ~this.(prop);
            this.(prop) = newValue;
            hcbo.Checked = newValue;
        end
        
        function toggleShowCallback(this, hcbo, ~)
            prop = getPropertyFromTag(this, hcbo.Tag);
            if ishghandle(hcbo, 'uiimage') || ishghandle(hcbo, 'uicheckbox')
                prop(end-4:end) = [];
                hcbo = hcbo.Parent;
                value = ~getappdata(hcbo, 'Value');
                this.(prop) = logical(value);
                setappdata(hcbo, 'Value', value);
            else
                this.(prop) = logical(hcbo.Value);
            end
            matlabshared.application.setToggleCData(hcbo);
            updateLayout(this);
        end
        
        function defaultRadioCallback(~, ~, ~)
            % NO OP, not enough info to implement a default callback.
        end
        
        function defaultEditboxCallback(this, hcbo, ~)
            this.(getPropertyFromTag(this, hcbo.Tag)) = hcbo.String;
        end
        
        function defaultCheckboxCallback(this, hcbo, ~)
            this.(getPropertyFromTag(this, hcbo.Tag)) = logical(hcbo.Value);
        end
        
        function defaultPopupCallback(this, hcbo, ~)
            prop = getPropertyFromTag(this, hcbo.Tag);
            this.(prop) = getPopupValue(this, prop);
        end
        
        function updateLayout(~)
            % NO OP
        end
        
        function prop = getPropertyFromTag(~, tag)
            prop = tag;
        end
    end
    
    methods (Access = protected)
        

        function str = getLabelString(~, tag)
            str = tag;
        end
        
        function prefix = getWidgetTagPrefix(~)
            prefix = '';
        end
    end
    
    methods (Static)
        function num = strToNum(str)
            % Convert string to number without using str2num
            str = string(str);
            str = str.replace("[","");
            str = str.replace("]","");
            % Converting to a matrix is not supported
            str = str.replace(";"," ");
            str = str.replace(","," ");
            str = strtrim(str);
            if str == ""
                num = [];
            else
                num = double(split(str))';
            end
        end
    end
end

% [EOF]
