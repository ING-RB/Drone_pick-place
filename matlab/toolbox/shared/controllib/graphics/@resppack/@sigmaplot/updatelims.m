function updatelims(this)
%  UPDATELIMS  Custom limit picker.
%
%  UPDATELIMS(H) implements a custom limit picker for Singular Value plots. 
%  This limit picker
%     1) Computes an adequate X range from the data or source
%     2) Computes common Y limits across rows for axes in auto mode.

%  Author(s): K. Subbarao
%  Copyright 1986-2021 The MathWorks, Inc.
AxGrid = this.AxesGrid;
ax = getaxes(AxGrid);

% Determine XLimMode
AutoX = strcmp(AxGrid.XLimMode,'auto');
if ~AutoX && strcmp(AxGrid.XScale,'log') && ax.XLim(1)<=0
   % Negative limits -> switch back to auto mode
   AxGrid.XLimMode = 'auto';
   AutoX = true;
end

% Update X range by merging time Focus of all visible data objects.
if AutoX
   XRange = getfocus(this);
   % RE: Do not use SETXLIM in order to preserve XlimMode='auto'
   set(ax, 'Xlim', XRange);
end

% Update Y limits
AxGrid.updatelims('manual', [])
