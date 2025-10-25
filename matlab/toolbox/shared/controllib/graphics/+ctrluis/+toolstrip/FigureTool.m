classdef FigureTool < handle
   % A figure with an associated tab.
   
   % Copyright 2013-2021 The MathWorks, Inc.
   
   properties(GetAccess = public, SetAccess = protected)
      Figure        %HG figure associated with the tool
      TabGroup      %TabGroup containing all tabs associated with the tool
      FigureDocument
   end
   
   properties(Dependent, GetAccess = public, SetAccess = protected)
      Tab           %Permanent Tab associated with the tool
   end
   
   properties(Access = private)
      Tab_
   end
   
   properties(Access = protected)
      Group  %The desktop group the figure tool is part of
      
      % To be deleted
      TabVersion = 2;
      ContainerVersion = 2;
      
   end
   
   methods
      function set.Tab(this, Value)
         if ~isa(Value, 'matlab.ui.internal.toolstrip.Tab')
            error(message('Controllib:general:UnexpectedError',...
               'Unexpected class for "Tab" property.'))
         end
         this.Tab_ = Value;
      end
      
      function Value = get.Tab(this)
         Value = this.Tab_;
      end      
   end
   
   methods(Access = public)
      function add(this,grp,varargin)
         %ADD Add the figure tool to a desktop group
         %
         %    add(this,group,[keeptab])
         %
         %    Inputs:
         %      this     - ctrluis.toolstrip.FigureTool instance
         %      group   - AppContainer the tool is added to
         %      keeptab - optional flag specfiying whether the tool
         %                group selected tab should change when the figure
         %                is added. If omitted the default false is used
         %
         
         if isempty(this.Figure)
            error(message('Controllib:general:UnexpectedError','Must have valid figure to add to the desktop group'))
         end
         if isempty(this.TabGroup)
            error(message('Controllib:general:UnexpectedError','Must have a valid tabgroup to add to the desktop group'))
         end
         
         resetTab = numel(varargin) > 0;
         
         %Add tabs to the tabgroup
         configureTabGroup(this)
         if resetTab
            this.TabGroup.SelectedTab = [];
         end

         %Add figure and TabGroup to the desktop group
         grp.add(this.TabGroup);
         grp.add(this.FigureDocument);
         set(this.Figure,'visible','on'); % NOTE: Not sure if this does anything
         
         %Store Group handle so we can remove on close
         this.Group = grp;
      end
   
      function remove(this) %#ok<MANU>
         %REMOVE Remove the figure tool from the desktop group
         %
         %    remove(this)
         %
         %    Inputs:
         %      this - ctrluis.toolstrip.FigureTool instance
         %
         %Hide the figure and remove the TabGroup
      end
 end
 
 methods(Access = protected)
      function this = FigureTool(varargin)
         %FIGURETOOL Construct FigureTool object

         %Set the TabGroup property
         this.TabGroup = matlab.ui.internal.toolstrip.TabGroup;
         this.TabGroup.Contextual = true;
      end
      function configureTabGroup(this)
         %CONFIGURETABGROUP Configure the TabGroup for a figure tool
         %
         %    configureTabGroup(this)
         %
         %    Inputs:
         %      this - ctrluis.toolstrip.FigureTool instance
         
         if isempty(this.Tab)
             %Quick return if there is no tab
             return
         end
         
         % add permanent tab to the tab group
        this.TabGroup.add(this.Tab);
        this.TabGroup.SelectedTab = this.Tab; % fires SelectedTabChanged
      end
   end
end
