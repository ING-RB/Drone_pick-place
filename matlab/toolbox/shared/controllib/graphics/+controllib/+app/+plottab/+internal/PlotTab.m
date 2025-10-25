classdef PlotTab < ctrluis.component.AbstractTabNew
    % Plot Tab for app
    
    % Copyright 2015 The MathWorks, Inc.
    
    properties
        Widgets
        Figure
        ModeManager
    end
    
    methods
        
        %% constructor
        function this = PlotTab(TabName, TabTitle, fig)
            this.Tag = TabName;
            this.Title = TabTitle;
            this.Figure = fig;
            this.ModeManager = uigetmodemanager(this.Figure);
            % build tab
            buildTab(this);
        end
        
        function updateUI(this)
            updateLegend(this);
        end
        
    end
    
    methods (Access = protected)
        
        function createSections(this)            
            %% Zoom
            createZoom(this);
            %% Legend
            createLegend(this);
        end
        
        function connectUI(this)
            % UI
            lis = addlistener(this.Widgets.ZoomSection.ZoomInButton,'ValueChanged',@(es,ed) cbZoomIn(this));
            registerUIListeners(this, lis, 'zoomin');
            lis = addlistener(this.Widgets.ZoomSection.ZoomOutButton,'ValueChanged',@(es,ed) cbZoomOut(this));
            registerUIListeners(this, lis, 'zoomout');
            lis = addlistener(this.Widgets.ZoomSection.PanButton,'ValueChanged',@(es,ed) cbPan(this));
            registerUIListeners(this, lis, 'pan');
            lis = addlistener(this.Widgets.LegendSection.LegendButton,'ValueChanged',@(es,ed) cbLegend(this));
            registerUIListeners(this, lis, 'legend');
            % Data
            lis = addlistener(this.ModeManager,'CurrentMode','PostSet',@(es,ed) cbCurrentMode(this));
            registerDataListeners(this, lis, 'mode');
            lis = addlistener(handle(this.Figure),'CurrentAxes','PostSet',@(es,ed) updateLegend(this));
            registerDataListeners(this, lis, 'axes');
        end
        
    end
    
    methods (Access = private)
        
        function createZoom(this)
            import matlab.ui.internal.toolstrip.*
            % create section
            section = Section(getString(message('Controllib:gui:PlotTabZoomPanSection')));
            section.Tag = 'ZoomSection';
            % create column
            column1 = Column();
            column2 = Column();
            column3 = Column();
            % create button
            icon = Icon(fullfile(matlabroot,'toolbox','shared','controllib','general','resources','toolstrip_icons','Zoom_In_16.png'));
            ZoomInButton = ToggleButton(icon);
            ZoomInButton.Tag = 'btnZoomIn';
            ZoomInButton.Description = getString(message('Controllib:gui:PlotTabZoomZoomIn'));
            icon = Icon(fullfile(matlabroot,'toolbox','shared','controllib','general','resources','toolstrip_icons','Zoom_Out_16.png'));
            ZoomOutButton = ToggleButton(icon);
            ZoomOutButton.Tag = 'btnZoomOut';
            ZoomOutButton.Description = getString(message('Controllib:gui:PlotTabZoomZoomOut'));
            icon = Icon(fullfile(matlabroot,'toolbox','shared','controllib','general','resources','toolstrip_icons','Pan_16.png'));
            PanButton = ToggleButton(icon);
            PanButton.Tag = 'btnPan';
            PanButton.Description = getString(message('Controllib:gui:PlotTabZoomPan'));
            % assemble
            add(this.Tab,section);
            add(section, column1);
            addEmptyControl(column1);
            add(column1,ZoomInButton);
            addEmptyControl(column1);
            add(section, column2);
            addEmptyControl(column2);
            add(column2,ZoomOutButton);
            addEmptyControl(column2);
            add(section, column3);
            addEmptyControl(column3);
            add(column3,PanButton);
            addEmptyControl(column3);
            % save references
            this.Widgets.ZoomSection =  struct('ZoomInButton',ZoomInButton,'ZoomOutButton',ZoomOutButton,'PanButton',PanButton);
        end
        
        function createLegend(this)
            import matlab.ui.internal.toolstrip.*
            % create section
            section = Section('Legend');
            section.Tag = 'LegendSection';
            % create column
            column = Column();
            % create button
            icon = Icon(fullfile(matlabroot,'toolbox','shared','controllib','general','resources','toolstrip_icons','Legend_16.png'));
            LegendButton = ToggleButton('Legend',icon);
            LegendButton.Tag = 'btnLegend';
            LegendButton.Description = getString(message('Controllib:gui:PlotTabLegendLegend'));
            % assemble
            add(this.Tab,section);
            add(section, column);
            addEmptyControl(column);
            add(column,LegendButton);
            addEmptyControl(column);
            % save references
            this.Widgets.LegendSection =  struct('LegendButton',LegendButton);
        end
        
        %% callbacks
        function cbZoomIn(this)
            %If Zoom-In in clicked, Zoom-in
            fig = this.Figure;
            if this.Widgets.ZoomSection.ZoomInButton.Value
                zoom(fig, 'inmode');
            else
                zoom(fig, 'off');
            end
        end
        
        function cbZoomOut(this)
            %If Zoom-out in clicked, Zoom-out
            fig = this.Figure;
            if this.Widgets.ZoomSection.ZoomOutButton.Value
                zoom(fig, 'outmode');
            else
                zoom(fig, 'off');
            end
        end
        
        function cbPan(this)
            %If Pan is selected, Pan
            fig = this.Figure;
            if this.Widgets.ZoomSection.PanButton.Value
                pan(fig, 'on');
            else
                pan(fig, 'off');
            end           
        end
        
        function cbCurrentMode(this)
           %Toggle button status according to current mdoe
           disableUIListeners(this,{'zoomin','zoomout','pan'});
           CurrentMode = get(this.ModeManager.CurrentMode);
           if ~isempty(CurrentMode)
               if strcmp(CurrentMode.Name,'Exploration.Zoom')
                   if strcmp(CurrentMode.ModeStateData.Direction, 'in')
                       %Zoom-in mode - enable Zoom-In button and disable the
                       %Zoom-Out and Pan buttons
                       this.Widgets.ZoomSection.ZoomInButton.Value = true;
                       this.Widgets.ZoomSection.ZoomOutButton.Value = false;
                       this.Widgets.ZoomSection.PanButton.Value = false;
                   else
                       %Zoom-out mode - enable Zoom-out button and disable the
                       %Zoom-in and Pan buttons
                       this.Widgets.ZoomSection.ZoomOutButton.Value = true;
                       this.Widgets.ZoomSection.ZoomInButton.Value = false;
                       this.Widgets.ZoomSection.PanButton.Value = false;
                   end
               elseif strcmp(CurrentMode.Name,'Exploration.Pan')
                   %Pan mode - enable Pan button and disable the
                   %Zoom-Out and Zoom-In buttons
                   this.Widgets.ZoomSection.PanButton.Value = true;
                   this.Widgets.ZoomSection.ZoomInButton.Value = false;
                   this.Widgets.ZoomSection.ZoomOutButton.Value = false;
               else
                   %If the figure is in any mode other than zoom or pan,
                   %toggle all three buttons off
                   this.Widgets.ZoomSection.PanButton.Value = false;
                   this.Widgets.ZoomSection.ZoomInButton.Value = false;
                   this.Widgets.ZoomSection.ZoomOutButton.Value = false;
               end
           else
               %If the CurrentMode is empty, toggle all three buttons off
               this.Widgets.ZoomSection.PanButton.Value = false;
               this.Widgets.ZoomSection.ZoomInButton.Value = false;
               this.Widgets.ZoomSection.ZoomOutButton.Value = false;
           end
           enableUIListeners(this,{'zoomin','zoomout','pan'});
        end
        
        function cbLegend(this)
            %If the legend button is pressed, get current axes handle
            CurrentAxesHandle = get(this.Figure, 'CurrentAxes');
            if ~isempty(CurrentAxesHandle) 
                %Add or delete the legend according to the button state
                if this.Widgets.LegendSection.LegendButton.Value
                    legend(CurrentAxesHandle, 'show');
                else
                    legend(CurrentAxesHandle, 'off');
                end  
            end
            updateLegend(this);
        end
        
        function updateLegend(this)
            disableUIListeners(this,'legend');
            unregisterDataListeners(this, 'legend_being_destroyed');
            %Get the current axes handle
            CurrentAxesHandle = get(this.Figure, 'CurrentAxes');
            %Does the current axes have a legend?
            LegendHandle = get(CurrentAxesHandle,'Legend');
            
            if isempty(LegendHandle) 
                %If the current axes does not have a listener, toggle the
                %button state to OFF
                this.Widgets.LegendSection.LegendButton.Value = false;
            else
                %If current axes has a legend, toggle the button state to
                %ON and add a listener to the legend being destroyed
                lis = addlistener(handle(LegendHandle), 'ObjectBeingDestroyed', @(es, ed) cbDestroyLegend(this));
                registerDataListeners(this, lis, 'legend_being_destroyed');
                this.Widgets.LegendSection.LegendButton.Value = true;
            end
            enableUIListeners(this,'legend');
        end
        
        function cbDestroyLegend(this)
            %Toggle the button when the legend is destroyed from outside the
            %LegendButton
            disableUIListeners(this,'legend');
            this.Widgets.LegendSection.LegendButton.Value = false;
            enableUIListeners(this,'legend');
        end
        
    end
    
end

