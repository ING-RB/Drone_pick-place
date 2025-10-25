function mRoot = addMenu(this,menuType,varargin)
%ADDMENU  Install generic wave plot menus.

%  Author(s): James Owen and P. Gahinet
%  Copyright 1986-2010 The MathWorks, Inc.

AxGrid = this.AxesGrid;
mRoot = AxGrid.findMenu(menuType);  % search for specified menu (HOLD support)
if ~isempty(mRoot)
   return
end

% Create menu if it does not already exist
switch menuType
   
case 'channelgrouping'
   % I/O grouping menu
   %Assign callbacks and labels
   mRoot = uimenu('Parent',AxGrid.UIContextMenu,...
      'Label',getString(message('Controllib:plots:strChannelGrouping')), ...
      'Tag','channelgrouping');
   mSub = [...
         uimenu('Parent',mRoot, ...
         'Label',getString(message('Controllib:plots:strNone')), ...
         'Tag','none',...
         'Callback',{@localGroupChannels this 'none'});...
         uimenu('Parent',mRoot, ...
         'Label',getString(message('Controllib:plots:strAll')), ...
         'Tag','all',...
         'Callback',{@localGroupChannels this 'all'})];
   %initialize submenus
   set(mSub(strcmpi(this.ChannelGrouping,get(mSub,{'Tag'}))),'checked','on');
   
   %listen to changes in the axesgroup property of the AxesGrid
   L = handle.listener(this,this.findprop('ChannelGrouping'),...
      'PropertyPostSet',{@localSyncGrouping mSub});
   set(mRoot,'Userdata',L);
   
   
case 'channelselector' 
   %if there is no system menu then create it
   mRoot=uimenu('Parent', AxGrid.UIContextMenu, ...
       'Label',getString(message('Controllib:plots:strChannelSelectorLabel')),...
      'Callback',{@localCreateSelector this},'Tag','channelselector');
   
case 'waves'
   mRoot = this.addContextMenu('waveforms',this.findprop('Waves'));
   
otherwise
   % Generic @wrfc/@plot menus
   % REVISIT: ::addMenu
   mRoot = this.addContextMenu(menuType);
   
end

% Apply menu settings
if ~isempty(varargin)
   set(mRoot,varargin{:})
end

%-------------------- Local Functions ---------------------------

function localCreateSelector(~,~,this)
% Build I/O selector if does not exist
if isempty(this.AxesGrid.AxesSelector)
   this.AxesGrid.AxesSelector = addChannelSelector(this);
end
set(this.AxesGrid.AxesSelector,'visible','on');


function localGroupChannels(~, ~,this,newval)
% Set I/O grouping state
this.ChannelGrouping = newval;


function localSyncGrouping(~,eventData,menuVec)
% Updates I/O Grouping menu check
newGrouping = eventData.Newvalue;
set(menuVec,'checked','off');
set(menuVec(strcmpi(newGrouping,get(menuVec,{'Tag'}))),'checked','on');
