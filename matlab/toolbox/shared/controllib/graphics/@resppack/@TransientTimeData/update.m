function update(cd,r)
%UPDATE  Data update method @TransientTimeData class

%   Copyright 2021 The MathWorks, Inc.

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

% Compute Transient Time
t = cd.Parent.Time;
y = cd.Parent.Amplitude;
if ~isempty(y)
   % Account for step or impulse delay
   if ~strcmp(r.Context.Type,'initial')
      nDelay = round(r.Context.Config.Delay/(t(2)-t(1)));
      t = t(nDelay+1:end);
      y = y(nDelay+1:end,:,:);
   end
   % Ignore last sample (can be Inf)
   t = t(1:end-1);
   y = y(1:end-1,:,:);
end

% Compute settling time
Ttr = NaN(nrows,ncols);
Ytr = NaN(nrows,ncols);
if ~isempty(y)
   s = lsiminfo(y,t,yf,y0,'SettlingTimeThreshold',cd.SettlingTimeThreshold);
   Ttr = reshape(cat(1,s.TransientTime),nrows,ncols);
   Ttr(isnan(Ttr)) = Inf;  % unstable
   % Compute Y value at settling time
   for ct=1:nrows*ncols
      if isfinite(Ttr(ct))
         Ytr(ct) = utInterp1(t,y(:,ct),Ttr(ct));
      end
   end
end
cd.FinalValue = yf;
cd.Time = Ttr;
cd.YSettle = Ytr;
cd.TimeUnits = cd.Parent.TimeUnits;
