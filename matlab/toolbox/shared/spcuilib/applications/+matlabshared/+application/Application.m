classdef Application < handle
    %Application   Define the Application class.

    %   Copyright 2016-2021 The MathWorks, Inc.

    properties (SetAccess = protected, Hidden)

        ActionsCache = struct;
        Toolstrip;

        KeyPressList = struct('key', {}, 'modifier', {}, 'callback', {});

        CallbackQueue = {};
        IsLaunching = false;
        ForceAppContainer = false;
        Window
    end

    properties (Dependent, Hidden)
        % Remove when everyone updates
        ToolGroup;
        Visible
    end

    properties(Hidden)
        % CurrentHover
        %     Handle to the object currently hovering on
        Components;
        CurrentHover
        VisibleAtOpen = true;
        IsClosing     = false;
        IsWindowDeleting = false;
    end

    properties (Access = protected)
        KeyPressListener;
        IsBusy = false;
        Icons
    end

    events
        ApplicationConstructed
        ToolGroupConstructed
        ApplicationBeingDestroyed
        ToolGroupBeingDestroyed
        ApplicationClosing
        ApplicationHiding
        ApplicationOpened
        ComponentActivated
    end

    methods

        function this = Application(varargin)
            %Application   Construct the Application class.
            this.parseInputs(varargin{:});
            % Save the application in a persistent cache to avoid MATLAB
            % performance issues with this object stored in callbacks.
            % This is a temporary fix until root cause can be investigated
            % and fixed by MATLAB.
            this.Window    = createWindow(this);

            addQabButton(this, 'help', @this.helpCallback);
            setQabEnabled(this, 'help', true);

            actionsCache = this.ActionsCache;
            fields = fieldnames(actionsCache);
            for indx = 1:numel(fields)
                addQabButton(this, fields{indx}, actionsCache.(fields{indx}){:});
            end

            matlabshared.application.InstanceCache.add(getTag(this),this);
        end

        function set.Visible(this, vis)
            if ~vis
                notify(this, 'ApplicationHiding');
            end
            this.Window.Visible = vis;
        end

        function vis = get.Visible(this)
            vis = this.Window.Visible;
        end

        function t = get.ToolGroup(this)
            r = this.Window;
            if isempty(r)
                t = [];
            else
                t = r.ToolGroup;
            end
        end

        function set.ToolGroup(this, tg)
            % For WWG
            this.Window.ToolGroup = tg;
        end

        function open(this, varargin)
            this.IsLaunching = true;
            if isempty(this.Toolstrip) || isstruct(this.Toolstrip)
                this.Toolstrip = createToolstrip(this);
            end
            open(this.Window, varargin{:});
            this.VisibleAtOpen = this.Visible;

            updateComponents(this);

            this.IsLaunching = false;

            notify(this, 'ApplicationOpened');
        end

        function addComponent(this, newComponent, docked)
            if nargin < 3
                docked = true;
            end
            this.Components(end+1) = newComponent;
            if useAppContainer(this) && isDocked(newComponent)
                needsFigure = isempty(newComponent.Document);
            else
                needsFigure = isempty(newComponent.Figure) || ~ishghandle(newComponent.Figure);
            end
            if needsFigure
                initializeFigure(newComponent);
            end
            addComponent(this.Window, newComponent, docked);
        end

        function removeComponent(this, component)
            this.Components = setdiff(this.Components, component);
            removeComponent(this.Window, component);
        end

        function hideComponent(this, component)
            hideComponent(this.Window, component);
        end

        function showComponent(this, component)
            showComponent(this.Window, component);
        end

        function close(this)
            % Make sure tests work properly, if close is called twice it
            % used to not error.
            if isvalid(this) && ~this.IsClosing
                this.IsClosing = true;
                close(this.Window);
            end
        end

        function delete(this)
            %delete

            % If delete is called directly instead of close, make sure
            this.IsClosing = true;
            w = this.Window;
            if isscalar(w) && isvalid(w) && isOpen(w)
                if useAppContainer(this)
                    w.Visible = false;
                end
                try
                    initializeClose(this);
                catch ME %#ok
                end
            end

            % Make sure all the components are notified to shut down.
            components = this.Components;
            for indx = 1:numel(components)
                if ~useAppContainer(this) || ~isDocked(components(indx))
                    delete(components(indx));
                end
            end

            if ~this.IsWindowDeleting
                delete(this.Window);
            end
            % Remove the cached application handle that was used to improve
            % performance.
            matlabshared.application.InstanceCache.remove(getTag(this),this);
        end

        function removeInvalidComponents(this)
            components = this.Components;
            indx = 1;
            % Loop over the current components and if any of the objects
            % are deleted, remove it from the vector and resave.
            while indx <= numel(components)
                if isvalid(components(indx))
                    indx = indx + 1;
                else
                    components(indx) = [];
                end
            end
            this.Components = components;
        end

        function b = isComponentInSameLocation(this, comp1, comp2)
            b = isComponentInSameLocation(this.Window, comp1, comp2);
        end

        function t = getTitle(this)
            t = getName(this);
        end

        function n = getName(~)
            n = 'Application';
        end

        function t = getTag(this)
            % Clients must implement a unique application tag
            t = strrep(getName(this), ' ', '');
        end

        function w = freezeUserInterface(this)
            r = this.Window;
            if isempty(r)
                w = [];
            else
                w = freezeUserInterface(r);
            end
        end

        function set.ForceAppContainer(this, force)
            this.forceAppContainer(force);
        end

        function force = get.ForceAppContainer(this)
            force = this.forceAppContainer();
        end
    end

    methods (Hidden, Static)
        function b = usingWebFigures

            b = matlabshared.application.usingWebFigures;
        end

        function varargout = forceAppContainer(varargin)
            persistent forceFlag;
            if nargin
                forceFlag = varargin{1};
            end
            if nargout
                if isempty(forceFlag)
                    forceFlag = false;
                end
                varargout{1} = forceFlag;
            end
        end
    end

    methods (Hidden)

        function state = uiconfirm(this, varargin)
            state = uiconfirm(this.Window, varargin{:});
        end

        function errorMessage(this, text, title)
            if isa(text, 'MException')
                text = text.message;
            end
            errorMessage(this.Window, text, title);
        end
        
        function [b, product, appName] = shouldSupportDDUX(~)
            b = false;
            product = '';
            appName = ''; % Can't use getName as it is localized and getTag 1) has no spaces and 2) isnt enforced to be the app name
        end


        function t = getComponentTileIndex(this, comp)
            t = getComponentTileIndex(this.Window, comp);
        end

        function moveComponentToTile(this, comp, tile)
            moveComponentToTile(this.Window, comp, tile);
        end

        function pvPairs = getAppContainerProperties(this)
            [shouldDDUX, product, appName] = shouldSupportDDUX(this);
            if shouldDDUX
                pvPairs = {'Product', product, 'Scope', appName};
            else
                pvPairs = {};
            end
        end

        function s = saveobj(~)
            s = [];
        end

        function b = isOpen(this)
            r = this.Window;
            if isempty(r) || ~isvalid(r)
                b = false;
            else
                b = isOpen(r);
            end
        end

        function comp = getComponentByTag(this, tag)
            allComps = this.Components;
            for indx = 1:numel(allComps)
                if strcmp(allComps(indx).getTag(), tag)
                    comp = allComps(indx);
                    return
                end
            end
            comp = [];
        end

        function attachCloseRequest(this, fcn)
            attachCloseRequest(this.Window, fcn)
        end

        function focusOnComponent(this, varargin)
            focusOnComponent(this.Window, varargin{:});
        end

        function b = isDocked(this, comp)
            b = isDocked(this.Window, comp);
        end
        function varargout = getPosition(this)
            [varargout{1:nargout}] = getPosition(this.Window);
        end

        function pos = getCenterPosition(this, size)
            pos = getCenterPosition(this.Window, size);
        end

        function group = getDocumentGroup(this, tag)
            group = getDocumentGroup(this.Window, tag);
        end

        function title = getDocumentGroupTitle(~, tag)
            title = tag;
        end

        function dontFocus = getAddComponentWithoutWindowFocus(~, ~)
            dontFocus = true;
        end

        function addDocument(this, varargin)
            addDocument(this.Window, varargin{:});
        end

        function addDocumentGroup(this, varargin)
            addDocumentGroup(this.Window, varargin{:});
        end

        function b = hasDocumentGroup(this, tag)
            b = hasDocumentGroup(this.Window, tag);
        end

        function addPanel(this, newPanel)
            addPanel(this.Window, newPanel);
        end

        function removePanel(this, oldPanelOrTagOrTitle)
            removePanel(this.Window, oldPanelOrTagOrTitle);
        end

        function addToWindow(this, objToAdd)
            add(this.Window, objToAdd);
        end

        function components = getDefaultComponents(this)
            components = this.Components;
            if isempty(components)
                components = createDefaultComponents(this);
                this.Components = components;
            end
        end

        function icon = getIcon(this, name)
            icon = this.Icons;
            if isempty(icon)
                % toolboxdir returns the correct root folder irrespective
                % of whether it is running in Desktop or deployed mode
                icon = load(fullfile(toolboxdir(fullfile('shared','spcuilib')),'applications','+matlabshared','+application','icons.mat'));
                paths = getIconMatFiles(this);
                for indx = 1:numel(paths)
                    newIcons = load(paths{indx});
                    fn = fieldnames(newIcons);
                    for jndx = 1:numel(fn)
                        icon.(fn{jndx}) = newIcons.(fn{jndx});
                    end
                end
                this.Icons = icon;
            end
            if nargin > 1
                icon = icon.(name);
            end
        end

        function helpCallback(~, ~, ~)
            doc;
        end

        function cb = initCallback(this, rawcb, varargin)
            cb = @(h, ev) runCallback(this, rawcb, h, ev, varargin{:});
        end

        function runCallback(this, cb, varargin)
            if this.IsBusy
                % If the application is busy, it must be already in the
                % else.  Queue up this callback and return early.
                this.CallbackQueue{end+1} = [{cb} varargin];
                return;
            else
                this.IsBusy = true;

                % Call this callback
                cb(varargin{:});

                % If another callback has been added while the first was
                % being executed, execute the new one
                if isvalid(this)
                    while ~isempty(this.CallbackQueue)
                        info = this.CallbackQueue{1};
                        this.CallbackQueue(1) = [];
                        info{1}(info{2:end});
                    end
                    this.IsBusy = false;
                end
            end
        end

        function name = getApplicationName(this)
            name = getApplicationName(this.Window);
        end

        function addApplicationKeyPress(this, key, callback, modifier)
            %addToolGroupKeyPress add a keypress that is active on all the components
            if nargin < 4
                modifier = {};
            end
            this.KeyPressList(end+1) = struct(...
                'key', key, ...
                'modifier', {modifier}, ...
                'callback', callback);
            c = this.Components;
            if ~isempty(c) && isempty(this.KeyPressListener)
                createComponentKeyPressListener(this);
            end
        end

        function addQabButton(this, name, varargin)
            renderer = this.Window;
            if isempty(renderer)
                this.ActionsCache.(name) = varargin;
            else
                addQabButton(this.Window, name, varargin{:});
            end
        end

        function setQab(this, action, varargin)
            r = this.Window;
            if ~isempty(r)
                setQab(r, action, varargin{:});
            end
        end

        function setQabEnabled(this, action, state)
            r = this.Window;
            if ~isempty(r)
                setQabEnabled(r, action, state)
            end
        end

        function setQabIcon(this, action, icon)
            if ischar(icon) || isstring(icon)
                icon = matlab.ui.internal.toolstrip.Icon(icon);
            end
            r = this.Window;
            if ~isempty(r)
                setQabIcon(r, action, icon)
            end
        end

        function setQabName(this, action, name)
            r = this.Window;
            if ~isempty(r)
                setQabName(r, action, name);
            end
        end

        function b = enableQabNaming(this, varargin)
            r = this.Window;
            if isempty(r)
                b = false;
            else
                b = enableQabNaming(this.Window, varargin{:});
            end
        end

        function setStatus(this, varargin)
            setStatus(this.Window, varargin{:});
        end

        function status = getStatus(this, varargin)
            status = getStatus(this.Window, varargin{:});
        end

        % This method is hidden (instead of protected) so the Component
        % objects can call it to send their keypresses up to the app.
        function onComponentKeyPress(this, ~, ev)
            keyPressList = this.KeyPressList;
            for indx = 1:numel(keyPressList)
                key = keyPressList(indx);
                if isequal(sort(ev.Modifier), sort(key.modifier)) && ...
                        isequal(ev.Key, key.key)
                    key.callback();
                    return;
                end
            end
        end

        function updateTitle(this)
            r = this.Window;
            if ~isempty(r)
                updateTitle(r);
            end
        end

        function initializeClose(~)
            % NO OP
        end

        function finalizeClose(this)

            notify(this, 'ApplicationClosing');

            delete(this);
        end

        function callbackHandler(this, fcn, messageTarget)
            [msg, id] = lastwarn;
            w = warning('off');
            lastwarn('', '');
            try
                fcn();
            catch ME
                % Ignore any warning, just throw the error
                lastwarn(msg, id);
                warning(w);
                if nargin > 2
                    focusOnComponent(messageTarget);
                    messageTarget.errorMessage(ME.message, ME.identifier);
                end
                return
            end
            [newMsg, newId] = lastwarn;
            if ~isempty(newMsg) && ~any(strcmp(newId, getWarningIdsToIgnore(this))) && nargin > 2
                focusOnComponent(messageTarget);
                messageTarget.warningMessage(newMsg, newId);
            end
            lastwarn(msg, id);
            warning(w);
        end

        function createComponentKeyPressListener(this)
            if isempty(this.KeyPressList)
                return;
            end
            this.KeyPressListener = event.listener([this.Components.Figure], ...
                'KeyPress', @this.onComponentKeyPress);
        end

        function position = getDefaultPosition(this)
            position = [getDefaultLocation(this) getDefaultSize(this)];
        end

        function h = createCommandLineInterface(~)
            % Nothing by default.  This returns an object you want to
            % document, usually not the application.
            h = [];
        end

        function b = useAppContainer(this)
            b = matlabshared.application.usingWebFigures || this.forceAppContainer;
            persistent flagset
            if b && isempty(flagset)

                s = settings;
                s.matlab.ui.internal.uicontrol.UseRedirect.TemporaryValue = 1;
                s.matlab.ui.internal.uicontrol.UseRedirectInUifigure.TemporaryValue = 1;
                flagset = true;
            end
        end

        function b = useMatlabTheme(~)
            b = false;
        end

        % Backwards compatibility
        function name = getToolGroupName(this)
            name = getApplicationName(this);
        end

        function createStatusItems(~)
            % NO OP
        end
    end

    methods (Access = protected)

        function id = getWarningIdsToIgnore(~)
            id = {'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame'};
        end

        function r = createWindow(this)
            if useAppContainer(this)
                r = matlabshared.application.AppContainerWindow(this);
            else
                r = matlabshared.application.ToolGroupWindow(this);
            end
        end

        function p = getIconMatFiles(~)
            p = {};
        end

        function updateComponents(~)
            % Usually overloaded
        end

        function size = getDefaultSize(~)
            size = [1280 768];
        end

        function location = getDefaultLocation(this)
            size = getDefaultSize(this);
            room = get(0, 'ScreenSize');
            location = [room(3) - size(1) room(4) - size(2)] / 2;
        end

        function parseInputs(~, varargin)
        end

        function str = getDataBrowserTitle(~)
            str = '';
        end

        function h = createToolstrip(~)
            h = [];
        end

        function h = createDefaultComponents(~)
            h = matlabshared.application.Component.empty;
        end
    end
end

% [EOF]
