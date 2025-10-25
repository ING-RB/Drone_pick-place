function str = maketip(this,tip,info,CursorInfo)
%MAKETIP  Build data tips for @rlview curves.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Author(s): John Glass
%   Copyright 1986-2013 The MathWorks, Inc.


r = info.Carrier;
h = r.Parent;
AxGrid = h.AxesGrid;
pos = get(CursorInfo,'Position');

% Create tip text

% Pole location
x = pos(1);
y = pos(2);
z = complex(x,y);
polestr = getString(message('Controllib:plots:strPole'));
if y>0
    pstr = sprintf('%s: %0.3g + %0.3gi',polestr,x,y);
elseif y<0
    pstr = sprintf('%s: %0.3g - %0.3gi',polestr,x,-y);
else
    pstr = sprintf('%s: %0.3g',polestr,x);
end

% Gain value
data = info.Data;
den = data.SystemGain*prod(data.SystemZero-z);
if den==0
    g = Inf;
else
    g = abs(prod(data.SystemPole-z)/den);
end

% Damping/Frequency values
[wn,zeta] = damp(z,data.Ts);
wn = wn*funitconv('rad/TimeUnit',h.FrequencyUnits,h.TimeUnits);

% Percentage Peak Overshoot
if abs(zeta)==1
    ppo = 0;
else
    ppo = exp(-pi*zeta/sqrt((1-zeta)*(1+zeta))); % equiv to exp(-z*pi/sqrt(1-z^2))
    ppo = round(1e6*ppo)/1e4; % round off small values
end

str = {getString(message('Controllib:plots:strResponseLabel',r.Name));...
      getString(message('Controllib:plots:strGainLabel2',sprintf('%0.3g',g)));...
      pstr;...
      getString(message('Controllib:plots:strDampingLabel',sprintf('%0.3g',zeta)));...
      getString(message('Controllib:plots:strOvershootLabel', sprintf('%0.3g',ppo)));...
      getString(message('Controllib:plots:strFrequencyLabel',h.FrequencyUnits,sprintf('%0.3g',wn)))};
