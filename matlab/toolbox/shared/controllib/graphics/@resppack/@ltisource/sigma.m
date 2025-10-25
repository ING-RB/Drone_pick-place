function sigma(this,r,wspec,type)
% Updates Singular Value data for SIGMA plots.

%   Copyright 1986-2020 The MathWorks, Inc.

% Note: WSPEC must come first because always assumed to be 3rd input by LTI
% Viewer
nsys = length(r.Data);
SysData = getModelData(this);
if numel(SysData)~=nsys || nsys==0
   return  % number of models does not match number of data objects
elseif nargin<4
   type = 0;
end
NormalRefresh = strncmp(r.RefreshMode,'normal',1);
Ts = SysData(1).Ts;
TU = this.Model.TimeUnit;
UCT = tunitconv(TU,'seconds');
UCF = funitconv('rad/TimeUnit','rad/s',TU);

% Get new data from the @ltisource object.
for ct=1:nsys
   % Look for visible+cleared responses in response array
   if isempty(r.Data(ct).SingularValues) && strcmp(r.View(ct).Visible,'on') && ...
         isfinite(SysData(ct))
      % Get frequency response data
      d = r.Data(ct);  
      if NormalRefresh
         % Default behavior: regenerate data on appropriate grid based on input arguments
         [sv,w,FocusInfo] = sigmaresp(SysData(ct),type,wspec,true);
         d.Focus = UCF * FocusInfo.Focus;
         d.SoftFocus = FocusInfo.Soft;
      else
         % Dynamic update: reuse the current frequency vector for maximum speed
         [sv,w] = sigmaresp(SysData(ct),type,d.Frequency,true);
      end
      % Store in response data object (@sigmadata instance)
      d.Frequency = UCF * w;
      d.SingularValues = sv';
      d.Ts = UCT * Ts;
      d.FreqUnits = 'rad/s';
      % Only w>=0 stored for real systems
      d.Real = isreal(SysData(ct));
   end
end

