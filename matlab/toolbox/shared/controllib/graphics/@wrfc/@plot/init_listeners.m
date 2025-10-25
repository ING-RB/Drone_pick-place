function init_listeners(this)
%INIT_LISTENERS  Installs generic listeners for @plot class.

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2014 The MathWorks, Inc.

AxGrid = this.AxesGrid;
container    = AxGrid.Parent;
StyleMgr = this.StyleManager;

L = [handle.listener(AxGrid, 'ObjectBeingDestroyed', @LocalDelete); ...
      handle.listener(AxGrid, 'PostLimitChanged',     @LocalAdjustView); ...
      handle.listener(this,   'ObjectBeingDestroyed', @LocalCleanUp); ...
      handle.listener(AxGrid, 'DataChanged', @LocalRedraw); ...
      handle.listener(this, this.findprop('Visible'), ...
      'PropertyPostSet', @LocalRefreshPlot); ...
      handle.listener(this, this.findprop('Options'), ...
      'PropertyPostSet', @LocalOptions);...
      handle.listener(StyleMgr, StyleMgr.findprop('Styles'), ...
      'PropertyPostSet', @updatestyle) ];
set(L, 'CallbackTarget', this);

% HG Listener
visiblelistener = addlistener(container,'Visible', 'PostSet', ...
    @(es,ed) LocalRefreshPlot(this,ed));




% REVISIT: should listen to ClearAxes event (hg.axes) and remove 
% ResponsePlotHandle field from axes appdata.
this.Listeners.deleteListeners;
this.Listeners.addListeners(L);
this.Listeners.addListeners(visiblelistener);




% ----------------------------------------------------------------------------%
% Local Functions
% ----------------------------------------------------------------------------%

% ----------------------------------------------------------------------------%
% Purpose: Adjust view in response to axes limit update
% ----------------------------------------------------------------------------%
function LocalAdjustView(this, eventdata)
if strcmp(this.Visible,'on')
   allwf = allwaves(this);
   if ~isempty(allwf)
      for wf = find(allwf,'Visible','on')'
         adjustview(wf,'postlim')
      end
   end
end


% ----------------------------------------------------------------------------%
% Purpose: Updates visibility of HG objects (axes, curves) when 
%          AxesGrid visibility changes
% ----------------------------------------------------------------------------%
function LocalRefreshPlot(this,eventdata)
% Update component visibility
AxGrid = this.AxesGrid;
if strcmp(this.Visible,'off')
   % on -> off
   % Rely on ContentsVisible property of hg.axes to hide everything
   AxGrid.Visible = 'off';
else
   % off -> on
   % Refresh visibility of HG components (see plot/refresh for rationale)
   refresh(this)
   % Make axes grid visible
   % RE: Turn off limit manager to block ViewChanged callback
   AxGrid.LimitManager = 'off';
   AxGrid.Visible = 'on';
   AxGrid.LimitManager = 'on';
   % Redraw since curves stop tracking data when plot not visible
   % RE: Issues ViewChanged event that triggers limit update
   draw(this)
end


% ----------------------------------------------------------------------------%
% Purpose: Clean up @plot object when @axesgrid object is deleted.
% ----------------------------------------------------------------------------%
function LocalDelete(this, eventdata)
delete(this(ishandle(this)))


% ---------------------------------------------------------------------------% 
% Purpose: Clean up when @plot object is destroyed. 
% ---------------------------------------------------------------------------% 
function LocalCleanUp(this, eventdata) 
this.cleanup;
% delete(this.AxesGrid(ishandle(this.AxesGrid)))  
% wfs = allwaves(this);
% delete(wfs(ishandle(wfs))) 
% this.Listeners.deleteListeners;


% ---------------------------------------------------------------------------% 
% Purpose: Redraw plot when receiving DataChanged event 
%          (e.g., when changing units, toggling Y normalization)
% ---------------------------------------------------------------------------% 
function LocalRedraw(this,eventdata)
% Update labels (e.g., to track new units or transforms)
setlabels(this.AxesGrid)
% Redraw (updates axes contents & limits)
draw(this)


% ---------------------------------------------------------------------------% 
% Purpose: Apply changes to Options.
% ---------------------------------------------------------------------------% 
function LocalOptions(this, eventdata)
Opts = this.Options;

for wf = allwaves(this)'  % @waveform
   applyOptions(wf, Opts)
end
draw(this);



