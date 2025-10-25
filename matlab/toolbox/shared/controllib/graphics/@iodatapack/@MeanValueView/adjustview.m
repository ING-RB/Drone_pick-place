function adjustview(cv,cd,Event,~)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits.
%
%  ADJUSTVIEW(cVIEW,cDATA,'prelim') hides HG objects that might interfer
%  with limit picking.
%
%  ADJUSTVIEW(cVIEW,cDATA,'postlim') adjusts the HG object extent once
%  the axes limits have been finalized (invoked in response, e.g., to a
%  'LimitChanged' event).

%  Copyright 2013-2015 The MathWorks, Inc.

% RE: Assumes parent waveform contains valid data
if strcmp(Event,'postlim')
   % Position dot and lines given finalized axes limits
   YNorm = strcmp(cv.AxesGrid.YNormalization,'on');
   %Xauto = strcmp(cv.AxesGrid.XlimMode,'auto');
   rData = cd.Parent; % parent response's data
   [nr, nc] = size(cv.Points);
   yts = rData.OutputData; % time series array (ny-by-1)
   uts = rData.InputData;  % time series array (nu-by-1)
   allts = [yts;uts];
   for ir = 1:nr
      T0 = allts(ir).Time;
      TU = allts(ir).TimeInfo.Units;
      for ic = 1:nc
         % Parent axes and limits
         ax = cv.Points(ir,ic).Parent;
         Xlim = get(ax,'Xlim');
         
         % Adjust dot position based on finalized X limits
         YMean = cd.Mean{ir,ic};
         TUnitConv = tunitconv(TU,cv.AxesGrid.XUnits);
         
         LinesP = cv.Points(ir,ic);
         
         % Take normalization into account
         if YNorm
            Y0 = allts(ir).Data;
            for i = 1:numel(YMean)
               if isfinite(YMean(i))
                  if ic==1
                     Yref = real(Y0(:,i));
                  else
                     Yref = imag(Y0(:,i));
                  end
                  YMean(i) = normalize(rData, YMean(i), ...
                     Xlim*tunitconv(cv.AxesGrid.XUnits,TU),...
                     T0,Yref);
               end
            end
         end
         
         % Position object
         X = T0*TUnitConv; Y = YMean(1)*ones(size(T0));
         for j = 2:numel(YMean)
            X = [X; NaN; T0*TUnitConv];
            Y = [Y; NaN; YMean(j)*ones(size(T0))];
         end
         
         set(LinesP, ...
            'XData',X,...
            'YData',Y, ...
            'Zdata',-10*ones(size(X)))
      end
   end
end
