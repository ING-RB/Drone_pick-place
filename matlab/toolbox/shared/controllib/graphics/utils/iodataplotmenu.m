function hmenu = iodataplotmenu(hplot,plotType)
%IODATAPLOTMENU  Constructs right-click menus for I/O data plots.
% plotType: 'time' or 'frequency'; REVISIT (which options are affected?)

%  Copyright 2013-2015 The MathWorks, Inc.

% Return a structure with fields set to the appropriate meu handles for
% each item.
if strcmpi(plotType,'frequency')
   hmenu = localFreqPlotMenu(hplot);
else
   hmenu = localTimePlotMenu(hplot);
end

%--------------------------------------------------------------------------
function hmenu = localTimePlotMenu(hplot)
% menu for time domain plots

AxGrid = hplot.AxesGrid;
hmenu = struct(...
   'Datasets',[],...
   'Characteristics',[], ...
   'Group1', []);

% Group #1: Data contents (waves & characteristics)
hmenu.Systems = hplot.addMenu('datasets',...
   'Label',getString(message('Controllib:plots:strDatasets')));
grp1 = hmenu.Systems;

% Create a Characteristics menu
hmenu.Characteristics = hplot.addMenu('characteristics');
grp1(end+1) = hmenu.Characteristics;
hplot.registerCharMenu(hmenu.Characteristics)
hmenu.Group1 = grp1;

% Group #2: Axes configuration, I/O and model selectors
grp2 = [...
   hplot.addMenu('orientation'); ...
   iodatapack.addGroupingMenu(hplot); ...
   hplot.addMenu('ioselector');];

LocalUpdateVis(AxGrid,grp2,grp1)  % initialize menu visibility

% Install listener to track plot size and update menu visibility
set(grp2(3),'UserData',handle.listener(AxGrid,...
   AxGrid.findprop('Size'),'PropertyPostSet',@(x,y) LocalUpdateVis(AxGrid,grp2)))

% Group #3: Annotation and Focus
AxGrid.addMenu('grid','Separator','on');

% Zoom and full view
hplot.addMenu('normalize');
hplot.addMenu('fullview');

% Add properties menu
grp3 = handle(hplot.addMenu('properties'));
set(grp3(1),'Separator','on');

%--------------------------------------------------------------------------
function hmenu = localFreqPlotMenu(hplot)
% menu for frequency domain plots

AxGrid = hplot.AxesGrid;
hmenu = struct(...
   'Systems',[],...
   'Characteristics',[], ...
   'Group1', []);

% Group #1: Data contents (waves & characteristics)
hmenu.Systems = hplot.addMenu('responses',...
   'Label',getString(message('Controllib:plots:strSystems')));
grp1 = hmenu.Systems;

% Create a Characteristics menu
hmenu.Characteristics = hplot.addMenu('characteristics');
grp1(end+1) = hmenu.Characteristics;
hplot.registerCharMenu(hmenu.Characteristics)

% Show mag/phase
grp1(end+1) = hplot.addBodeMenu('show');
hmenu.Group1 = grp1;


% Group #2: Axes configuration, I/O and model selectors
grp2 = [...
   iodatapack.addOrientationMenu(hplot);...
   iodatapack.addGroupingMenu(hplot); ...
   hplot.addMenu('ioselector')]; % hplot.addMenu('arrayselector')

LocalUpdateVis(AxGrid,grp2,grp1)  % initialize menu visibility

% Install listener to track plot size and update menu visibility
L = handle.listener(AxGrid,AxGrid.findprop('Size'),'PropertyPostSet',...
   @(x,y) LocalUpdateVis(AxGrid,grp2,grp1));
ud = get(grp2(2),'UserData');
set(grp2(2),'UserData',[ud; L]);

% Group #3: Annotation and Focus
AxGrid.addMenu('grid','Separator','on');

hplot.addMenu('fullview');

grp3 = handle(hplot.addMenu('properties'));
set(grp3(1),'Separator','on');

%--------------------------------------------------------------------------
function LocalUpdateVis(AxGrid,MenuHandles, Previous)
% Initializes and updates visibility of "MIMO" menus
set([Previous(end);MenuHandles],'Separator','off')
iosize = AxGrid.RowLen;

if sum(iosize)<=1 % single axes or no axes
   set(MenuHandles(1:3),'Visible','off')
   set(Previous(end),'Separator','on')
elseif all(iosize<=1) % SISO
   set(MenuHandles(2),'Visible','off')
   set(MenuHandles(1),'Separator','on')
else
   set(MenuHandles(1:3),'Visible','on')
   set(MenuHandles(1),'Separator','on')
end

mSub = [findobj(MenuHandles(1).Children,'tag','2row');...
   findobj(MenuHandles(1).Children,'tag','2col')];
if any(iosize==0) || all(iosize<=1)
   % nonscalar output-only or input-only, or SISO
   set(mSub(1:2),'Visible','off')
else
   set(mSub(1:2),'Visible','on')
end

