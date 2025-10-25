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
   [nr,nc] = size(cv.Points);
   yts = rData.OutputData; % time series array (ny-by-1)
   uts = rData.InputData;  % time series array (nu-by-1)
   allts = [yts;uts];
   for i = 1:nr
      for j = 1:nc
         % Parent axes and limits
         ax = cv.Points(i,j).Parent;
         Xlim = get(ax,'Xlim');
         Ylim = get(ax,'Ylim');
         
         % Adjust dot position based on finalized X limits
         T = cd.Time{i,j}; YDots = cd.PeakResponse{i,j};
         TUnitConv = tunitconv(cd.TimeUnit{i,j},cv.AxesGrid.XUnits);
         XDots = T*TUnitConv;
         LinesP = cv.Points(i,j);
         
         T0 = allts(i).Time; Y0 = allts(i).Data;
         % Take normalization into account
         if YNorm
            for ii = 1:numel(YDots)
               if isfinite(YDots(ii))
                  if rData.IsReal
                     YDots(ii) = normalize(rData, YDots(ii), ...
                        Xlim*tunitconv(cv.AxesGrid.XUnits,cd.TimeUnit{i,j}),...
                        T0,Y0(:,ii));
                  else
                     if j==1
                        Yref = real(Y0(:,ii));
                     else
                        Yref = imag(Y0(:,ii));
                     end
                     YDots(ii) = normalize(rData, YDots(ii), ...
                        Xlim*tunitconv(cv.AxesGrid.XUnits,cd.TimeUnit{i,j}),...
                        T0,Yref);
                  end
               end
            end
         end
         
         % Position object
         LinesH = cv.HLines(i,j);
         LinesV = cv.VLines(i,j);
         X1 = XDots(1); Y1 = YDots(1);
         for jj = 2:numel(YDots)
            X1 = [X1; NaN; XDots(jj)]; %#ok<*AGROW>
            Y1 = [Y1; NaN; YDots(jj)];
         end
         set(LinesP,'XData',X1,'YData',Y1,'Zdata',5*ones(size(X1)))
         
         X1 = [T0(1)*TUnitConv; XDots(1)];
         Y1 = [YDots(1); YDots(1)];
         for jj = 2:numel(YDots)
            X1 = [X1; NaN; T0(1)*TUnitConv; XDots(jj)];
            Y1 = [Y1; NaN; YDots(jj); YDots(jj)];
         end
         set(LinesH, 'XData',X1, 'YData',Y1, 'ZData', -10*ones(size(X1)));
         
         X1 = [XDots(1); XDots(1)];
         Y1 = [Ylim(1); YDots(1)];
         for jj = 2:numel(YDots)
            X1 = [X1; NaN; XDots(jj); XDots(jj)];
            Y1 = [Y1; NaN; Ylim(1) ; YDots(jj)];
         end
         set(LinesV, 'XData',X1, 'YData',Y1, 'ZData', -10*ones(size(X1)));
      end
   end
end
