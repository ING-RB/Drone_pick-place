function str = maketip_p(this,tip,info,fUnits,mUnits,pUnits)
%MAKETIP  Build data tips for StabilityMarginView Characteristics.

%   Author(s): John Glass
%   Copyright 1986-2013 The MathWorks, Inc. 

% REVISIT: rename to MAKETIP when superclass::method call available
r = info.Carrier;
str{1,1} = getString(message('Controllib:plots:strResponseLabel',r.Name));

% Get the UserData from the host to get the marker index
% Note: Can be a multi-index for open markers showing margins out of scope
MarkerIndex = tip.UserData;

if info.MarginType == 1
   % Convert Gain Margin Frequency from rad/s to Axis Grid XUnits
   GM = info.Data.GainMargin(MarkerIndex);
   wGM = info.Data.GMFrequency(MarkerIndex);
   [~,imin] = min(abs(mag2db(GM)));
   XData = wGM(imin)*funitconv(info.Data.FreqUnits,fUnits);
   XData = sprintf('%0.3g',XData);
   % Convert Gain Margin from abs to Axis Grid YUnits{1}
   YData = unitconv(GM(imin),'abs',mUnits);
   YData = sprintf('%0.3g',YData);
   str{end+1,1} = getString(message('Controllib:plots:strGainMarginLabel', mUnits, YData));
   str{end+1,1} = getString(message('Controllib:plots:strAtFrequencyLabel', fUnits, XData));
   
else
   % Convert Phase Margin Frequency from rad/s to Axis Grid XUnits
   PM = info.Data.PhaseMargin(MarkerIndex);
   wPM = info.Data.PMFrequency(MarkerIndex);
   [~,imin] = min(abs(PM));
   XData = wPM(imin)*funitconv(info.Data.FreqUnits,fUnits);
   XData = sprintf('%0.3g',XData);
   % Convert Phase Margin from deg to Axis Grid YUnits{2}
   YData = unitconv(PM(imin),'deg',pUnits);
   YData = sprintf('%0.3g',YData);
   % Delay margins
   DelayData = info.Data.DelayMargin(MarkerIndex(imin));
   str{end+1,1} = getString(message('Controllib:plots:strPhaseMarginLabel',pUnits,YData));
   % If the system is discrete, then display the units to be samples.
   % Otherwise use seconds.
   if info.Data.Ts
       DelayData = sprintf('%0.3g',DelayData);
       str{end+1,1} = getString(message('Controllib:plots:strDelayMarginLabel', 'samples',DelayData));
   else
       DelayData = sprintf('%0.3g',DelayData*tunitconv(info.Data.TimeUnits,'seconds'));
       str{end+1,1} = getString(message('Controllib:plots:strDelayMarginLabel', 'sec', DelayData));
   end   
   str{end+1,1} = getString(message('Controllib:plots:strAtFrequencyLabel',fUnits, XData));
end


if isempty(info.Data.Stable) || isnan(info.Data.Stable) 
   Stable = 'Not known';
elseif info.Data.Stable
   Stable = getString(message('Controllib:plots:strYes'));
else
   Stable = getString(message('Controllib:plots:strNo'));
end
str{end+1,1} = getString(message('Controllib:plots:strClosedLoopStableLabel',Stable));
