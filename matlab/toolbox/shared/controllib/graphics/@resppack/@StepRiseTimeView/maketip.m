function str = maketip(this,tip,info,CursorInfo)
%MAKETIP  Build data tips for SettleTimeView Characteristics.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Author(s): John Glass
%   Copyright 1986-2013 The MathWorks, Inc.

r = info.Carrier;
AxGrid = info.View.AxesGrid;

str = {getString(message('Controllib:plots:strResponseLabel',r.Name))};
[iotxt,ShowFlag] = rcinfo(r,info.Row,info.Col); 
if any(AxGrid.Size(1:2)>1) || ShowFlag 
    % Show if MIMO or non trivial 
    str{end+1,1} = iotxt; 
end

Time = info.View.Points(info.Row,info.Col).XData;
Factor = tunitconv(info.Data.TimeUnits,AxGrid.XUnits);
TLow = info.Data.TLow(info.Row,info.Col)*Factor;
THigh = info.Data.THigh(info.Row,info.Col)*Factor;
RT = Time - TLow;  % rise time estimate
if isinf(TLow)
   % Unstable
   str{end+1,1} =  getString(message('Controllib:plots:strRiseTimeLabel', ...
       AxGrid.XUnits, 'N/A'));
elseif isnan(TLow)
   % Has not reached low threshold yet
   str{end+1,1} = getString(message('Controllib:plots:strRiseTimeLabel', ...
       AxGrid.XUnits,sprintf('> %0.3g',Time)));
elseif isnan(THigh)
   % Has not reached high threshold yet
   str{end+1,1} = getString(message('Controllib:plots:strRiseTimeLabel', ...
       AxGrid.XUnits,sprintf('> %0.3g',RT)));
else
   % Fully risen
    str{end+1,1} = getString(message('Controllib:plots:strRiseTimeLabel', ...
       AxGrid.XUnits,sprintf('%0.3g',RT)));
end
