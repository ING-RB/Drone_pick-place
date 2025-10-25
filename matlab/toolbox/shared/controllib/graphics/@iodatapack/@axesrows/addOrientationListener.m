function L = addOrientationListener(h, mSub)
% Listen to change in the value of "Orientation property of @plotrows
% instance used by the plot.

%  Copyright 2014 The MathWorks, Inc.

Ax = h.Axes;
L = handle.listener(Ax,...
   Ax.findprop('Orientation'),'PropertyPostSet',...
   {@localUpdateOrientationMenu mSub});

%--------------------------------------------------------------------------
function localUpdateOrientationMenu(~,eventData,menuVec)
% Updates I/O Grouping menu check
newOrient = eventData.Newvalue;
set(menuVec,'checked','off');
set(menuVec(strcmpi(newOrient,get(menuVec,{'Tag'}))),'checked','on');
