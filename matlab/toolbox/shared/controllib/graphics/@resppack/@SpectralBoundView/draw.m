function draw(this,Data,~)
%DRAW  Draws uncertain view

%   Author(s): Craig Buhr
%   Copyright 1986-2013 The MathWorks, Inc.

% Set ZLevel for bounds to be below the grid
ZLevel = this.AxesGrid.GridOptions.Zlevel - 0.1;

ax = getaxes(this.AxesGrid);
hPlot = gcr(ax(1));
set(this.SpectralRadiusPatch,'XData',[],'YData',[],'ZData',[]);

if Data.Ts==0
   Factor = tunitconv(hPlot.TimeUnits,Data.TimeUnits);
   % Make sure to include (-MinDecay,0)
   set(this.SpectralAbscissaPatch,'XData',-Factor * Data.MinDecay,'YData',0,'ZData',ZLevel);
else
   set(this.SpectralAbscissaPatch,'XData',[],'YData',[],'ZData',[]);
end
