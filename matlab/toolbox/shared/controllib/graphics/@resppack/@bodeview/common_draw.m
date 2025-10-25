function common_draw(this, Mag, Phase, Freq, Ts)
%DRAW  Draws Bode response curves.
%
%  DRAW(VIEW,DATA) maps the response data in DATA to the curves in VIEW.

%  Author(s): P. Gahinet
%  Copyright 1986-2021 The MathWorks, Inc.
if isempty(Mag)
   % NaN system
   set([this.MagCurves(:);this.MagNyquistLines(:);...
      this.PhaseCurves(:);this.PhaseNyquistLines(:)], 'XData', [], 'YData', [])
   return
end

AxGrid = this.AxesGrid;
[Ny, Nu] = size(this.MagCurves);
if Ts~=0
   nf = pi/abs(Ts)*funitconv('rad/s',AxGrid.XUnits);
end
LOG = strcmp(AxGrid.XScale{1},'log');
if LOG
   X = abs(Freq);
else
   X = Freq;
end

% Mag curves
for ct = 1:Ny*Nu
   % REVISIT: remove conversion to double (UDD bug where XOR mode ignored)
   set(double(this.MagCurves(ct)), 'XData', X, 'YData', Mag(:,ct));
end

% Phase curves
Pi = unitconv(pi,'rad',AxGrid.YUnits{2});
WRAP = strcmp(this.UnwrapPhase, 'off') && ~isempty(this.PhaseWrappingBranch);
MATCH = strcmp(this.ComparePhase.Enable, 'on'); % phase matching
if WRAP
   Branch = unitconv(this.PhaseWrappingBranch,'rad',AxGrid.YUnits{2});
end
for ct = 1:Ny*Nu
   ph = Phase(:,ct);
   if MATCH
      ix = findNearestMatch(Freq,ph,this.ComparePhase.Freq);
      if ~isempty(ix)
         ph = ph - (2*Pi) * round((ph(ix)-this.ComparePhase.Phase)/(2*Pi));
      end
   end
   if WRAP
      ph = mod(ph - Branch,2*Pi) + Branch;
   end
   set(double(this.PhaseCurves(ct)), 'XData', X, 'YData', ph);
end

% Nyquist lines (invisible to limit picker)
if Ts==0
   set([this.MagNyquistLines(:);this.PhaseNyquistLines(:)], 'XData', [], 'YData', [])
else
   YData = unitconv(infline(0,Inf),'abs',AxGrid.YUnits{1});
   XData = nf(:,ones(size(YData)));
   if ~LOG
      XData = [-XData NaN XData];  YData = [YData NaN YData];
   end
   set(this.MagNyquistLines,'XData',XData,'YData',YData)
   YData = infline(-Inf,Inf);
   XData = nf(:,ones(size(YData)));
   if ~LOG
      XData = [-XData NaN XData];  YData = [YData NaN YData];
   end
   set(this.PhaseNyquistLines,'XData',XData,'YData',YData)
end


%------------------------------
function ix = findNearestMatch(f,ph,f0)
% Watch for NaN phase (causes entire curve to become NaN)
f(isnan(ph),:) = NaN;
[~,ix] = min(abs(flipud(f)-f0));  % favor positive match when tie
ix = numel(f)+1-ix;