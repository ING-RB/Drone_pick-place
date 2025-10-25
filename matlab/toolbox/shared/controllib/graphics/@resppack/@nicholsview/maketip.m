function str = maketip(this,tip,info,CursorInfo)
%MAKETIP  Build data tips for @nicholsview curves.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Copyright 1986-2021 The MathWorks, Inc.
r = info.Carrier;
h = r.Parent;
AxGrid = h.AxesGrid;
pos = get(CursorInfo,'Position');

% Create tip text
str = {getString(message('Controllib:plots:strResponseLabel',r.Name))};
[iotxt,ShowFlag] = rcinfo(r,info.Row,info.Col);
if any(AxGrid.Size(1:2)>1) || ShowFlag
   % Show if MIMO or non trivial
   str = [str;{iotxt}];
end

FreqUnits = h.FrequencyUnits;
F = LocalInterpFreq(info.Data.Frequency,CursorInfo); % Data units
F = F * funitconv(info.Data.FreqUnits,FreqUnits);
str = [str ; ...
    {getString(message('Controllib:plots:strGainLabel', AxGrid.YUnits, ...
    sprintf('%0.3g',pos(2))));...
    getString(message('Controllib:plots:strPhaseLabel', AxGrid.XUnits, ...
    sprintf('%0.3g',pos(1))));...
    getString(message('Controllib:plots:strFrequencyLabel',FreqUnits,...
    sprintf('%0.3g',F)))}];

%%%%%%%%%%%%%%%%%%%%% Local Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   

function F = LocalInterpFreq(Freqs,CursorInfo)
% Interpolates frequency value in parametric plots
tau = CursorInfo.InterpolationFactor;
idx = CursorInfo.DataIndex;
if isequal(tau,0)
    F = Freqs(idx);
elseif tau > 0
    F = Freqs(idx) + tau * (Freqs(idx+1)-Freqs(idx));
else
    % case tau < 0
    F = Freqs(idx) + tau * (Freqs(idx)-Freqs(idx-1));        
end
