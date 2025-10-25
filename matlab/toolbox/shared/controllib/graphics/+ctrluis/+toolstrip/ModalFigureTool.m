classdef ModalFigureTool < ctrluis.toolstrip.FigureTool
   %MODALFIGURETOOL Figure tool with many modes.
   
   % Copyright 2013-2018 The MathWorks, Inc
   
   properties(GetAccess = public, SetAccess = protected)
      ModeManager   %Mode Manager instance used by the FigureTool
   end
   
   methods
      function set.ModeManager(this,manager)
         this.ModeManager = manager;
         weakThis = matlab.lang.WeakReference(this);
         addlistener(manager,'ModeChanged', @(hSrc,hData) cbModeChanged(weakThis.Handle,hData));
      end
   end
   
   methods(Access = protected)
      function obj = ModalFigureTool(varargin)
         %MODALFIGURETOOL Construct ModalFigureTool object
         %
         
         %Call parent constructor
         obj = obj@ctrluis.toolstrip.FigureTool(varargin{:});
      end
      function configureTabGroup(this)
         %CONFIGURETABGROUP Configure the TabGroup for a figure tool
         %
         %    configureTabGroup(obj)
         %
         %    Inputs:
         %      obj - ctrluis.toolstrip.FigureTool instance
         %
         
         %Get tabs we need to display for this mode
         mTabs    = getModeTabs(this.ModeManager);
         showTabs = getAllTabs(this); % all "valid" tabs
         
         %Add the tabs we need to display
        for ct = 1:numel(showTabs)
           this.TabGroup.add(showTabs(ct)); % does not add already present tab
        end
         
         %Select the tab associated with the figure. Do this before
         %removing any extra tabs as in API ver2 removing a tab that is
         %selected will cause the toolstrip to select the home tab.
         if isempty(mTabs)
            this.TabGroup.SelectedTab = this.Tab;
         else
            this.TabGroup.SelectedTab = mTabs(end);
         end
         
         %Remove any tabs we are currently showing but no longer need
        % using matlab.ui.internal.toolstrip tabs
        ExistingTabs = getChildByIndex(this.TabGroup);
        for ct = 1:numel(ExistingTabs)
           if ~any(ExistingTabs(ct) == showTabs)
              this.TabGroup.remove(ExistingTabs(ct));
           end
        end
         
      end
      function cbModeChanged(this,hData)
         %CBMODECHANGED
         %
         
         if strcmp(hData.Type,'PostModeChanged')
            configureTabGroup(this);
         end
      end
      
      function Tabs = getAllTabs(this)
         % GETALLTABS Get a vector of all tabs associated with this modal
         % figure.
         Tabs = [this.Tab; getModeTabs(this.ModeManager)];
      end
   end
end