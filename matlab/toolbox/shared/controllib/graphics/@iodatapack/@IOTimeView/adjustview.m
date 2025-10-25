function adjustview(this,Data,Event,~)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits.
%
%  ADJUSTVIEW(VIEW,DATA,'postlim') adjusts the HG object extent once the
%  axes limits have been finalized (invoked in response, e.g., to a
%  'LimitChanged' event).

%  Copyright 2013-2015 The MathWorks, Inc.

AxGrid = this.AxesGrid;

if strcmp(Event,'postlim') && strcmp(AxGrid.YNormalization,'on')
   % Draw normalized data once X limits are finalized.
   yts = Data.OutputData; % time series array (ny-by-1)
   uts = Data.InputData;  % time series array (nu-by-1)
   allts = [yts;uts];
   Curves = this.Curves;
   for j = 1:numel(allts)
      % work on one column at a time
      if ~isempty(allts(j))
         y = allts(j).Data;
         ISB = getinterpmethod(allts(j));
         DataTimeUnits = allts(j).TimeInfo.Units;
         t = allts(j).Time*tunitconv(DataTimeUnits, AxGrid.XUnits);
         Xlims = get(ancestor(Curves(j),'axes'),'Xlim');
         T = zeros(0,1); Y = zeros(0,1);
         for ct = 1:size(y,2)
            if strcmp(ISB,'zoh')
               [T_,Y_] = stairs(t,y(:,ct));
            else
               T_ = t; Y_ = y(:,ct);
            end
            if Data.IsReal
               Y_ = normalize(Data, real(Y_), Xlims*tunitconv(AxGrid.XUnits,DataTimeUnits),...
                  allts(j).Time, real(y(:,ct)));
            else
               Yr_ = normalize(Data, real(Y_), Xlims*tunitconv(AxGrid.XUnits,DataTimeUnits),...
                  allts(j).Time, real(y(:,ct)));
               
               Yi_ = normalize(Data, imag(Y_), Xlims*tunitconv(AxGrid.XUnits,DataTimeUnits),...
                  allts(j).Time, imag(y(:,ct)));
               
               Y_ = Yr_ + 1i*Yi_;
            end
            T = [T; T_; NaN]; Y = [Y; Y_; NaN];
         end
         if Data.IsReal
            set(double(Curves(j)),'Xdata',T(1:end-1),'Ydata',real(Y(1:end-1)));
         else
            set(double(Curves(j,1)),'Xdata',T(1:end-1),'Ydata',real(Y(1:end-1)));
            set(double(Curves(j,2)),'Xdata',T(1:end-1),'Ydata',imag(Y(1:end-1)));
         end
      end
   end
end
