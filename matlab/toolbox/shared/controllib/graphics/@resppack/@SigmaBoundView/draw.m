function draw(this, Data,~)
%DRAW  Draw method for the @sigmaview class (Singular Value Plots).

%  Author(s): Kamesh Subbarao, Pascal Gahinet
%   Copyright 1986-2014 The MathWorks, Inc.

%  Frequency:   Nf x 1
%  Singular Values: Nf x Ns

AxGrid = this.AxesGrid;
YUnits = AxGrid.YUnits;
if ~strcmp(YUnits,'dB')
   % To accomodate deg/dB in TuningGoal.Margins view
   YUnits = 'abs';
end

% Adjust number of SV curves
Ns = size(Data.SingularValues,2);
Nline = length(this.Curves);
if Ns>Nline
   % Add missing lines
   Curves = this.Curves;
   for ct=Ns:-1:Nline+1
      ax = Curves(1).Parent;
      Curves(ct,1) = controllibutils.utCustomCopyLineObj(Curves(1),ax);
   end
   this.Curves = Curves;
end
   
Freq = Data.Frequency*funitconv(Data.FreqUnits,AxGrid.XUnits);
SV = unitconv(Data.SingularValues,Data.MagUnits,YUnits);

% Eliminate zero frequencies in log scale
if strcmp(AxGrid.XScale,'log')
   idxf = find(Freq>0);
   Freq = Freq(idxf);
   SV = SV(idxf,:);
end

% Map data to curves
% Use offset for limit picking to prevent lines from being on axis edge
for ct=1:Ns
   % REVISIT: remove conversion to double (UDD bug where XOR mode ignored)
   XData = [Freq;Freq(end:-1:1)];
   ZData = this.ZLevel * ones(size(XData));
   if strcmp(YUnits,'abs')
      YData = [1.5*SV(:,ct);SV(end:-1:1,ct)/1.5];
   else
      YData = [SV(:,ct)-3.5;SV(end:-1:1,ct)+3.5];
   end
   set(double(this.Curves(ct)), 'XData', XData, 'YData', YData,'ZData',ZData);
end   
set(this.Curves(Ns+1:end),'XData',[],'YData',[],'ZData',[])
