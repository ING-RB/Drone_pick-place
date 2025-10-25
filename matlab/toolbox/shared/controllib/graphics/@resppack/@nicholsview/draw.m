function draw(this, Data,~)
%DRAW  Draws Bode response curves.
%
%  DRAW(VIEW,DATA) maps the response data in DATA to the curves in VIEW.

%  Copyright 1986-2021 The MathWorks, Inc.
AxGrid = this.AxesGrid;
PhaseUnits = AxGrid.XUnits;
[Ny, Nu] = size(this.Curves);

% Collect data
Freq = Data.Frequency;
Mag = Data.Magnitude(:,:);
Phase = Data.Phase(:,:);
if isempty(Mag)
   set(double(this.Curves(:)), 'XData', [], 'YData', [])
   return
end

% Convert to current units
Mag   = unitconv(Mag, Data.MagUnits, 'dB');
Phase = unitconv(Phase, Data.PhaseUnits, PhaseUnits);

% Phase unwrapping
Pi = unitconv(pi, 'rad', AxGrid.XUnits);
WRAP = strcmp(this.UnwrapPhase, 'off') && ~isempty(this.PhaseWrappingBranch);
MATCH = strcmp(this.ComparePhase.Enable, 'on'); % phase matching
if WRAP
   Branch = unitconv(this.PhaseWrappingBranch,'rad',PhaseUnits);
end
if MATCH
   ax = AxGrid.getaxes; % Revisit
   h = gcr(ax(1));
   CF = this.ComparePhase.Freq * funitconv(h.FrequencyUnits,Data.FreqUnits);
end
   
% Draw curves
for ct = 1:Ny*Nu
   ph = Phase(:,ct);
   if MATCH
      % phase matching
      ix = findNearestMatch(Freq,ph,CF);
      if ~isempty(ix)
         ph = ph - (2*Pi) * round((ph(ix)-this.ComparePhase.Phase)/(2*Pi));
      end
   end
   if WRAP
      ph = mod(ph - Branch,2*Pi) + Branch;
   end
   set(double(this.Curves(ct)), 'XData', ph, 'YData', Mag(:,ct));
end


%------------------------------
function ix = findNearestMatch(f,ph,f0)
% Watch for NaN phase (causes entire curve to become NaN)
f(isnan(ph),:) = NaN;
[~,ix] = min(abs(flipud(f)-f0));  % favor positive match when tie
ix = numel(f)+1-ix;