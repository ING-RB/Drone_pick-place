function draw(this, Data,NormalRefresh)
%DRAW  Draws root locus.
%
%  DRAW(VIEW,DATA) maps the data in DATA to the root locus in VIEW.

%  Author(s): P. Gahinet
%  Copyright 1986-2014 The MathWorks, Inc.
ax = getaxes(this.AxesGrid);
hPlot = gcr(ax(1));
if isequal(Data.Ts,0)
    Factor = tunitconv(hPlot.TimeUnits,Data.TimeUnits);
else
    Factor = 1;
end
% System dynamics
this.SystemZero.XData = real(Data.SystemZero)*Factor;
this.SystemZero.YData = imag(Data.SystemZero)*Factor;
this.SystemPole.XData = real(Data.SystemPole)*Factor;
this.SystemPole.YData = imag(Data.SystemPole)*Factor;

% Adjust number of locus curves
Nbranch = size(Data.Roots,2);
Nline = length(this.Locus);
if Nbranch>Nline
   % Add missing lines
   Locus = this.Locus;
   for ct=Nbranch:-1:Nline+1
      Locus(ct,1) = controllibutils.utCustomCopyLineObj(Locus(1),Locus(1).Parent);
   end
   this.Locus = Locus;
end

% Set line data
for ct=1:Nbranch
   set(this.Locus(ct),'XData',real(Data.Roots(:,ct))*Factor,'YData',imag(Data.Roots(:,ct))*Factor)
end
set(this.Locus(Nbranch+1:end),'XData',NaN,'YData',NaN)

% Branch coloring option
Ncolors = length(this.BranchColorList);
if Ncolors>0
   idx = 1+rem(0:Nbranch-1,Ncolors);
   for ct=1:Nbranch
      set(this.Locus(ct),'Color',this.BranchColorList{idx(ct)})
   end
end
