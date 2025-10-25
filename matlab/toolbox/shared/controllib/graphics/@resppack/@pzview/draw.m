function draw(this, Data,NormalRefresh)
%  DRAW  Draw method for the @pzview class to generate the response curves.

%  Author(s): John Glass, Bora Eryilmaz, Kamesh Subbarao
%  Copyright 1986-2010 The MathWorks, Inc.

% Recompute the curves
ax = getaxes(this.AxesGrid);
hPlot = gcr(ax(1));
if isequal(Data.Ts,0)
    Factor = tunitconv(hPlot.TimeUnits,Data.TimeUnits);
else
    Factor = 1;
end
for ct = 1:prod(size(Data.Poles))
   set(double(this.PoleCurves(ct)), 'XData', real(Data.Poles{ct})*Factor, ...
      'YData', imag(Data.Poles{ct})*Factor);
   set(double(this.ZeroCurves(ct)), 'XData', real(Data.Zeros{ct})*Factor, ...
      'YData', imag(Data.Zeros{ct})*Factor);
end
