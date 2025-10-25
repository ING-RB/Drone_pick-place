function adjustview(cv,cd,Event,NormalRefresh)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits. 
%
%   ADJUSTVIEW(cVIEW,cDATA,'prelim') hides HG objects that might interfer  
%   with limit picking.  rDATA contains the data of the parent response.
%
%   ADJUSTVIEW(cVIEW,cDATA,'postlimit') adjusts the HG object extent once  
%   the axes limits have been finalized (invoked in response, e.g., to a 
%   'LimitChanged' event).

%   Author(s): J. Glass, P. Gahinet
%   Copyright 1986-2010 The MathWorks, Inc.

if strcmp(Event,'postlim')
    % Position dot and lines given finalized axes limits
    AxGrid = cv.AxesGrid;
    Xauto = strcmp(AxGrid.XlimMode,'auto');
    rData = cd.Parent;
    FreqFactor = funitconv(rData.FreqUnits,AxGrid.XUnits);
    Freq = FreqFactor * rData.Frequency;
    
    % Position dot and lines given finalized axes limits
    % Parent axes and limits
    ax = cv.Points.Parent;
    Xlim = ax.XLim;
    Ylim = ax.YLim;
    LOG = strcmp(ax.XScale,'log');
    
    XDot = FreqFactor * cd.Frequency;
    if LOG
       SIGN = sign(XDot);  XDot = abs(XDot);
    end
    OutScope = Xauto && (XDot<Xlim(1) || XDot>Xlim(2));
    if OutScope && numel(Freq)>1
       % Dot falls outside auto limit box
       XDot = max(Xlim(1),min(Xlim(2),XDot));
       SV = unitconv(rData.SingularValues(:,1),rData.MagUnits,AxGrid.YUnits);
       if LOG
          ind = find(SIGN*Freq>0);
          YDot = utInterp1(log(abs(Freq(ind))),SV(ind),log(XDot));
       else
          YDot = utInterp1(Freq,SV,XDot);
       end
       Color = get(ax,'Color');   % open circle
    else
       YDot = unitconv(cd.PeakGain,rData.MagUnits,AxGrid.YUnits);
       Color = get(cv.Points,'Color');
    end
    
    if OutScope || isnan(XDot)
       set(double([cv.HLines,cv.VLines]),'XData',NaN(1,2),'YData', NaN(1,2))
    else
       set(double(cv.HLines),'XData',[Xlim(1),XDot],'YData',[YDot,YDot])
       set(double(cv.VLines),'XData',[XDot XDot],'YData',[Ylim(1) YDot])
    end
    % Position objects
    set(double(cv.Points),'XData',XDot,'YData',YDot,'MarkerFaceColor',Color)
end