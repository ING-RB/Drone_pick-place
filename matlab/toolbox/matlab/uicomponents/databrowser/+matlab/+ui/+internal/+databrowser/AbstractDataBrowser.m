classdef AbstractDataBrowser < matlab.ui.internal.databrowser.base.AbstractUI
    % Parent class for TableDataBrowser and any custom data browser.
    %
    % To build a custom data browser, create a subclass and add it to AppContainer.
    %
    % Constructor:
    %   <a href="matlab:help matlab.ui.internal.databrowser.AbstractDataBrowser.AbstractDataBrowser">AbstractDataBrowser</a>    
    %
    % Properties:
    %   <a href="matlab:help matlab.ui.internal.databrowser.AbstractDataBrowser.Figure">Figure</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.AbstractDataBrowser.Name">Name</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.AbstractDataBrowser.Title">Title</a>    
    %
    % Public Methods:
    %   <a href="matlab:help matlab.ui.internal.databrowser.AbstractDataBrowser.addToAppContainer">addToAppContainer</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.AbstractDataBrowser.positionFigureOnAppContainer">positionFigureOnAppContainer</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.AbstractDataBrowser.setPreferredHeight">setPreferredHeight</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.AbstractDataBrowser.setPreferredWidth">setPreferredWidth</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.updateUI">updateUI</a>    
    %    
    % Protected Methods:
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.buildUI">buildUI</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.cleanupUI">cleanupUI</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.connectUI">connnectUI</a>    
    %
    % Special methods for data/ui listener management:
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.registerDataListeners">registerDataListeners</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.unregisterDataListeners">unregisterDataListeners</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.enableDataListeners">enableDataListeners</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.disableDataListeners">disableDataListeners</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.registerUIListeners">registerUIListeners</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.unregisterUIListeners">unregisterUIListeners</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.enableUIListeners">enableUIListeners</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.disableUIListeners">disableUIListeners</a>    
    %
    % See also matlab.ui.internal.databrowser.TableDataBrowser, matlab.ui.internal.databrowser.PreviewPanel
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = protected)
        % Property "Name"
        %
        %   Name of the data browser, which is used as identification.
        %
        %   Example:
        %       this.Name = 'AgentsDB';
        Name
        % Property "Title"
        %
        %   Title of the data browser, displayed in the app (use I18N).
        %
        %   Example:
        %       this.Title = 'Agents';
        Title
    end
    
    properties (Dependent, GetAccess = public, SetAccess = private)
        % Property "Figure"
        %
        %   The "uifigure" object that hosts all the widgets used in the
        %   data browser.  Typically used in the subclass as the parent of
        %   widgets such as uitable or uitree
        %
        %   Example:
        %       tree = uitree(this.Figure);
        Figure
    end
    
    properties (SetAccess = protected, GetAccess = public, Transient)
        Panel
        AppContainer
    end
    
    %% public methods
    methods 
        
        function value = get.Figure(this)
            % GET function
            value = this.Panel.Figure;
        end
        
        function addToAppContainer(this, app)
            % Method "addToAppContainer": 
            %
            %   Add the data browser to the left-side panel of the
            %   Appcontainer. 
            %
            %       addToAppContainer(this, app)
            %
            %   where "app" is the AppContainer.
            %
            %   All the data browsers will be vercially stacked.
            app.add(this.Panel);
            this.AppContainer = app;
        end

        function positionFigureOnAppContainer(this,fig)
            % Method "positionFigureOnAppContainer": 
            %
            %   Position a figure in the center of the AppContainer.
            %   
            %       positionFigureOnAppContainer(this, fig);
            %
            %   where "fig" is the handle of a "figure" or "uifigure".
            screensize = get(0,'ScreenSize');
            units = fig.Units;
            fig.Units = 'pixels';
            appsize = this.AppContainer.WindowBounds; % top-left is [0 0]
            appsize(2) = screensize(4) - (appsize(2)+appsize(4)); % bottom-left is [0 0]
            center = [appsize(1)+appsize(3)/2 appsize(2)+appsize(4)/2];
            fig.Position = [min(max(center(1)-fig.Position(3)/2,0),screensize(3)-fig.Position(3)) min(max(center(2)-fig.Position(4)/2,0),screensize(4)-fig.Position(4)) fig.Position(3:4)];
            figure(fig);
            fig.Units = units;
        end
        
    end
    
    methods (Access = protected)
        
        function this = AbstractDataBrowser(name, title)
            % Constructor "AbstractDataBrowser": 
            %
            %   Create a data browser with a uifigure for display in AppContainer.
            %
            %   In the constructor of your subclass, you must have
            %   
            %       this = this@matlab.ui.internal.databrowser.AbstractDataBrowser(name, title);
            %
            %   where "name" is the name of the object for reference and
            %   "title" is displayed in the app.
            this.Name = name;
            this.Title = title;
            this.Panel = buildPanel(this);
        end
        
        function setPreferredWidth(this, width)
            % Method "setPreferredWidth": 
            %
            %   Set preferred width of data browser when displayed in
            %   AppContainer.
            %   
            %       setPreferredWidth(this, width);
            %
            %   where "width" is in pixels.  If not used, default width is
            %   used, which is auto-determined by AppContainer.
            this.Panel.PreferredWidth = width;
        end
        
        function setPreferredHeight(this, height)
            % Method "setPreferredHeight": 
            %
            %   Set preferred height of data browser when displayed in
            %   AppContainer.
            %   
            %       setPreferredHeight(this, height);
            %
            %   where "height" is in pixels.  If not used, default height
            %   is used, which is auto-determined by AppContainer.
            this.Panel.PreferredHeight = height;
        end
        
    end
    
    methods(Access = private)
        
        function panel = buildPanel(this)
            panelOptions.Title = this.Title; 
            panelOptions.Region = "left";
            panel = matlab.ui.internal.FigurePanel(panelOptions); 
            % do not set custom panel tag because AppContainer honors
            % alphabetic order during launch (might be a bug)
            panel.Figure.Tag = strcat('dbfigure_',this.Name);
        end
        
    end
    
    methods (Hidden)
        
        function f = qeShow(this)
            % Method "qeShow": 
            %
            %   Launch data browser inside a uifigure for unit testing.
            %   
            %       qeShow(this);
            %
            %   Do not use it when it should be added to an AppContainer.
            widgets = this.Figure.Children;
            f = uifigure;
            for ct=1:length(widgets)
                widgets(ct).Parent = f;
            end
        end
        
    end
    
end

