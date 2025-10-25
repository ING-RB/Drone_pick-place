%

% Copyright 2013-2015 The MathWorks, Inc.
classdef WebDDG < handle
    properties(SetObservable=true)
        Title = '';
        Url = '';
        PageNotFoundUrl = '';
        Html = '';
        ToolbarOptions = {};
        Geometry = [];
        EnableInspectorInContextMenu = false;
        EnableInspectorOnLoad = false;
        Debug = false;
        ClearCache = false;
        EnableJsOnClipboard = false;
        WebKit = false;
        DisableContextMenu = false;
        CloseCallback;
        CloseArgs;
    end
    
    properties(SetAccess = private)
        Tag = '';
        HomeUrl = '';
    end

    properties(SetAccess = private, GetAccess = public)
        % The current active URL
        CurrentUrl = '';
    end
    
    methods
        function this = WebDDG(varargin)
            assert(nargin < 3, 'The number of input parameters are wrong! First: tag(optional)|url(optional), Second: homeUrl(optional).');
            if nargin == 1
                if length(regexp(varargin{1}, '^http://')) == 1 || length(regexp(varargin{1}, '^https://')) == 1
                    this.Url = varargin{1};
                    this.ToolbarOptions = {'URLBar', 'Navigation'};
                    this.Geometry = [100 100 800 800];
                    this.EnableInspectorInContextMenu = true;
                    this.ClearCache = true;
                    this.Debug = true;
                    show(this)
                end
                this.Tag = varargin{1};
            end
            if nargin == 2
                if ischar( varargin{2} )
                    this.HomeUrl = varargin{2};
                else
                    this.Url = varargin{1};
                    this.ToolbarOptions = varargin(2);
                    this.Geometry = [100 100 800 800];
                    this.EnableInspectorInContextMenu = true;
                    this.ClearCache = true;
                    this.Debug = true;
                    show(this)                    
                end
                this.Tag = varargin{1};
            end
        end
        
        function createEmbeddedDDG(obj, studio, id, title, dockposition, dockoption)
            DAStudio.openEmbeddedDDGForSource(studio, obj, id, title, dockposition, dockoption);   
        end
        
        function dlg = createStandaloneDDG(obj)
            dlg = DAStudio.Dialog(obj);
        end
        
        function dlg = show(obj, varargin)
            if (nargin > 1)
                obj.Url = varargin{1};
            end
            d = DAStudio.ToolRoot.getOpenDialogs(obj);
            if ~isempty(d)
                for i = 1:length(d)
                    d(i).show;
                end
            else 
                dlg = createStandaloneDDG(obj);
            end
        end
        
        function hide(obj)
            d = DAStudio.ToolRoot.getOpenDialogs(obj);
            if ~isempty(d)
                for i = 1:length(d)
                    d(i).hide;
                end
            end
        end
        
        function dlg = getDialogSchema(h)
            webbrowser.Type          = 'webbrowser';
            webbrowser.Tag           = 'DDGWebBrowser';
            webbrowser.Url           = h.Url;
            webbrowser.HTML          = h.Html;
            webbrowser.WebKit        = h.WebKit;
            webbrowser.WebKitToolBar = h.ToolbarOptions;
            webbrowser.HomeURL       = h.HomeUrl;
            webbrowser.PageNotFoundUrl             = h.PageNotFoundUrl;
            webbrowser.EnableInspectorInContextMenu = h.EnableInspectorInContextMenu;
            webbrowser.EnableInspectorOnLoad        = h.EnableInspectorOnLoad;
            webbrowser.ClearCache    = h.ClearCache;
            webbrowser.Debug         = h.Debug;
            webbrowser.EnableJsOnClipboard = h.EnableJsOnClipboard;
            webbrowser.DisableContextMenu = h.DisableContextMenu;
            webbrowser.BrowserUrlChangeCallback = @onURLChangedCB;
            
            dlg.DialogTitle         = h.Title;
            dlg.DialogTag           = h.Tag;
            dlg.Items               = {webbrowser};
            dlg.StandaloneButtonSet = {''};
            dlg.EmbeddedButtonSet   = {''};
            
            if(~isempty(h.CloseCallback))
                dlg.CloseCallback  = h.CloseCallback;
            end 
            if(~isempty(h.CloseArgs))
                dlg.CloseArgs = h.CloseArgs;
            end
            if (~isempty(h.Geometry))
              dlg.Geometry = h.Geometry;
            end

            function onURLChangedCB(~, ~, url)
                h.CurrentUrl = url;
            end
        end 
        
        % customed setters to update dialog when properties are changes  
        function set.Title(obj, value)
            obj.Title = value;
            d = DAStudio.ToolRoot.getOpenDialogs(obj);
            if ~isempty(d)
                for i = 1:length(d)
                    d(i).setTitle(value);
                end
            end
        end
        
        function set.Url(obj, value)
            obj.Url = value;
            refreshAllDialogs(obj);  
            obj.CurrentUrl = obj.Url;
        end
        
        function set.PageNotFoundUrl(obj, value)
            obj.PageNotFoundUrl = value;
            refreshAllDialogs(obj);  
        end
        
        function set.Html(obj, value)
            obj.Html = value;
            refreshAllDialogs(obj);
        end
        
        function set.ToolbarOptions(obj, value)
            obj.ToolbarOptions = value;
            refreshAllDialogs(obj);
        end 
        
        function set.Geometry(obj, value)
            if (not(isempty(value)))
                s = size(value);
                if (s(1) ~= 1 || s(2) ~= 4) || not(all(isnumeric(value)))
                    warning('Ignored invalid geometry. Geometry must be like: [x y width height]');
                    return
                end
            end
            obj.Geometry = value;
            refreshAllDialogs(obj); % this doesn't seem to update existing dialogs?
        end
        
        function moveTo(obj, x, y)
            assert(isnumeric(x), 'Invalid x; parameters must be valid x, y coordinates.');
            assert(isnumeric(y), 'Invalid y; parameters must be valid x, y coordinates.');

            d = DAStudio.ToolRoot.getOpenDialogs(obj);
            if ~isempty(d)
                for i = 1:length(d)
                    dlg = d(i);
                    assert(dlg.isStandAlone, 'Cannot move an embedded dialog');
                    currentGeometry = dlg.position;
                    newGeometry = [x y currentGeometry(3) currentGeometry(4)];
                    dlg.position = newGeometry;
                end
            else
                disp('No open dialogs to modify.');
                return;
            end
        end
        
        function resizeTo(obj, width, height)
            assert(isnumeric(width) && width > 0, 'Invalid width; width and height must be > 0.');
            assert(isnumeric(height) && height > 0, 'Invalid height; width and height must be > 0.');

            d = DAStudio.ToolRoot.getOpenDialogs(obj);
            if ~isempty(d)
                for i = 1:length(d)
                    dlg = d(i);
                    assert(dlg.isStandAlone, 'Cannot resize an embedded dialog');
                    currentGeometry = dlg.position;
                    newGeometry = [currentGeometry(1) currentGeometry(2) width height];
                    dlg.position = newGeometry;
                end
            else
                disp('No open dialogs to modify.');
                return;
            end
        end
        
        function showToolbar(obj)
            % Other toolbar option is 'Search'
            obj.ToolbarOptions = {'Navigation', 'URLBar'};
        end
        
        function refreshAllDialogs(obj)
            d = DAStudio.ToolRoot.getOpenDialogs(obj);
            if ~isempty(d)
                for i = 1:length(d)
                    d(i).refresh;
                end
            end
        end
    end
end