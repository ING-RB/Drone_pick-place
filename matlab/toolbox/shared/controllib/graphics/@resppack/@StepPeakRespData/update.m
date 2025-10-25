function update(cd,r)
%UPDATE  Data update method @StepPeakRespData class

%  Author(s): John Glass
%  Copyright 1986-2022 The MathWorks, Inc.

% RE: Assumes response data is valid (shorted otherwise)
nrows = length(r.RowIndex);
ncols = length(r.ColumnIndex);

% Get final value
if isempty(r.DataSrc)
   % If there is no source do not give a valid yf gain result.
   y0 = zeros(nrows,ncols);
   yf = NaN(nrows,ncols);
else
   % If the response contains a source object compute the final value
   idxModel = find(r.Data==cd.Parent);
   [yf,y0] = getFinalValue(r.DataSrc,idxModel,r);
   if isnan(isstable(r.DataSrc,idxModel)) && ~isSettling(r.Data(idxModel),yf)
      % System with delay-dependent dynamics and unsettled response: skip
      yf(:) = Inf;
   end
end  

% Get data
t = cd.Parent.Time;
y = cd.Parent.Amplitude;
if ~isempty(y)
   % Account for step delay
   Delay = r.Context.Config.Delay;
   if Delay>0
      nDelay = round(Delay/(t(2)-t(1)));
      t = t(nDelay+1:end);
      y = y(nDelay+1:end,:,:);
   end
end
if ~(isempty(y) || all(isfinite(y(end,:))))
   % Skip last sample when not finite
   t = t(1:end-1);   y = y(1:end-1,:,:);
end
   
% Compute peak deviation due to step
tPeak = nan(nrows,ncols);
yPeak = nan(nrows,ncols);
OS = nan(nrows,ncols);  % overshoot
if ~isempty(y)
   if all(isfinite(yf(:)))
      % Stable case
      s = stepinfo(y,t,yf,y0);
      tPeak = reshape(cat(1,s.PeakTime),nrows,ncols);
      OS = reshape(cat(1,s.Overshoot),nrows,ncols);
      yPeak = reshape(cat(1,s.Peak),nrows,ncols);
   else
      % Unstable case: show peak value so far and set overshoot to NaN
      for ct=1:nrows*ncols
         dy = abs(y(:,ct)-y0(ct));
         idx = find(dy==max(dy),1,'last'); % to correctly compute Time for first-order-like systems
         tPeak(ct) = t(idx);
         yPeak(ct) = dy(idx);
      end
   end
end
cd.Time = tPeak;
cd.PeakResponse = yPeak;
cd.OverShoot = OS;
cd.TimeUnits = cd.Parent.TimeUnits;
