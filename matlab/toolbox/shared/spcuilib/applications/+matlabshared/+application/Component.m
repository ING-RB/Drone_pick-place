classdef Component < handle & matlab.mixin.Heterogeneous
    % Superclass for tool group windows

    %   Copyright 2017-2020 The MathWorks, Inc.

    properties (Dependent)
        Visible
    end

    properties (SetAccess = protected, Hidden)
        Figure
        Application
        Document
        Keyboard
    end

    properties (Access = protected)
        KeyPressListener
        MotionListener
    end

    properties (SetAccess = protected, Dependent, Hidden)
        FigureDocument
    end

    methods

        function this = Component(varargin)
            parseInputs(this, varargin{:});
            initializeFigure(this);
        end
        function initializeFigure(this)
            this.Figure = createFigure(this);
            if ishandle(this.Figure)
                hWidgets = findall(this.Figure, 'type', 'uicontrol');
                if ~isempty(hWidgets)
                    this.KeyPressListener = event.listener(hWidgets, ...
                        'KeyPress', @this.onWidgetKeyPress);
                end
                this.Keyboard = createKeyboard(this);
            end
        end

        function b = isCloseable(~)
            b = false;
        end

        function b = isIntrinsic(this)
            % An Intrinsic component will shutdown the application if it is
            % shutdown.  By default all components marked as noncloseable
            % are intrinsic.
            b = ~isCloseable(this);
        end

        function b = isDocked(this)
            b = isDocked(this.Application, this);
        end

        function resize(~)
            % NO OP by default.
        end

        function delete(this)
            fig = this.Figure;
            if ~isempty(fig) && ishghandle(fig)
                delete(fig);
            end
        end

        function set.Visible(this, vis)
            if isPanel(this)
                this.Document.Opened = vis;
            else
                % Would have to detach Documents
            end
        end

        function vis = get.Visible(this)
            if isPanel(this)
                vis = this.Document.Opened;
            else
                doc = this.Document;
                if isempty(doc)
                    vis = get(this.Figure, 'Visible');
                else
                    vis = doc.Visible;
                end
            end
        end

        function set.FigureDocument(this, doc)
            this.Document = doc;
        end

        function doc = get.FigureDocument(this)
            doc = this.Document;
        end
    end

    methods (Sealed)
        function out = findobj(varargin)
            out = findobj@handle(varargin{:});
        end

        function out = eq(varargin)
            out = eq@handle(varargin{:});
        end

        function out = ne(varargin)
            out = ne@handle(varargin{:});
        end
    end

    methods (Hidden)
        function focusOnComponent(this)

            % Only focus on the component if the toolgroup is already in
            % focus.  This will prevent the window from popping up.
            % Optimize performance by checking the object currently
            % hovering on.
            try
                hApp = this.Application;
                if ~isvalid(hApp)
                    return;
                end
                focusOnComponent(hApp, this);
            catch me %#ok
                % This can error during shutdown.
            end
        end

        function onBlur(~)
            % NO OP
        end

        function onFocus(~)
            % NO OP
        end

        function onKeyPress(varargin)
            % NO OP
            % This exists at the highest level to prevent keypresses from
            % going to the commandline for any application.
        end

        function tag = getDocumentGroupTag(~)
            tag = 'WorkingArea';
        end

        function b = isPanel(~)
            b = false;
        end

        function id = getTileOccupancyId(this)
            id = sprintf('%s_%s', getDocumentGroupTag(this), getTag(this));
        end

        function region = getPanelRegion(~)
            region = 'left';
        end

        function b = isAttached(this)
            b = any(this.Application.Components == this);
        end

        function b = isFigureValid(this)
            if useAppContainer(this.Application)
                b = isvalid(this.FigureDocument);
            else
                b = isvalid(this.Figure);
            end
        end
    end

    methods (Access = protected)
        function keyboard = createKeyboard(this)
            keyboard = [];
            this.Figure.KeyPressFcn = @this.onKeyPress;
        end

        function parseInputs(this, hApplication, varargin)
            this.Application = hApplication;
            for indx = 1:2:numel(varargin)
                this.(varargin{indx}) = varargin{indx + 1};
            end
        end

        function hFig = createFigure(this, varargin)
            app = this.Application;
            varargin = [{ ...
                'HandleVisibility', 'off', ...
                'IntegerHandle', 'off', ...
                'WindowButtonMotionFcn', @this.windowMotionCallback, ...
                'Menubar', 'none', ...
                'Tag', getTag(this), ...
                'ResizeFcn', @this.resizeCallback} varargin];
            if useAppContainer(app) && isDocked(this)
                options = getAddToApplicationOptions(this);
                if isPanel(this)
                    options.Region = getPanelRegion(this);
                    document = matlab.ui.internal.FigurePanel(options);
                    addPanel(app, document);
                else
                    group = getDocumentGroup(app, getDocumentGroupTag(this));
                    options.DocumentGroupTag = group.Tag;
                    document = matlab.ui.internal.FigureDocument(options);
                    addDocumentToApplication(this, document);
                end
                this.Document = document;
                hFig = document.Figure;
                set(hFig, 'AutoResizeChildren', 'off', varargin{:});
            else
                hFig = figure('Name', getName(this), ...
                    'Visible', 'off', ...
                    'DeleteFcn', @this.figureDeleteCallback, ...
                    varargin{:});
            end
            setappdata(hFig, 'Handle', this);
        end

        function options = getAddToApplicationOptions(this)
            options = struct( ...
                'Title', getName(this), ...
                'Tag', getTag(this), ...
                'Closable', isCloseable(this));
        end

        function addDocumentToApplication(this, document)
            this.Document = document;
            addDocument(this.Application, this);
        end

        function updateName(this)
            document = this.Document;
            if ~isempty(document) && isvalid(document)
                document.Title = getName(this);
            end
        end

        function onWidgetKeyPress(this, h, ev)

            % Only process widget keypresses that contain a control
            % modifier.
            if isDocked(this) && any(strcmp(ev.Modifier, 'control'))
                % Special case ctrl-v ctrl-x ctrl-c in editboxes
                if ~ishghandle(ev.Source, 'uicontrol') || ...
                        ~strcmp(ev.Source.Style, 'edit') || ...
                        ~any(strcmpi(ev.Key, {'c', 'x', 'v', 'a'}))
                    onComponentKeyPress(this.Application, h, ev);
                end
            end
        end

        function resizeCallback(this, ~, ~)
            % The resizeCallback can be issued after the app is closed.  In
            % this case "this" is no longer valid.  Any of these errors can
            % be ignored.  Rethrow all errors that happen when "this" is
            % still a valid object.
            try
                resize(this);
            catch me
                if isvalid(this) && isFigureValid(this) && isvalid(this.Application)
                    rethrow(me);
                end
            end
        end

        function figureDeleteCallback(this, ~, ~)
            onFigureDelete(this);
        end

        function onFigureDelete(this)
            app = this.Application;
            if isvalid(app) && isOpen(app) && ~app.IsClosing
                if isIntrinsic(this) && ~useAppContainer(app)
                    % Only destroy the app if this component is intrinsic
                    % and if we are using the old toolgroup, because the
                    % old toolgroup's figures can be removed via close all
                    % force, but in appcontainer they cannot be.
                    notify(app, 'ToolGroupBeingDestroyed');
                    close(app);
                else
                    removeComponent(app, this);
                end
            end
        end

        function windowMotionCallback(this, ~, ~)
            doc = this.Document;
            if ~useAppContainer(this.Application) && (isempty(doc) || doc.Showing)
                focusOnComponent(this);
            end
        end
    end

    methods (Abstract)
        name = getName(this)
        tag  = getTag(this)
    end
end

% [EOF]
