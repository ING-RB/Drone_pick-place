function draw(this, Data, ~)
%DRAW  Draws time domain signal curves.
%
%  DRAW(VIEW,DATA) maps the signal data in DATA to the curves in VIEW.

%  Copyright 2013-2016 The MathWorks, Inc.

AxGrid = this.AxesGrid;

% Redraw the curves
if strcmp(AxGrid.YNormalization,'on')
   % RE: Defer to ADJUSTVIEW:postlim for normalized case (requires finalized X limits)
   reset(this);
   return
end

% Input and output sizes
yts = Data.OutputData; % time series array (ny-by-1)
uts = Data.InputData;  % time series array (nu-by-1)
allts = [yts;uts];
for j = 1:numel(allts)
   % work on one column at a time
   if ~isempty(all(j))
      y = allts(j).Data;
      ISB = getinterpmethod(allts(j));
      t = allts(j).Time*tunitconv(allts(j).TimeInfo.Units, AxGrid.XUnits);
      Curve = this.Curves(j,:);
      T = zeros(0,1); Y = zeros(0,1);
      if ~allts(j).IsTimeFirst
          %Permute to put time first and all other channels along 2nd
          %dimension
          sz = size(y);
          nsz = numel(sz);
          y = permute(y, [nsz 1:nsz-1]);
          y = reshape(y,sz(end),prod(sz(1:end-1)));
      end
      for ct = 1:size(y,2)
         if strcmp(ISB,'zoh')
            [T_,Y_] = stairs(t,y(:,ct));
            T = [T; T_; NaN]; Y = [Y; Y_; NaN];
         else
            T = [T; t; NaN]; Y = [Y; y(:,ct); NaN];
         end
      end
      if Data.IsReal
         set(double(Curve),'Xdata',T(1:end-1), 'Ydata',real(Y(1:end-1)), 'Tag', allts(j).Name);
      else
         set(double(Curve(1)),'Xdata',T(1:end-1), 'Ydata',real(Y(1:end-1)), 'Tag', allts(j).Name);
         set(double(Curve(2)),'Xdata',T(1:end-1), 'Ydata',imag(Y(1:end-1)), 'Tag', allts(j).Name);
      end
   end
end
