function updatelims(this)
%  UPDATELIMS  Custom limit picker.
%
%  UPDATELIMS(H) implements a custom limit picker for Singular Value plots. 
%  This limit picker
%     1) Computes an adequate X range from the data or source
%     2) Computes common Y limits across rows for axes in auto mode.

%  Copyright 1986-2014 The MathWorks, Inc.
AxGrid = this.AxesGrid;
ax = getaxes(AxGrid);

% Determine XLimMode
AutoX = strcmp(AxGrid.XLimMode,'auto');
if ~AutoX && strcmp(AxGrid.XScale,'log') && ax(1).XLim(1)<=0
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

% Adjust Y limits
if strcmp(AxGrid.YLimMode{1}, 'auto')
   % Mag limits
   YLim = ax(1).YLim;
   switch AxGrid.YUnits{1}
      case 'abs'
         MagLim = [1 min(100,max(YLim(2),5))];
      case 'dB'
         MagLim = [0 min(40,10*ceil(YLim(2)/10))];
   end
   set(ax(1),'YLim',MagLim)
end
if strcmp(AxGrid.YLimMode{2}, 'auto')
   % Phase limits
   PhaseLim = ax(2).YLim;
   switch AxGrid.YUnits{2}
      case 'deg'
         if isempty(this.Responses)
            PhaseLim = [0,90];
         else
            PhaseLim(1) = max(0,10*floor(PhaseLim(1)/10));
            PhaseLim(2) = min(180,10*ceil(PhaseLim(2)/10));
         end
      case 'rad'
         if isempty(this.Responses)
            PhaseLim = [0,pi/2];
         end
   end
   set(ax(2),'YLim',PhaseLim)
end
