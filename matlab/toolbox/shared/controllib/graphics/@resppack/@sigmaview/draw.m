function draw(this, Data,~)
%DRAW  Draw method for the @sigmaview class (Singular Value Plots).

%  Author(s): Kamesh Subbarao, Pascal Gahinet
%  Copyright 1986-2021 The MathWorks, Inc.

%  Frequency:   Nf x 1
%  Singular Values: Nf x Ns
AxGrid = this.AxesGrid;
if Data.Ts
   nf = pi/abs(Data.Ts)*funitconv('rad/s',AxGrid.XUnits);
else
   nf = NaN;
end
REAL = Data.Real;
LOG = strcmp(AxGrid.XScale{1},'log');

% Access data
[Freq,SV] = getPlotData(Data,AxGrid.XScale{1});
% Store underlying (signed) frequency vector in Data units
this.Frequency = Freq;

% Plot 
if LOG
   Freq = abs(Freq);
end
Freq = Freq*funitconv(Data.FreqUnits,AxGrid.XUnits);
SV = unitconv(SV,Data.MagUnits,AxGrid.YUnits);
Ns = size(SV,2);

% Adjust number of SV curves and arrows
Curves = this.Curves;
PosArrows = this.PosArrows;
NegArrows = this.NegArrows;
Nline = numel(Curves);
if Ns>Nline
   % Add missing lines
   for ct=Ns:-1:Nline+1
      ax = Curves(1).Parent;
      Curves(ct,1) = controllibutils.utCustomCopyLineObj(Curves(1),ax);
      if ~REAL
         PosArrows(ct,1) = handle(copyobj(PosArrows(1),ax));
         NegArrows(ct,1) = handle(copyobj(NegArrows(1),ax));
      end
   end
   this.Curves = Curves;
   this.PosArrows = PosArrows;
   this.NegArrows = NegArrows;
end
   
% Singular value curves
for ct=1:Ns
   % REVISIT: remove conversion to double (UDD bug where XOR mode ignored)
   set(double(Curves(ct)), 'XData', Freq, 'YData', SV(:,ct));
end   
set(Curves(Ns+1:end),'XData',[],'YData',[])

% Nyquist lines (invisible to limit picker)
YData = unitconv(infline(0,Inf),'abs',AxGrid.YUnits);
XData = nf(:,ones(size(YData)));
if ~LOG
   XData = [-XData NaN XData];  YData = [YData NaN YData];
end
set(this.NyquistLine,'XData',XData,'YData',YData)
