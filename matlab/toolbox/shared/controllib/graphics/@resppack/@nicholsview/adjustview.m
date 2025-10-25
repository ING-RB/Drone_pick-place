function adjustview(this,Data,Event,NormalRefresh) %#ok<INUSD>
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits. 
%
%  ADJUSTVIEW(VIEW,DATA,'prelim') hides HG objects that might interfer with 
%  limit picking.
%
%  ADJUSTVIEW(VIEW,DATA,'postlimit') adjusts the HG object extent once the 
%  axes limits have been finalized (invoked in response, e.g., to a 
%  'LimitChanged' event).

%  Author(s): P. Gahinet, B. Eryilmaz
%  Copyright 1986-2021 The MathWorks, Inc.
if isempty(Data.Magnitude)
   % NaN system
   set(double(this.Curves(:)), 'XData', [], 'YData', [])
else
   switch Event
      case 'prelim'
         % Frequency focus
         Curves = this.Curves;
         if Data.SoftFocus
            % Quasi-integrator/derivator or pure gain: Limit visible mag range
            MagUnits = this.AxesGrid.YUnits;
            for ct = 1:numel(Curves)
               LocalShowMagRange(Curves(ct),MagUnits)
            end
         else
            % Other cases: Show frequency range of interest
            w = abs(Data.Frequency);
            LocalShowFreqRange(Curves, (w>=Data.Focus(1) & w<=Data.Focus(2))')
         end
      case 'postlim'
         % Restore nichols curves to their full extent
         draw(this, Data)
   end
end


% --------------------------------------------------------------------------- %
% Local Functions
% --------------------------------------------------------------------------- %
function LocalShowFreqRange(Curves, Include)
% Clips response to a given frequency range
npts = numel(Include);
idx = find(Include);
for ct = 1:numel(Curves)
   h = Curves(ct);
   ydata = get(h, 'YData');
   if length(ydata) == npts  % watch for exceptions (ydata=NaN)
      xdata = get(h, 'XData');
      set(double(h),'XData', xdata(idx), 'YData', ydata(idx))
   end
end


function LocalShowMagRange(h, MagUnits)
% Clips response to show only portion in [-30,30] dB mag range
% nichols(tf(1,[1 0 0 eps^2]))
% nichols(tf(1e-10,[1 1e-10]))
% nichols(tf(1e5,[1 1e-10]))
xdata = h.XData;
ydata = unitconv(h.YData,MagUnits,'dB');

% Determine mag range [GMIN,GMAX] to focus on 
gmin = min(ydata);
gmax = max(ydata);
if gmin>20
   gmax = gmin + 40;
elseif gmax<-20
   gmin = gmax - 40;
else
   gmin = max(-30,gmin);
   gmax = min(30,gmax);
end

% Force gain data to range [GMIN,GMAX]
ydata(ydata<gmin) = gmin;
ydata(ydata>gmax) = gmax;
set(double(h),'XData', xdata, 'YData', unitconv(ydata,'dB',MagUnits))
