function str = maketip(this,tip,info,CursorInfo) %#ok<INUSL>
%MAKETIP  Build data tips for TimePeakRespView Characteristics.
%
%   INFO is a structure built dynamically by the data tip interface
%   and passed to MAKETIP to facilitate construction of the tip text.

%   Copyright 2013-2015 The MathWorks, Inc.

r = info.Carrier;
cData = info.Data;
AxGrid = info.View.AxesGrid;
pos = get(CursorInfo,'Position');

str{1,1} =  getString(message('Controllib:plots:lblDataset',r.Name));
[iotxt,ShowFlag] = rcinfo(r,info.Row,info.Col);
if any(AxGrid.Size(1:2)>1) || ShowFlag
   % Show if MIMO or non trivial
   str{end+1,1} = iotxt;
end

YNorm = strcmp(AxGrid.YNormalization,'on');
XDot = pos(1);
YDot = pos(2);
Ypeak = cData.PeakResponse{info.Row, info.Col};

if ~isscalar(Ypeak)
   [~, Dim] = min(abs(Ypeak-YDot));
else
   Dim = 1;
end

if YNorm
   XDot = cData.Time{info.Row,info.Col}(Dim)*...
      tunitconv(cData.TimeUnit{info.Row,info.Col},AxGrid.XUnits);
   YDot = Ypeak(Dim);
   
   % Parent axes and limits
   ax = info.View.Points(info.Row,info.Col).Parent;
   Xlim = get(ax,'Xlim');
   
   % Adjust dot position based on the X limits
   if strcmp(AxGrid.XlimMode{info.Col},'auto') && (XDot<Xlim(1) || XDot>Xlim(2) || isnan(XDot))
      XDot = max(Xlim(1),min(Xlim(2),XDot));
      allts = [cData.Parent.OutputData; cData.Parent.InputData];
      T0 = allts(info.Row).Time; Y0 = allts(info.Row).Data(:,Dim);
      TU = allts(info.Row).TimeInfo.Units;
      YDot = interp1(T0*tunitconv(TU, AxGrid.XUnits), Y0, XDot);
   end
end

if XDot == cData.Time{info.Row,info.Col}(Dim)*...
      tunitconv(cData.TimeUnit{info.Row,info.Col},AxGrid.XUnits)
   str{end+1,1} = getString(message('Controllib:plots:strPeakAmplitudeLabel', ...
      sprintf('%0.3g',YDot)));
   str{end+1,1} = getString(message('Controllib:plots:strAtTimeLabel', ...
      AxGrid.XUnits, sprintf('%0.3g', XDot)));
end
