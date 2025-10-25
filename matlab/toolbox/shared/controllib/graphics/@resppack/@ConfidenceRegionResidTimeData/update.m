function update(this,~)
%UPDATE  Data update method @ConfidenceRegionResidCorrData class.
% For impulse response confidence bound.

%  Copyright 2015 The MathWorks, Inc.

% Struct Data(ny,nu,nD).Amplitude
%                      .Time

try
   % Determine if the last time point is an extension or a computed
   % timestep
   tvec = this.Parent.Time;
   if (length(tvec)>2)
      TEndDiff = tvec(end)-tvec(end-1);
      TBeginDiff = tvec(2)-tvec(1);
      if abs(TEndDiff-TBeginDiff) > 0.01*TBeginDiff
         tvec = tvec(1:end-1);
      end
   end
catch 
   tvec = this.Parent.Time(1:end-1);
end

y = this.Parent.Amplitude;
ysd = this.Parent.AmplitudeSD;
[~,ny,nu] = size(y);

if ~isempty(ysd)
   for yct = 1:ny
      for uct = 1:nu
         % Remove trailing NaNs
         idx = find(isfinite(ysd(:,yct,uct)),1,'last');
         this.Data(yct,uct).AmplitudeSD =  this.NumSD*ysd(1:idx,yct,uct);
         if this.ZeroMeanInterval
            this.Data(yct,uct).Amplitude = zeros(size(y(1:idx,yct,uct)));
         else
            this.Data(yct,uct).Amplitude = y(1:idx,yct,uct);
         end
         this.Data(yct,uct).Time = tvec(1:idx);
      end
   end
end

this.Ts = this.Parent.Ts;
this.TimeUnit = this.Parent.TimeUnits;
