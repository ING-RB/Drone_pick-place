function mRoot = addGroupingMenu(this)
% Add IO grouping menu.

%  Copyright 2015 The MathWorks, Inc.

% I/O grouping menu
AxGrid = this.AxesGrid;
mRoot = uimenu('Parent',AxGrid.UIContextMenu,...
   'Label',getString(message('Controllib:plots:strIOGrouping')), ...
   'Tag','iogrouping');
mSub = [...
   uimenu('Parent',mRoot, ...
   'Label',getString(message('Controllib:plots:strNone')), ...
   'Tag','none',...
   'Callback',{@localGroupIOs this 'none'});...
   uimenu('Parent',mRoot, ...
   'Label',getString(message('Controllib:plots:strAll')), ...
   'Tag','all',...
   'Callback',{@localGroupIOs this 'all'});...
   ];
% Initialize submenus
set(mSub(strcmpi(this.IOGrouping,get(mSub,{'Tag'}))),'checked','on');

% Listen to changes in the IOGrouping property of the plot
L = handle.listener(this,this.findprop('IOGrouping'),...
   'PropertyPostSet',{@localSyncIOGrouping mSub});
ud = get(mRoot,'UserData');
set(mRoot,'UserData',[ud; L]);

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

