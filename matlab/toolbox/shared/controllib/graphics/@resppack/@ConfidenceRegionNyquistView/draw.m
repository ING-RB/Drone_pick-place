function draw(this,Data,NormalRefresh)
%DRAW  Draws uncertain view

%   Author(s): Craig Buhr
%   Copyright 1986-2011 The MathWorks, Inc.


[Ny, Nu] = size(this.UncertainNyquistCurves);
if isempty(Data.Data)
    set(this.UncertainNyquistCurves,'XData',NaN,'YData',NaN,'ZData',-2);
    set(this.UncertainNyquistNegCurves,'XData',NaN,'YData',NaN,'ZData',-2);
    set(this.UncertainNyquistMarkers,'XData',NaN,'YData',NaN,'ZData',-2);
    set(this.UncertainNyquistNegMarkers,'XData',NaN,'YData',NaN,'ZData',-2);
else
    EllipseData = computeEllipseData(Data);
    for yct = 1:Ny
        for uct = 1:Nu
            % nyquist
            if isempty(EllipseData(yct,uct).EllipseFreq)
                set(this.UncertainNyquistCurves(yct,uct),'XData',NaN,'YData',NaN,'ZData',-2);
                set(this.UncertainNyquistNegCurves(yct,uct),'XData',NaN,'YData',NaN,'ZData',-2);
                set(this.UncertainNyquistMarkers(yct,uct),'XData',NaN,'YData',NaN,'ZData',-2);
                set(this.UncertainNyquistNegMarkers(yct,uct),'XData',NaN,'YData',NaN,'ZData',-2);
            else
                NyquistData = [];
                for ct = 1:size(EllipseData,3)
                    NyquistData = [NyquistData;NaN;EllipseData(yct,uct,ct).EllipseFreq];
                end
                set(this.UncertainNyquistCurves(yct,uct),...
                    'XData', real(NyquistData),...
                    'YData', imag(NyquistData),...
                    'ZData', -2 * ones(size(NyquistData)))
                
                set(this.UncertainNyquistMarkers(yct,uct),...
                    'XData', real(Data.Data.Response(:,yct,uct)),...
                    'YData', imag(Data.Data.Response(:,yct,uct)),...
                    'ZData', -2 * ones(size(Data.Data.Response(:,yct,uct))))
                
                if this.Parent.ShowFullContour
                    % REVISIT: incorrect for complex systems!
                    set(this.UncertainNyquistNegCurves(yct,uct),...
                        'XData', real(NyquistData),...
                        'YData', -imag(NyquistData),...
                        'ZData', -2 * ones(size(NyquistData)))
                    set(this.UncertainNyquistNegMarkers(yct,uct),...
                        'XData', real(Data.Data.Response(:,yct,uct)),...
                        'YData', -imag(Data.Data.Response(:,yct,uct)),...
                        'ZData', -2 * ones(size(Data.Data.Response(:,yct,uct))))
                else
                    set(this.UncertainNyquistNegCurves(yct,uct), 'XData',[],'YData',[],'ZData',[])
                    set(this.UncertainNyquistNegMarkers(yct,uct), 'XData',[],'YData',[],'ZData',[])
                end
            end
        end
    end
end

