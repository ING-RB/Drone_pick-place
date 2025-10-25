function updatelims(this)
%UPDATELIMS  Custom limit picker.
%
%  UPDATELIMS(H) implements a custom limit picker for spectrum plots.
%  This limit picker
%     1) Computes an adequate X range from the data or source
%     2) Computes common Y limits across rows for axes in auto mode.

%  Author(s): P. Gahinet, Bora Eryilmaz
%  Copyright 1986-2011 The MathWorks, Inc.

AxGrid = this.AxesGrid;
% Update X range by merging time Focus of all visible data objects.
ax = getaxes(AxGrid,'2d');
AutoX = strcmp(AxGrid.XLimMode,'auto');
if any(AutoX)
   XRange = getfocus(this);
   % RE: Do not use SETXLIM in order to preserve XlimMode='auto'
   set(ax(:,AutoX),'Xlim',XRange)
end

% Update Y limits
AxGrid.updatelims('manual',[])

% Set minimum magnitude limits for ylim with auto if Min gain lvl is enabled
if isfield(this.Options,'MinGainLimit') && strcmp(this.Options.MinGainLimit.Enable,'on')
   LocalMinMag(this);
end

%------------------------- Local Functions -----------------------------
function LocalMinMag(this)
% Sets Lower magnitude limits for when Minimum gain lvl is set

ax = getaxes(this.Axesgrid);
magax = ax(:,:,1);
AutoY = strcmp(this.AxesGrid.YLimMode,'auto');
AutoY = AutoY(1:2:end);
for ct = 1:length(AutoY)
   if AutoY(ct)
      curylim = get(magax(ct,:),{'Ylim'});
      for ct2 = 1:length(curylim)
         curylim{ct2}(1)= this.Options.MinGainLimit.MinGain;
         if curylim{ct2}(1)>=curylim{ct2}(2)
            % Case when response upper auto limit is less then
            % MinGain limit
            curylim{ct2}(2) = curylim{ct2}(1) + 10;
         end
         set(magax(ct,ct2),'Ylim',curylim{ct2})
      end
   end
end