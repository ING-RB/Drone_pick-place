function update(cd,r)
% Data update method @SettleTimeData class (settling time in step response)

%  Author(s): John Glass
%   Copyright 1986-2023 The MathWorks, Inc.

% RE: Assumes response data is valid (shorted otherwise)
nrows = length(r.RowIndex);
ncols = length(r.ColumnIndex);

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

% Compute Settling Time
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

% Compute settling time
Tsettle = NaN(nrows,ncols);
Ysettle = NaN(nrows,ncols);
if ~isempty(y)
   s = stepinfo(y,t,yf,y0,'SettlingTimeThreshold',cd.SettlingTimeThreshold);
   Tsettle = reshape(cat(1,s.SettlingTime),nrows,ncols);
   Tsettle(isnan(Tsettle)) = Inf;  % unstable
   % Compute Y value at settling time
   for ct=1:nrows*ncols
      if isfinite(Tsettle(ct))
         Ysettle(ct) = utInterp1(t,y(:,ct),Tsettle(ct));
      end
   end
end
cd.FinalValue = yf;
cd.Time = Tsettle;
cd.YSettle = Ysettle;
cd.TimeUnits = cd.Parent.TimeUnits;
