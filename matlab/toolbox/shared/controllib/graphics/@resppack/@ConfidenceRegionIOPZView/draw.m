function draw(this,Data,NormalRefresh)
%DRAW  Draws uncertain view

%   Author(s): Craig Buhr
%   Copyright 1986-2010 The MathWorks, Inc.


if isempty(Data.Data)
    set(this.UncertainPoleCurves,'XData',[],'YData',[],'ZData',[]);
    set(this.UncertainZeroCurves,'XData',[],'YData',[],'ZData',[]);
    
else
    ax = getaxes(this.AxesGrid);
    hPlot = gcr(ax(1));
    Factor = tunitconv(hPlot.TimeUnits,Data.TimeUnits);
    
    [Ny, Nu] = size(this.UncertainPoleCurves);
    EllipseData = computeEllipseData(Data);
    EllipsePoleData = EllipseData.EllipsePoleData;
    EllipseZeroData = EllipseData.EllipseZeroData;
    
    for yct = 1:Ny
        for uct = 1:Nu
            % Poles
            if isempty(EllipsePoleData(yct,uct).EllipseData)
                set(this.UncertainPoleCurves(yct,uct),'XData',NaN,'YData',NaN,'ZData',-2);
            else
                PoleData = [];
                for ct = 1:size(EllipsePoleData,3)
                    PoleData = [PoleData;NaN;EllipsePoleData(yct,uct,ct).EllipseData(:)];
                end
                set(this.UncertainPoleCurves(yct,uct),'XData',real(PoleData)*Factor,'YData',imag(PoleData)*Factor,'ZData',-2 * ones(size(PoleData)))
            end
            
            
            if isempty(EllipseZeroData(yct,uct).EllipseData)
                set(this.UncertainZeroCurves(yct,uct),'XData',NaN,'YData',NaN,'ZData',-2);
            else
                ZeroData = [];
                for ct = 1:size(EllipseZeroData,3)
                    ZeroData = [ZeroData;NaN;EllipseZeroData(yct,uct,ct).EllipseData(:)];
                end
                set(this.UncertainZeroCurves(yct,uct),'XData',real(ZeroData)*Factor,'YData',imag(ZeroData)*Factor,'ZData',-2 * ones(size(ZeroData)))
            end
            
        end
    end
end
