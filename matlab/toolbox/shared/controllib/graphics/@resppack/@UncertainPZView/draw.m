function draw(this,Data,NormalRefresh)
%DRAW  Draws uncertain view

%   Author(s): Craig Buhr
%   Copyright 1986-2010 The MathWorks, Inc.


[Ny, Nu] = size(this.UncertainPoleCurves);
RespData = Data.Data;
for ct = 1:Ny*Nu
    % Plot data as a line
    PoleData = [];
    ZeroData = [];
    for ct1 = 1:length(RespData)
        PoleData = [PoleData; RespData(ct1).Poles{:}];
        ZeroData = [ZeroData; RespData(ct1).Zeros{:}];
    end
end

ax = getaxes(this.AxesGrid);
hPlot = gcr(ax(1));
Factor = tunitconv(hPlot.TimeUnits,Data.TimeUnits);
set(double(this.UncertainPoleCurves),'XData',real(PoleData)*Factor,'YData',imag(PoleData)*Factor,'ZData',-2 * ones(size(PoleData)))
set(double(this.UncertainZeroCurves),'XData',real(ZeroData)*Factor,'YData',imag(ZeroData)*Factor,'ZData',-2 * ones(size(ZeroData)))