function magphaseresp(this, RespType, r, wspec)
%MAGPHASERESP  Updates magnitude and phase data of @magphasedata objects.
%
%  RESPTYPE = 'bode' or 'nichols'

%  Author(s): P. Gahinet, B. Eryilmaz
%   Copyright 1986-2021 The MathWorks, Inc.
nsys = length(r.Data);
SysData = getModelData(this);
if numel(SysData)~=nsys || nsys==0
   return  % number of models does not match number of data objects
end
NormalRefresh = strncmp(r.RefreshMode,'normal',1);
Ts = SysData(1).Ts;
TU = this.Model.TimeUnit;
UCT = tunitconv(TU,'seconds');
UCF = funitconv('rad/TimeUnit','rad/s',TU);

% Plot-type-specific settings
switch RespType
   case 'bode'
      grade = 3;
   case 'nichols'
      grade = 2;
end

% Get new data from the @ltisource object.
for ct=1:nsys
   % Look for visible+cleared responses in response array
   if isempty(r.Data(ct).Magnitude) && strcmp(r.View(ct).Visible,'on') && isfinite(SysData(ct))
      % Get frequency response data
      d = r.Data(ct);
      if NormalRefresh
         % Default behavior: regenerate data on appropriate grid based on input
         % arguments
         [mag,phase,w,FocusInfo] = freqresp(SysData(ct),grade,wspec,true);
         d.Focus = UCF * FocusInfo.Focus;
         d.SoftFocus = FocusInfo.Soft;
      else
         % Reuse the current frequency vector for maximum speed
         [mag,phase,w] = freqresp(SysData(ct),grade,d.Frequency,true);
      end
      
      % Ignore phase where gain is 0 or Inf (see g144852)
      phase(~isfinite(mag) | mag==0) = NaN;  % phase of 0 or Inf undefined
      
      % Store in response data object (@magphasedata instance)
      d.Frequency = UCF * w;
      d.Magnitude = mag;
      d.Phase = phase;
      d.Ts = UCT * Ts;
      d.FreqUnits = 'rad/s';
      % Only w>=0 stored for real systems
      d.Real = isreal(SysData(ct));
   end
end
