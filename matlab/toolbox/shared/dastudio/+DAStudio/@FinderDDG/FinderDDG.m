classdef FinderDDG < handle
    
    properties(SetObservable=true)
        Title = '';
        Url = '';
        Html = '';
        ToolbarOptions = {};
        Geometry = [];
        EnableInspectorInContextMenu = false;
        EnableInspectorOnLoad = false;
        DisableContextMenu = false;
        Debug = false;
        ClearCache = false;
    end
    
    properties(SetAccess = private)
        Tag = '';
        HomeUrl = '';
        CloseArgs = {};
    end
    
    methods             
        function this = FinderDDG(varargin)
            if nargin > 0
                if length(regexp(varargin{1}, '^http://')) == 1 || length(regexp(varargin{1}, '^https://')) == 1
                    this.Url = varargin{1};    
                end
                if nargin == 2
                    this.EnableInspectorInContextMenu = varargin{2};
                    this.EnableInspectorOnLoad = varargin{2};
                    this.DisableContextMenu = ~varargin{2};
                else
                    this.EnableInspectorInContextMenu = false;
                    this.EnableInspectorOnLoad = false;
                    this.DisableContextMenu = true;
                end   
            end
        end
        
        function comp = createEmbeddedDDG(obj, studio, id, title, dockposition, dockoption)
            comp = GLUE2.FinderComponent(studio, id);
            studio.registerComponent(comp);
            studio.moveComponentToDock(comp, title, dockposition, dockoption);
        end
        
        function dlg = createStandaloneDDG(obj)
            dlg = DAStudio.Dialog(obj);
        end
        
        function dlg = getDialogSchema(h)
            if (~isempty(h.Url))
                webbrowser.Type          = 'webbrowser';
                webbrowser.Tag           = 'DDGFinderBrowser';
                webbrowser.Url           = h.Url;
                webbrowser.HTML          = h.Html;
                webbrowser.WebKit        = true;
                webbrowser.WebKitToolBar = h.ToolbarOptions;
                webbrowser.HomeURL       = h.HomeUrl;
                webbrowser.EnableInspectorInContextMenu = h.EnableInspectorInContextMenu;
                webbrowser.EnableInspectorOnLoad        = h.EnableInspectorOnLoad;
                webbrowser.DisableContextMenu           = h.DisableContextMenu;
                webbrowser.ClearCache    = h.ClearCache;
                webbrowser.Debug         = h.Debug;
                dlg.Items                = {webbrowser};              
            else
                dlg.Items                = {};
            end
            
            dlg.DialogTitle         = h.Title;
            dlg.DialogTag           = h.Tag;
            dlg.StandaloneButtonSet = {''};
            dlg.EmbeddedButtonSet   = {''};
            dlg.IsScrollable        = false;
            if (~isempty(h.Geometry))
              dlg.Geometry = h.Geometry;
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
        
        
    end
    
end

