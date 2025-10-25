classdef AppContainerWindow < matlabshared.application.ApplicationWindow
    %

    %   Copyright 2020-2021 The MathWorks, Inc.
    properties (Dependent)
        Visible
    end

    properties (SetAccess = protected, Hidden)
        % GroupDocument
        %     Handle to the toolgroup document
        AppContainer;

        QuickAccessButtons = struct;
        QuickAccessListeners = struct;
        FigureGroups;
        ContainerBeingDestroyedListener
        PropertyChangedListener
        CloseRequestFunction
        LastSelectedChild;
        FirstStatusTag;
    end

    properties (Hidden)
        UIConfirmState = -1
        Debug = false
    end

    methods
        function this = AppContainerWindow(hApp)
            this@matlabshared.application.ApplicationWindow(hApp);
            this.FigureGroups = containers.Map;
        end

        function b = isValid(this)
            ac = this.AppContainer;
            b = isempty(ac) || ~isvalid(ac) || ac.State ~= matlab.ui.container.internal.appcontainer.AppState.TERMINATED;
        end

        function state = uiconfirm(this, text, title, buttons, default)
            this.UIConfirmState = -1;
            container = this.AppContainer;
            uiconfirm(container, text, title, 'Options', buttons, ...
                'CancelOption', default, 'CloseFcn', @this.onUIConfirmStateDialog);
            oldBusy = container.Busy;
            if oldBusy
                container.Busy = false;
            end
            waitfor(this, 'UIConfirmState');
            if oldBusy
                container.Busy = true;
            end

            state = this.UIConfirmState;
        end

        function errorMessage(this, text, title)
            uialert(this.AppContainer, text, title);
        end

        function vis = get.Visible(this)
            if isOpen(this)
                vis = this.AppContainer.Visible;
            else
                vis = false;
            end
        end

        function set.Visible(this, vis)
            if isOpen(this)
                if vis == this.AppContainer.Visible
                    return
                end
                this.AppContainer.Visible = vis;
            end
            if vis
                open(this);
            end
        end

        function b = isOpen(this)
            b = ~isempty(this.AppContainer);
        end

        function b = isComponentInSameLocation(this, comp1, comp2)
            b = getComponentTileIndex(this, comp1) == getComponentTileIndex(this, comp2);
        end

        function tileOccupancy = getTileOccupancy(~, varargin)
            tileOccupancy = cell(numel(varargin), 1);
            for index = 1:numel(varargin)
                tile = varargin{index};

                % Create the ID for each element in the tile
                if isempty(tile)
                    tileOccupancy{index} = struct('children', []);
                else
                    nComps = numel(tile);
                    ids = cell(nComps, 1);

                    % Create the ID for each element in the tile
                    for jndex = 1:nComps
                        ids{jndex} = sprintf('%s_%s', getDocumentGroupTag(tile(jndex)), getTag(tile(jndex)));
                    end

                    % Create the occupancy for the tile.
                    tileOccupancy{index} = struct('children', struct('id', ids', 'showOrder', num2cell(0:nComps-1)), 'showingChildId', ids{1});
                end
            end
        end

        function open(this, visible)
            container = this.AppContainer;
            if nargin < 2
                visible = true;
            end
            if ~isempty(container)
                container.Visible = visible;
                return;
            end
            hApp = this.Application;
            persistent instanceCount;
            if isempty(instanceCount)
                instanceCount = 0;
            else
                instanceCount = instanceCount + 1;
            end
            % Make a unique tag by counting every instance launched, this
            % is necessary to not confuse the AppContainer interface
            pvPairs = getAppContainerProperties(hApp);
            pvPairs = [{'CanCloseFcn', @this.onCloseRequest, ...
                'Title', getTitle(hApp), ...
                'Tag', sprintf('%s_%d', getTag(hApp), instanceCount), ...
                'EnableTheming', useMatlabTheme(hApp)} pvPairs];
            position = getDefaultPosition(hApp);
            if this.Debug
                container = matlab.ui.container.internal.AppContainer_Debug(pvPairs{:});
            else
                container = matlab.ui.container.internal.AppContainer(pvPairs{:});
            end
            this.AppContainer = container;
            this.ContainerBeingDestroyedListener = event.listener(container, ...
                'ObjectBeingDestroyed', @this.onContainerBeingDestroyed);
            this.PropertyChangedListener = event.listener(container, ...
                'PropertyChanged', @this.onAppContainerPropertyChanged);
            notify(hApp, 'ApplicationConstructed');

            if ~isempty(hApp.Toolstrip)
                container.add(hApp.Toolstrip);
            end

            components = getDefaultComponents(hApp);

            qab = this.QuickAccessButtons;
            btns = fieldnames(qab);
            for indx = 1:numel(btns)
                container.addQabControl(qab.(btns{indx}));
            end
            %             if ~hApp.usingWebFigures
            %                 for indx = 1:numel(components)
            %                     toolGroup.addFigure(components(indx).Figure);
            %                 end
            %             end

            createComponentKeyPressListener(hApp);
            createStatusItems(hApp);

            container.WindowBounds = position;

            % Make the AppContainer visible.
            container.Visible = visible;
        end

        function attachCloseRequest(this, fcn)
            this.CloseRequestFunction = fcn;
        end


        function b = isDocked(~, ~)
            b = true;
        end

        function addComponent(~, c, ~)
            if ~isPanel(c) && ~isempty(c.Document)
                c.Document.Visible = true;
            end
        end

        function removeComponent(this, c)
            if ~isempty(c.Document)
                if isPanel(c)
                    removePanel(this, c.Document);
                else
                    removeDocument(this, c.Document);
                end
            end
        end

        function hideComponent(~, c)
            if isempty(c.Document)
                c.Figure.Visible = false;
            else
                c.Document.Visible = false;
            end
        end

        function showComponent(~, c)
            if isempty(c.Document)
                c.Figure.Visible = true;
            else
                c.Document.Visible = true;
            end
        end

        function focusOnComponent(this, comp, force)
            selection = struct( ...
                'tag', getTag(comp), ...
                'title', getName(comp), ...
                'documentGroupTag', getDocumentGroupTag(comp));
            ac = this.AppContainer;
            if nargin > 2 && force || ~isequal(ac.SelectedChild, selection)
                this.AppContainer.SelectedChild = selection;
            end
        end

        function hWebWindow = getWebWindow(this)
            appContainer = this.AppContainer;

            % Get all the web windows
            wwm = matlab.internal.webwindowmanager.instance;
            ww = wwm.windowList;
            if isempty(ww)
                hWebWindow = [];
                return;
            end

            % The webwindow for the container should match exactly with the
            % appcontainer's Title.
            wwIndex = find(strcmp({ww.Title}, appContainer.Title));

            % Default to the struct method if we can't find via title
            if isempty(wwIndex)
                i = matlabshared.application.IgnoreWarnings('MATLAB:structOnObject');
                s = struct(appContainer);
                hWebWindow = s.Window;
            else
                hWebWindow = ww(wwIndex(1));
            end
        end

        function [x, y, w, h] = getPosition(this)
            x = this.AppContainer.WindowBounds;
            if nargout > 1
                y = x(2);
                w = x(3);
                h = x(4);
                x = x(1);
            end
        end
        function pixelRatio = getPixelRatio(~)
            % Information from the appcontainer already has pixel ratio
            % applied.
            pixelRatio = 1;
        end
        function pos = getCenterPosition(this, sz)
            pos = matlabshared.application.getCenterPosition(sz, this.AppContainer);
        end

        function b = onCloseRequest(this, ~, ~)
            fcn = this.CloseRequestFunction;
            if isempty(fcn)
                b = true;
            else
                b = fcn();
            end
        end

        function onContainerBeingDestroyed(this, ~, ~)
            close(this.Application);
        end

        function addQabButton(this, id, callback, varargin)
            allQab = this.QuickAccessButtons;
            import matlab.ui.internal.toolstrip.*;
            varargin = [{'ButtonPushedFcn', callback} varargin];
            switch id
                case 'undo'
                    varargin = [{'Text', getString(message('MATLAB:toolstrip:qab:undoLabel')), ...
                        'Description', getString(message('MATLAB:toolstrip:qab:undoDescription'))}, ...
                        'Enabled', false, ...
                        varargin];
                    btn = qab.QABPushButton(Icon('undo'));
                case 'redo'
                    varargin = [{'Text', getString(message('MATLAB:toolstrip:qab:redoLabel')), ...
                        'Description', getString(message('MATLAB:toolstrip:qab:redoDescription'))}, ...
                        'Enabled', false, ...
                        varargin];
                    btn = qab.QABPushButton(Icon('redo'));
                case 'help'
                    varargin = [{'Text', getString(message('MATLAB:toolstrip:qab:helpLabel')), ...
                        'Description', getString(message('MATLAB:toolstrip:qab:helpDescription'))}, ...
                        varargin];
                    btn = qab.QABPushButton(Icon('help'));
                case 'save'
                    varargin = [{'Text', getString(message('Spcuilib:application:SaveText'))} varargin];
                    btn = qab.QABPushButton(Icon('unsaved'));
                case 'cut'
                    varargin = [{'Text', getString(message('Spcuilib:application:Cut'))} varargin];
                    btn = qab.QABPushButton(Icon('cut'));
                case 'copy'
                    varargin = [{'Text', getString(message('Spcuilib:application:Copy'))} varargin];
                    btn = qab.QABPushButton(Icon('copy'));
                case 'paste'
                    varargin = [{'Text', getString(message('Spcuilib:application:Paste'))} varargin];
                    btn = qab.QABPushButton(Icon('paste'));
                otherwise
                    btn = qab.QABPushButton;
            end
            for indx = 1:2:numel(varargin)
                btn.(varargin{indx}) = varargin{indx+1};
            end
            % If the app container is present, add the qab, otherwise defer
            appcontainer = this.AppContainer;
            if ~isempty(appcontainer)
                appcontainer.addQabControl(btn);
            end
            allQab.(id) = btn;
            this.QuickAccessButtons = allQab;
        end

        function setQabEnabled(this, id, state)
            if strcmp(id, 'help')
                return;
            end
            btns = this.QuickAccessButtons;
            if isfield(btns, id)
                btns.(id).Enabled = state;
            end
        end

        function setQabIcon(this, id, icon)
            if strcmpi(id, {'undo', 'redo', 'help'})
                return;
            end
            btns = this.QuickAccessButtons;
            if isfield(btns, id)
                btns.(id).Icon = icon;
            end
        end

        function setQabName(this, id, name)
            if any(strcmpi(id, {'undo', 'redo'}))
                return; % cannot set undo/redo
            end
            btns = this.QuickAccessButtons;
            if isfield(btns, id)
                btns.(id).Text = name;
            end
        end

        function setQab(this, id, varargin)
            btns = this.QuickAccessButtons;
            if isfield(btns, id)
                btn = btns.(id);
                for indx = 1:2:numel(varargin)
                    if strcmp(varargin{indx}, 'Icon')
                        btn.Icon = matlab.ui.internal.toolstrip.Icon(varargin{indx + 1});
                    else
                        btn.(varargin{indx}) = varargin{indx + 1};
                    end
                end
            end
        end

        function b = enableQabNaming(this, varargin)
            b = true;
        end

        function setStatus(this, statusText, element)
            container = this.AppContainer;
            if isempty(container)
                return;
            end
            bar = getStatusBar(container);
            if isempty(bar)
                bar = matlab.ui.internal.statusbar.StatusBar;
                bar.Tag = 'MainStatus';
                addStatusBar(container, bar);
            end
            if nargin < 3
                element = this.FirstStatusTag;
                if isempty(element)
                    element = '1';
                    this.FirstStatusTag = element;
                end
            elseif isempty(this.FirstStatusTag)
                this.FirstStatusTag = element;
            end
            status = getStatusComponent(container, element);
            if isempty(status)
                status = matlab.ui.internal.statusbar.StatusLabel;
                status.Tag = element;
                addStatusComponent(container, status);
                add(bar, status);
            end
            status.Text = statusText;
        end

        function status = getStatus(this, element)
            if nargin < 2
                element= this.FirstStatusTag;
            end
            status = getStatusComponent(this.AppContainer, element);
            status = status.Text;
        end

        function updateTitle(this)
            container = this.AppContainer;
            if ~isempty(container)
                container.Title = getTitle(this.Application);
            end
        end

        function close(this)
            this.ContainerBeingDestroyedListener = [];
            this.PropertyChangedListener = [];
            initializeClose(this.Application);
            finalizeClose(this.Application);
        end

        function delete(this)
            container = this.AppContainer;
            if isempty(container) || container.State == matlab.ui.container.internal.appcontainer.AppState.TERMINATED
                return;
            end
            delete(container);
        end

        function w = freezeUserInterface(this)
            ac = this.AppContainer;

            % If this is called before the application window is open,
            % simply return to avoid hang or an error.
            if isempty(ac)
                w = [];
                return;
            end
            oldBusy = ac.Busy;
            ac.Busy = true;
            w = onCleanup(@() setACWaiting(ac, oldBusy));
        end

        function name = getApplicationName(this)
            name = this.AppContainer.Tag;
        end
    end

    methods (Hidden)

        function onUIConfirmStateDialog(this, ~, e)
            this.UIConfirmState = e.SelectedOption;
        end

        function addDocument(this, component, tile)
            newDoc = component.Document;
            newDoc.AddWithoutWindowFocus = getAddComponentWithoutWindowFocus(this.Application, component);
            container = this.AppContainer;
            if nargin > 2
                newDoc.Tile = tile;
            end
            addDocument(container, newDoc);
        end

        function removeDocument(this, oldDoc)
            % closeDocument will hang when phantom is true,
            if isvalid(oldDoc) && oldDoc.Visible
                % Remove any can close function to ensure its not called.
                % If it is being removed programatically, then there's no
                % need to check.
                oldDoc.CanCloseFcn = [];
                this.AppContainer.closeDocument(oldDoc.DocumentGroupTag, oldDoc.Tag);
            end
        end

        function addPanel(this, newPanel)
            addPanel(this.AppContainer, newPanel);
        end

        function removePanel(this, oldPanelOrTagOrTitle)
            if ~isstring(oldPanelOrTagOrTitle) && isvalid(oldPanelOrTagOrTitle)
                removePanel(this.AppContainer, oldPanelOrTagOrTitle.Tag);
            else
                removePanel(this.AppContainer, oldPanelOrTagOrTitle);
            end
        end

        function group = getDocumentGroup(this, tag)
            groups = this.FigureGroups;
            if isKey(groups, tag)
                group = groups(tag);
            else
                group = matlab.ui.internal.FigureDocumentGroup();
                group.Tag = tag;
                group.Title = getDocumentGroupTitle(this.Application, tag);
                groups(tag) = group; %#ok<*NASGU>
                this.AppContainer.add(group);
            end
        end

        function b = hasDocumentGroup(this, tag)
            b = isKey(this.FigureGroups, tag);
        end

        function addDocumentGroup(this, group)
            groups = this.FigureGroups;
            groups(group.Tag) = group;
            this.AppContainer.add(group);
        end

        function tile = getComponentTileIndex(this, comp)
            if isempty(comp)
                id = '';
            else
                id = getTileOccupancyId(comp);
            end
            layout = this.AppContainer.DocumentLayout;
            if isfield(layout, 'tileOccupancy')
                tiles = layout.tileOccupancy;
            else
                tiles = [];
            end
            for tile = 1:numel(tiles)
                for cndx = 1:numel(tiles(tile).children)
                    if strcmp(tiles(tile).children(cndx).id, id)
                        return;
                    end
                end
            end
            tile = [];
        end

        function moveComponentToTile(this, comp, tileIndex)
            id = getTileOccupancyId(comp);
            layout = this.AppContainer.DocumentLayout;
            tiles = layout.tileOccupancy;
            [tiles, tile] = removeId(tiles);

            if iscell(tiles(tileIndex).children)
                tiles(tileIndex).children{end+1} = tile;
            else
                tiles(tileIndex).children = {tiles(tileIndex).children tile};
            end

            this.AppContainer.DocumentLayout.tileOccupancy = tiles;

            function [tiles, tile] = removeId(tiles)

                for tndx = 1:numel(tiles)
                    children = tiles(tndx).children;
                    for cndx = 1:numel(children)
                        if iscell(children)
                            child = children{cndx};
                        else
                            child = children(cndx);
                        end
                        cId = child.id;
                        if strcmp(cId, id)
                            tile = child;
                            tiles(tndx).children(cndx) = [];
                            if strcmp(tiles(tndx).showingChildId, id)
                                if iscell(children)
                                    showingId = children{1}.id;
                                else
                                    showingId = children(1).id;
                                end
                                tiles(tndx).showingChildId = showingId;
                            end
                            return
                        end
                    end
                end
            end
        end

        function l = createGroupActionListener(this, callback)
            l = event.listener(this.ToolGroup, 'GroupAction', callback);
        end

        function onAppContainerPropertyChanged(this, h, ~)
            last    = this.LastSelectedChild;
            current = h.SelectedChild;
            if ~isequal(last, current)
                if ~isempty(last)
                    blur = getComponentByTag(this.Application, last.tag);
                    if ~isempty(blur)
                        onBlur(blur);
                    end
                end
                focus = [];
                if isfield(current, 'tag')
                    focus = getComponentByTag(this.Application, current.tag);
                end
                if isempty(focus)
                    return;
                end
                onFocus(focus);
                this.LastSelectedChild = current;
            end
        end
    end
end

function setACWaiting(ac, busy)
if isvalid(ac)
    ac.Busy = busy;
end
end

% [EOF]
