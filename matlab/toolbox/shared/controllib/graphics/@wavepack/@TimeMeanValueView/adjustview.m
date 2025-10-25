function adjustview(cv,cd,Event,~)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits.
%
%  ADJUSTVIEW(cVIEW,cDATA,'prelim') hides HG objects that might interfer
%  with limit picking.
%
%  ADJUSTVIEW(cVIEW,cDATA,'postlim') adjusts the HG object extent once
%  the axes limits have been finalized (invoked in response, e.g., to a
%  'LimitChanged' event).

%  Copyright 2015 The MathWorks, Inc.

% RE: Assumes parent waveform contains valid data
if strcmp(Event,'postlim')
   % Position dot and lines given finalized axes limits
   YNorm = strcmp(cv.AxesGrid.YNormalization,'on');
   %Xauto = strcmp(cv.AxesGrid.XlimMode,'auto');
   rData = cd.Parent; % parent response's data
   nr = numel(cv.Points);
   for ct = 1:nr
      % Parent axes and limits
      ax = cv.Points(ct).Parent;
      Xlim = get(ax,'Xlim');
      
      % Adjust dot position based on finalized X limits
      YMean = cd.Mean(ct);      
      TU = rData.TimeUnits;
      TUnitConv = tunitconv(TU,cv.AxesGrid.XUnits);
      LinesP = cv.Points(ct);
      T0 = rData.Time;
      % Take normalization into account
      if YNorm
         Y0 = rData.Amplitude;
         if isfinite(YMean)
            if isa(rData,'wavepack.timedata')
               YMean = normalize(rData, YMean, ...
                  Xlim*tunitconv(cv.AxesGrid.XUnits,TU),ct);
            else
               YMean = normalize(rData, YMean, ...
                  Xlim*tunitconv(cv.AxesGrid.XUnits,TU),T0,Y0);
            end
         end
      end
      
      % Position object
      X = T0*TUnitConv; Y = YMean(1)*ones(size(T0));      
      set(LinesP, ...
         'XData',X,...
         'YData',Y, ...
         'Zdata',-10*ones(size(X)))
   end
end
