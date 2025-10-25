function update(cd,r)
%UPDATE  Data update method @ImpulsePeakRespData class

%  Copyright 2022 The MathWorks, Inc.

% RE: Assumes response data is valid (shorted otherwise)
nrows = length(r.RowIndex);
ncols = length(r.ColumnIndex);

% Get initial value
if isempty(r.DataSrc)
   % If there is no source do not give a valid yf gain result.
   y0 = zeros(nrows,ncols);
else
   % If the response contains a source object compute the final value
   idxModel = find(r.Data==cd.Parent);
   [~,y0] = getFinalValue(r.DataSrc,idxModel,r);
end

% Get data
t = cd.Parent.Time;
y = cd.Parent.Amplitude;
if ~isempty(y)
   % Account for impulse delay
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

% Compute peak deviation due to impulse
tPeak = nan(nrows,ncols);
yPeak = nan(nrows,ncols);
if ~isempty(y)
   for ct=1:nrows*ncols
      dy = abs(y(:,ct)-y0(ct));
      idx = find(dy==max(dy),1,'last');
      tPeak(ct) = t(idx);
      yPeak(ct) = dy(idx);
   end
end
cd.Time = tPeak;
cd.PeakResponse = yPeak;
cd.TimeUnits = cd.Parent.TimeUnits;
