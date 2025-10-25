function updatelims(this)
%UPDATELIMS  Limit picker for time plots.
%
%   UPDATELIMS(H) computes:
%     1) an adequate X range from the data or source
%     2) common Y limits across rows for axes in auto mode.

%  Copyright 2013 The MathWorks, Inc.

AxesGrid = this.AxesGrid;
% Update X range by merging time Focus of all visible data objects.
% RE: Do not use SETXLIM in order to preserve XlimMode='auto'
% REVISIT: make it unit aware
ax = getaxes(this);
AutoX = strcmp(AxesGrid.XLimMode,'auto');
if any(AutoX)
   set(ax(:,AutoX),'Xlim', getfocus(this));
end

% Update Y limits
if strcmp(AxesGrid.YNormalization,'on')
   % Reset auto limits to [-1,1] range
   set(ax(strcmp(AxesGrid.YLimMode,'auto'),:),'Ylim',[-1.1 1.1])
else
   % Update Y limits
   AxesGrid.updatelims('manual',[])
end
