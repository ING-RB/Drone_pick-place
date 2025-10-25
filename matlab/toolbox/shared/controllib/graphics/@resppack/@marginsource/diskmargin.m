function diskmargin(this,r,wspec)
% Computes (MIMO) disk margin as a function of frequency and updates 
% gain/phase margin data. This computes the true disk-based margins 
% using mu analysis.

%   Copyright 1986-2020 The MathWorks, Inc.

% NOTE: Data units are Frequency:rad/s, Magnitude:abs, and Phase:rad
nsys = length(r.Data);
if nsys==0
   return
end
LData = getModelData(this);
Ts = abs(LData(1).Ts);
TU = this.Model.TimeUnit;
UCT = tunitconv(TU,'seconds');
UCF = funitconv('rad/TimeUnit','rad/s',TU);
sigma = this.Skew;

% Get new data
for ct=1:nsys
   % Look for visible+cleared responses in response array
   if isempty(r.Data(ct).Magnitude) && strcmp(r.View(ct).Visible,'on') && ...
         isfinite(LData(ct))
      % Compute disk margin as a function of frequency
      [alpha,w,FocusInfo] = diskmarginresp(LData(ct),sigma,wspec,this.Cache(ct).Stable,true);
      % Compute gain and phase margin data to plot
      [GM,PM,alpha] = dm2gmPlot(alpha,sigma);
      % Store data
      d = r.Data(ct);
      d.Ts = UCT * Ts;
      d.Focus = UCF * FocusInfo.Focus;
      d.SoftFocus = FocusInfo.Soft;
      d.Frequency = UCF * w;
      d.DiskMargin = alpha;
      d.Magnitude = GM; % abs
      d.Phase = (pi/180)*PM; % rad
      % Only w>=0 stored for real systems
      d.Real = isreal(LData(ct));
   end
end