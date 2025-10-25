function nyquist(this, r, wspec)
%NYQUIST  Updates frequency response data.

%  Author(s): P. Gahinet, B. Eryilmaz
%   Copyright 1986-2020 The MathWorks, Inc.
nsys = length(r.Data);
SysData = getModelData(this);
if numel(SysData)~=nsys
   return  % number of models does not match number of data objects
end
NormalRefresh = strncmp(r.RefreshMode,'normal',1);
Ts = SysData(1).Ts;
TU = this.Model.TimeUnit;
UCT = tunitconv(TU,'seconds');
UCF = funitconv('rad/TimeUnit','rad/s',TU);

% Get new data from the @ltisource object.
for ct=1:nsys
   % Look for visible+cleared responses in response array
   if isempty(r.Data(ct).Response) && strcmp(r.View(ct).Visible,'on') && isfinite(SysData(ct))
      % Get frequency response data
      d = r.Data(ct);  
      if NormalRefresh
         % Default behavior: regenerate data on appropriate grid based on input
         % arguments
         [mag,phase,w,FocusInfo] = freqresp(SysData(ct),1,wspec,true);
         d.Focus = UCF * FocusInfo.Focus;
         d.SoftFocus = FocusInfo.Soft;
      else
         % Reuse the current frequency vector for maximum speed
         [mag,phase,w] = freqresp(SysData(ct),1,d.Frequency,true);
      end
      % Store in response data object (@magphasedata instance)
      d.Frequency = UCF * w;
      d.Response = mag .* exp(1i*phase);
      d.Ts = UCT * Ts;
      d.FreqUnits = 'rad/s';
      % Only w>=0 stored for real systems
      d.Real = isreal(SysData(ct));
   end
end
