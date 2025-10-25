function mRoot = addMenu(this,menuType,varargin)
%ADDMENU  Adds response plot menu.
%
%   hMENU = ADDMENU(rPlot,MenuType) adds or finds a menu hMENU of
%   type MENUTYPE.  Built-in menu types for response plots include:
%      'characteristics'    plot characteristics
%      'fullview'           zoom out
%      'grid'               toggle grid on/off
%      'iogrouping'         group axes
%      'ioselector'         launch I/O selector GUI
%      'normalize'          normalize plot data (time plots only)
%      'datasets'           toggle response visibility
%      'properties'         launch property editor
%
%   HMENU = ADDMENU(rPlot,MenuType,'Property1',Value1,...)
%   further specifies settings for the menu HMENU.

%  Copyright 2013-2014 The MathWorks, Inc.

% Create or identify (if one already exists) a context menu for a
% @iotimeplot object of type menuType. Return an array of handles m, where
% m(1) identifies the parent context menu of type menuType, and m(2:end)
% are handles to the children of m(1).
AxGrid = this.AxesGrid;
mRoot = AxGrid.findMenu(menuType);  % search for specified menu (HOLD support)
if ~isempty(mRoot)
   return
end

% Create menu if it does not already exist
switch menuType      
   case 'ioselector'
      %if there is no system menu then create it
      mRoot = uimenu('Parent', AxGrid.UIContextMenu, ...
         'Label',getString(message('Controllib:plots:strIOSelectorLabel')),...
         'Callback',{@localCreateIOSelector this},'Tag','ioselector');
      
   case 'datasets'
      mRoot = this.addContextMenu('waveforms',this.findprop('Waves'));
      
   case 'showinput'
      % Used by pid tuner
      mRoot = uimenu('Parent', AxGrid.UIContextMenu, ...
         'Label',getString(message('Controllib:plots:strShowInput')),...
         'Callback',{@localShowInput this},'Tag','showinput');
   case 'orientation'
      mRoot = iodatapack.addOrientationMenu(this);
   otherwise
      % Generic @wrfc/@plot menus
      % REVISIT: ::addMenu
      mRoot = this.addContextMenu(menuType);
end

% Apply menu settings
if ~isempty(varargin)
   set(mRoot,varargin{:})
end


%-------------------- Local Functions -------------------------------------
function localCreateIOSelector(~,~,this)
% Build I/O selector if does not exist
if isempty(this.AxesGrid.AxesSelector)
   this.AxesGrid.AxesSelector = this.addioselector;
end
set(this.AxesGrid.AxesSelector,'visible','on');

%--------------------------------------------------------------------------
function localGroupIOs(~, ~,this,newval)
% Set I/O grouping state
this.IOGrouping = newval;

%--------------------------------------------------------------------------
function localSyncIOGrouping(~,eventData,menuVec)
% Updates I/O Grouping menu check
newGrouping = eventData.Newvalue;
set(menuVec,'checked','off');
set(menuVec(strcmpi(newGrouping,get(menuVec,{'Tag'}))),'checked','on');

%--------------------------------------------------------------------------
function localShowInput(es,~,this)
% Show or hide input axes. This is for PID (SISO) case only where IO
% selector is not offered. 

if this.IOSize(2)>0
   I = this.IOSize(1)+1;
   if strcmp(this.AxesGrid.RowVisible{I},'off')
      this.AxesGrid.RowVisible{2} = 'on';
      set(es,'Checked','on')
   else
      this.AxesGrid.RowVisible{I} = 'off';
      set(es,'Checked','off')
   end
end
