classdef UITools2 < handle
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    methods (Access = protected)
        function [label, edit] = createLabelEditPair(this, fig, tag, varargin)
            
            label = createLabel(this, fig, tag);
            edit  = createEditbox(this, fig, tag, varargin{:});
            label.Visible = edit.Visible;
            
            if nargout < 2
                this.(['h' tag]) = edit;
            end
            if nargout < 1
                this.(['h' tag 'Label']) = label;
            end
        end
        
        function label = createLabel(this, fig, tag, varargin)
            label = uilabel(fig, ...
                'HorizontalAlignment', 'left', ...
                'Tag', [tag 'Label'], ...
                'Text', getLabelString(this, tag), varargin{:});
        end
        
        function edit = createEditbox(this, fig, tag, callback, type, varargin)
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
            
            if strcmp(type, 'table')
                edit = uitable(fig, ...
                    'ColumnEditable', true, ...
                    'CellEditCallback', callback, varargin{:});
            else
                if any(strncmp(type, {'listbox', 'popupmenu'}, numel(type)))
                    if nargin < 4 || isempty(callback)
                        callback = @this.defaultPopupCallback;
                    end
                    edit = uidropdown(fig, ...
                        'ValueChangedFcn', callback, ...
                        'Tag', tag, ...
                        'Items', {' '}, ...
                        'Value', ' ', ...
                        varargin{:});
                elseif strncmp(type, 'radio', numel(type))
                    if ~isa(fig, 'matlab.ui.container.ButtonGroup')
                        if nargin < 4 || isempty(callback)
                            callback = @this.defaultRadioCallback;
                        end
                        fig = matlab.ui.container.ButtonGroup('Parent', fig);
                        fig.SelectionChangedFcn = callback;
                    end
                    edit = uiradiobutton(fig, ...
                        'Text', getLabelString(this, tag));
                else
                    % Must be an editbox
                    if nargin < 4 || isempty(callback)
                        callback = @this.defaultEditboxCallback;
                    end
                    edit = uieditfield(fig, ...
                        'HorizontalAlignment', 'left', ...
                        'ValueChangedFcn', callback, ...
                        'Tag', tag, ...
                        varargin{:});
                end
            end
            if nargout < 1
                this.(['h' tag]) = edit;
            end
        end
        
        function check = createCheckbox(this, parent, tag, callback, varargin)
            if nargin > 3 && ischar(callback)
                varargin = [{callback} varargin];
                callback = @this.defaultCheckboxCallback;
            elseif nargin < 4
                callback = @this.defaultCheckboxCallback;
            end
            check = uicheckbox(parent, ...
                'Tag', tag, ...
                'Text', getLabelString(this, tag), ...
                'ValueChangedFcn', callback, varargin{:});
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
                    'Tag', tag, ...
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
            
            h = uipanel('Parent', parent, ...
                'BorderType', 'none', ...
                'Units', 'pixels', ...
                'Tag', tag);
            label = uicheckbox(h, ...
                'Value', this.(tag), ...
                'ValueChangedFcn', @this.toggleShowCallback, ...
                'Text', getLabelString(this, tag), ...
                'Tag', [tag 'Label'], ...
                'Position', [1 1 200 17]);
            im = uiimage(h, ...
                'ImageClickedFcn', @this.toggleShowCallback, ...
                'Tag', [tag 'Image'], ...
                'Position', [1 1 17 17]);
            setappdata(h, 'Value', this.(tag));
            setappdata(h, 'Image', im);
            setappdata(h, 'Label', label);
            for indx = 1:2:numel(varargin)
                setappdata(h, varargin{index:index+1});
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
                if islogical(value)
                else
                    if nargin < 5
                        value = mat2str(value);
                    end
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
            set(this.(['h' widget]), 'String', strings, 'UserData', varargin);
        end
        
        function setToggleValue(this, prop, value)
            widget = this.(['h' prop]);
            if ishghandle(widget, 'uipanel')
                setappdata(widget, 'Value', value);
            else
                widget.Value = value;
            end
        end
    end
    
    methods (Hidden)
        function setPopupValue(this, property, value)
            
            if nargin < 3
                value = this.(property);
            end
            widget = this.(['h' property]);
            widget.Value = value;
        end
        
        function value = getPopupValue(this, property)
            widget = this.(['h' property]);
            value = widget.Value;
        end
        
        function toggleShowMenuCallback(this, hcbo, ~)
            newValue = ~this.(hcbo.Tag);
            this.(hcbo.Tag) = newValue;
            hcbo.Checked = newValue;
        end
        
        function toggleShowCallback(this, hcbo, ~)
            hcbo = hcbo.Parent;
            value = ~getappdata(hcbo, 'Value');
            this.(hcbo.Tag) = logical(value);
            setappdata(hcbo, 'Value', value);
            matlabshared.application.setToggleCData(hcbo);
            updateLayout(this);
        end
        
        function defaultRadioCallback(~, ~, ~)
            % NO OP, not enough info to implement a default callback.
        end
        
        function defaultEditboxCallback(this, hcbo, ~)
            this.(hcbo.Tag) = hcbo.String;
        end
        
        function defaultCheckboxCallback(this, hcbo, ~)
            this.(hcbo.Tag) = logical(hcbo.Value);
        end
        
        function defaultPopupCallback(this, hcbo, ~)
            prop = hcbo.Tag;
            this.(prop) = getPopupValue(this, prop);
        end
        
        function updateLayout(~)
            % NO OP
        end
    end
    
    methods (Access = protected)
        function str = getLabelString(~, tag)
            str = tag;
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
