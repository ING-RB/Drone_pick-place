function str = maketip(this,~,info,CursorInfo)
%MAKETIP  Build data tips for @nyquistview curves.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Copyright 1986-2021 The MathWorks, Inc.

r = info.Carrier;
h = r.Parent;
AxGrid = h.AxesGrid;
pos = get(CursorInfo,'Position');

% Create tip text
str{1,1} = getString(message('Controllib:plots:strResponseLabel',r.Name));
[iotxt,ShowFlag] = rcinfo(r,info.Row,info.Col);
if any(AxGrid.Size(1:2)>1) || ShowFlag
   % Show if MIMO or non trivial
   str{end+1,1} = iotxt;
end

Freqs = this.Frequency;
FreqUnits = h.FrequencyUnits;
tau = CursorInfo.InterpolationFactor;
idx = CursorInfo.DataIndex;
if tau>=0
   F = (1-tau) * Freqs(idx) + tau * Freqs(idx+1);
else
   F = (1+tau) * Freqs(idx) - tau * Freqs(idx+1);
end
F = unitconv(F,info.Data.FreqUnits,FreqUnits);
str = [str ; ...
      {getString(message('Controllib:plots:strRealLabel', ...
      sprintf('%0.3g',pos(1))));...
      getString(message('Controllib:plots:strImagLabel', ...
      sprintf('%0.3g',pos(2))));...
      getString(message('Controllib:plots:strFrequencyLabel',FreqUnits,...
      sprintf('%0.3g',F)))}];