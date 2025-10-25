function update(cd,r)
%UPDATE  Data update method @StepRiseTimeData class

%   Author(s): John Glass
%   Copyright 1986-2010 The MathWorks, Inc.

% RE: Assumes response data is valid (shorted otherwise)
nrows = length(r.RowIndex);
ncols = length(r.ColumnIndex);
RiseTimeLims = cd.RiseTimeLimits;

% Get final value
if isempty(r.DataSrc)
   % If there is no source do not give a valid yf gain result.
   y0 = NaN(nrows,ncols);
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

% Compute rise time data
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
   % Ignore last sample (can be Inf)
   t = t(1:end-1);
   y = y(1:end-1,:,:);
end

% Compute rise time info
if isempty(y)
   cd.TLow = NaN(nrows,ncols);
   cd.THigh = NaN(nrows,ncols);
   cd.Amplitude = NaN(nrows,ncols);
else
   [~,xt] = stepinfo(y,t,yf,y0,'RiseTimeLimits',RiseTimeLims);
   % Store data
   cd.TLow = reshape(cat(1,xt.RiseTimeLow),nrows,ncols);
   cd.THigh = reshape(cat(1,xt.RiseTimeHigh),nrows,ncols);
   % Compute YHigh = upper rise time target
   cd.Amplitude = y0+RiseTimeLims(2)*(yf-y0);
end
cd.TimeUnits = cd.Parent.TimeUnits;
