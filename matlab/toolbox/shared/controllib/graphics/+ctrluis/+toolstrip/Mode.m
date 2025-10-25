classdef Mode < matlab.mixin.Heterogeneous & handle
   % An abstract mode of a modal figure.
   
   % Copyright 2013-2020 The MathWorks, Inc
   
   properties(Dependent = true, GetAccess = public, SetAccess = public, SetObservable = true)
      Enabled  %Mode state
   end
   
   properties(Access = private)
      Enabled_ = false;
   end
   
   properties(GetAccess = public, SetAccess = protected)
      Name = '';  %Name of the mode, this is an instance specific name
      DataNameSection = [];
   end
   
   properties(Abstract = true, Constant = true)
      ICON         %Icon path/name used to represent the mode
      ICON_16      %Icon path/name used to represent the mode
      DISPLAYNAME  %Name of the mode to use when displaying the mode
      DESCRIPTION  %Description of the mode
   end
   
   properties(GetAccess = protected, SetAccess = protected)
      ModeManager   %ModeManager managing this mode
      Tab           %Tab(s) for this mode
      CloseButton   %Handle of the button widget for closing the tab
      
      % To be deleted
      TabVersion = 2;

      SHORTNAME = strings(0) %Short name of the mode, if any, used on the Close button
   end
   
   %Interface methods for matlab.mixin.HeterogeneousHandle
   methods(Sealed = true, Static = true, Access = protected)
      function obj = getDefaultScalarElement %#ok<STOUT>
         %GETDEFAULTSCALARELEMENT Create default object
         %
         
         %Note: We error in this method as we dont have a Mode subclass
         %that can be implemented. This means that while vectors/arrays
         %of Modes can be created, vector expansion is not supported.
         
         error(message('Controllib:general:UnexpectedError', ...
            'Vector expansion is not supported by the Mode class'))
      end
   end
   
   methods
      function set.Enabled(this,enabled)
         if ~isequal(this.Enabled_,enabled)
            setEnabled(this,enabled,false)
         end
      end
      
      function val = get.Enabled(this)
         val = this.Enabled_;
      end

      function btn = getCloseButton(this)
          % Some subclasses may need to switch the icon of the close button
          % to use an .SVG icon instead of the old CSS class based toolstrip
          % icon. In order to do this, the subclass will need to have the
          % handle of the button widget. Allow public access to the close
          % button via a get method.
          btn = this.CloseButton;
      end
      
      function addDataNameSection(this)
         % dataset name display section (sys id use)
         this.DataNameSection = ctrluis.toolstrip.dataprocessing.DatasetNameSection;
      end
      
   end
   
   methods(Hidden = true)
      function setModeManager(this,modemanager)
         %SETMODEMANAGER
         %
         %    setModeManager(obj,modemanager)
         %
         %    Set the Mode.ModeManager property value.
         %
         %    Inputs:
         %      obj         - ctrluis.toolstrip.Mode instance
         %      modemanager - ctrluis.toolstrip.ModeManager Instance
         
         this.ModeManager = modemanager;
      end
      function setEnabled(this,enabled,force)
         %SETENABLED
         %
         %    setEnabled(obj,enabled,[force])
         %
         %    Method to set the Mode.Enabled property value. If one is
         %    defined the method uses the Mode.ModeManager to change the
         %    mode enabled state. The method calls the
         %    Mode.enabledChanged method if the Mode.Enabled property
         %    value changes.
         %
         %    Inputs:
         %      obj     - ctrluis.toolstrip.Mode instance
         %      enabled - value to use to set the Mode.Enabled property
         %      force   - optional logical specifying whether to for the
         %                Mode.Enable property value to change to the
         %                specified enable value. If omitted the false
         %                is used.
         %
         
         if nargin < 3, force = false; end
         
         if isequal(this.Enabled,enabled)
            %Quick return, nothing to do
            return
         end
         
         if force || isempty(this.ModeManager)
            if ~enabled && ~cbPreClose(this)
               %Abort close
               return
            end
            this.Enabled_ = enabled;
            enabledChanged(this);
         else
            setModeState(this.ModeManager,this,enabled);
         end
      end
   end
   
   methods(Access = public)
      function tab = getModeTab(this)
         %GETMODETAB
         %
         %    tab = getModeTab(obj)
         %
         %    Return the toolstrip tab(s) associated with this mode. The
         %    method uses the Mode.getTabSection to populate the tab.
         %
         %    Inputs:
         %      obj - ctrluis.toolstrip.Mode instance
         %
         %    Outputs:
         %      tab - matlab.ui.internal.toolstrip.Tab instances
         
         if isempty(this.Tab)
            Tag = sprintf('tab%s(%s)',this.Name,datestr(now));
            createVersion2Tab(this, Tag);
         end
         tab = this.Tab;
      end
      function btn = getToggleButton(this)
         %GETTOGGLEBUTTON
         %
         %    btn = getToggleButton(obj)
         %
         %    Return a toolstrip button that can be used to togle the
         %    enable state of this mode.
         %
         %    Inputs:
         %      obj - ctrluis.toolstrip.Mode instance
         %
         %    Outputs:
         %      btn - ToggleButton instance
         %
    	 Icon = this.ICON;

         if ischar(Icon)
            Icon = ctrluis.toolstrip.dataprocessing.getIcon(Icon);
         end
         
         btn = matlab.ui.internal.toolstrip.ToggleButton(this.DISPLAYNAME, Icon);
         addlistener(btn,'ValueChanged', @(hSrc,hData) cbMode(this,hSrc));
      end
   end
   
   methods(Access = protected)
      function obj = Mode(varargin)
         %MODE Construct a Mode Instance.
         % obj = ctrluis.toolstrip.Mode;
         % obj = ctrluis.toolstrip.Mode('TabVersion',NUM); % null op
         obj.Name = 'unknown';
      end
      
      function sec = getTabSection(this) %#ok<MANU>
         %GETTABSECTION
         %
         %    sec = getTabSection(obj)
         %
         %    Return the toolstrip section(s) associated with this mode.
         %    This method is called by Mode.getModeTab to populate the
         %    mode tab.
         %
         %    Inputs:
         %      obj - ctrluis.toolstrip.Mode instance
         %
         %    Outputs:
         %      sec - a vector of matlab.ui.internal.toolstrip.Section instances
         %
         
         sec = [];
      end
      function cols = getColsInCloseSection(~)
          %    cols = getColsInCloseSection(obj)
         %
         %    Return additional cols to pre-append to the close section
         %
         %    Inputs:
         %      obj - ctrluis.toolstrip.Mode instance
         %
         %    Outputs:
         %      cols - a vector columns to add to the close section
         %
         % Add a close section to the tab
         cols = [];
      end
      function enabledChanged(this) %#ok<MANU>
         %ENABLEDCHANGED
         %
         %    enabledChanged(obj)
         %
         %    Method called when the model enabled state changes. This
         %    method is overridden by subclasses that need to perform
         
      end
      function cbCloseTab(this)
         %CBCLOSETAB
         %
         %
         this.Enabled = false;
      end
      function cbMode(this,hSrc)
         %CBMODE Manage mode button events
         %
         
         val = hSrc.Value;
         this.Enabled = val;
      end
      function ok = cbPreClose(this) %#ok<MANU>
         %CBPRECLOSE
         %
         %    ok = cbPreClose(obj)
         %
         %    React to mode close (enable=false) events to preempt the
         %    close if necessary. Default implementation is a no-op
         %    returning true, subclasses shoul overload as needed.
         %
         %    Inputs:
         %      obj - ctrluis.toolstrip.Mode instance
         %
         %    Outputs:
         %      ok - logical scalar, return true if it is ok to close
         %           the mode, false to abort the close
         %
         
         %Default implementation, ok to close
         ok = true;
      end
      
      function createVersion2Tab(this, Tag)
         tab = matlab.ui.internal.toolstrip.Tab(this.DISPLAYNAME);
         tab.Tag = Tag;
         
         sec = getTabSection(this);
         for ct = 1:numel(sec)
            add(tab,sec(ct));
         end
         
         % Add a close section to the tab
         secClose = matlab.ui.internal.toolstrip.Section(getString(message...
            ('Controllib:general:strClose')));
         secClose.Tag = 'secClose';
         
         % add cols to the close section
         cols = getColsInCloseSection(this);
         for col = cols(:)'
             add(secClose,col);
         end
         
         % add the close button to the close section
         if ~isempty(this.SHORTNAME)
           NAME = this.SHORTNAME;
         else
           NAME = this.DISPLAYNAME;
         end
         Icon = matlab.ui.internal.toolstrip.Icon('close');
         Text = getString(message('Controllib:general:strCloseItem', NAME));
         btn = matlab.ui.internal.toolstrip.Button(Text, Icon);
         btn.Tag = 'btnClose';
         Col = matlab.ui.internal.toolstrip.Column('HorizontalAlignment','center');
         Col.add(btn);
         add(secClose,Col);
         
         add(tab,secClose);
         weakThis = matlab.lang.WeakReference(this);
         addlistener(btn,'ButtonPushed', @(hSrc,hData) cbCloseTab(weakThis.Handle));
         
         this.Tab = tab;
         this.CloseButton = btn;
      end
   end
   
   methods (Hidden)
       function qeCloseTab(this)
           %QECLOSETAB Close tab
           %
           cbCloseTab(this);
       end
   end
end
