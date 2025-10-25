classdef FigureTool < handle
    % FigureTool
    
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties
        PlotTab       % Default Plot Tab
    end
    
    properties(GetAccess = public, SetAccess = protected)
        ToolGroup     %The desktop group the figure tool is part of
        Figure        %HG figure associated with the tool
        TabGroup      %TabGroup containing all tabs associated with the tool
    end
    
    methods(Access = public)
        
        function this = FigureTool(fig,varargin)
            %FIGURETOOL Construct FigureTool object
            %
            % create TabGroup
            if nargin > 1
                this.TabGroup = varargin{1};
            else
                this.TabGroup = matlab.ui.internal.toolstrip.TabGroup();
            end
            % save figure reference
            this.Figure = fig;
            % when this component is destroyed programmatically, remove the
            % tabgroup as well.  if the tabgroup is already removed such as
            % from UI crossing, this is null op inside removeClientTabGroup
            weakThis = matlab.lang.WeakReference(this);
            addlistener(this,'ObjectBeingDestroyed', @(hSrc,hData)  removeFromHost(weakThis.Handle));
        end
        
        function addToHost(this,grp)
            %ADD Add the figure and tabgroup to a desktop group
            %
            %    add(this,group,[keeptab])
            %
            %    Inputs:
            %      this    - ctrluis.toolstrip.FigureTool instance
            %      group   - matlab.ui.container.internal.AppContainer that the tool is
            %                added to
            %      keeptab - optional flag specifying whether the tool
            %                group selected tab should change when the
            %                figure is added. If omitted the default false
            %                is used.

            % configure tabs in the tabgroup
            configureTabGroup(this)
            %Store ToolGroup handle so we can remove on close
            this.ToolGroup = grp;
        end
        
        function removeFromHost(this)
            %REMOVE Remove the figure tool from the desktop group
            %
            %    remove(this)
            %
            %    Inputs:
            %      this - ctrluis.toolstrip.FigureTool instance
            %
            
            %Hide the figure and remove the TabGroup
            if ishghandle(this.Figure)
                set(this.Figure,'visible','off')
                if ~isempty(this.ToolGroup) && isvalid(this.ToolGroup)
                    %ToolGroup may already be closed
                    if isa(this.ToolGroup,'matlab.ui.container.internal.AppContainer')
%                         remove(this.TabGroup,this.PlotTab);
                    else
                        removeClientTabGroup(this.ToolGroup,this.Figure);
                    end
                end
            end
        end
        
        function addTab(this, tab)
            if ~any(this.TabGroup.Children==tab)
                this.TabGroup.add(tab);
            end
        end
        
        function selectTab(this, tab)
            if isempty(tab)
                this.TabGroup.SelectedTab = [];
            elseif any(this.TabGroup.Children==tab)
                this.TabGroup.SelectedTab = tab;
            end
        end
        
        function addPlotTab(this, name, title)
            plottab = controllib.app.plottab.internal.PlotTab(name, title, this.Figure);
            this.PlotTab = plottab.getTab();
            this.TabGroup.add(this.PlotTab);
        end
        
        function selectPlotTab(this)
            if ~isempty(this.PlotTab)
                this.TabGroup.SelectedTab = this.PlotTab;
            end
        end
        
    end
    
    methods(Access = protected)
        
        function configureTabGroup(~)
            %CONFIGURETABGROUP Configure the TabGroup for a figure tool 
            %
            %    configureTabGroup(this)
        end
        
    end
    
end