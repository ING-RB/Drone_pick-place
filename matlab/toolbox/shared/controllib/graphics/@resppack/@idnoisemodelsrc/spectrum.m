function spectrum(this, r, wspec)
%SPECTRUM  Updates magnitude of @magphasedata objects.

%   Copyright 2011-2018 The MathWorks, Inc.
nsys = length(r.Data);
SysData = getModelData(this);
if numel(SysData)~=nsys
   return  % number of models does not match number of data objects
end
NormalRefresh = strncmp(r.RefreshMode,'normal',1);

% Get new data from the @ltisource object.
for ct = 1:nsys
   % Look for visible+cleared responses in response array
   Ts = SysData(1).Ts;
   if isfinite(SysData(ct)) && isempty(r.Data(ct).Magnitude)
      % Get frequency response data
      d = r.Data(ct);  
      if NormalRefresh
         % Default behavior: regenerate data on appropriate grid based on input
         % arguments
         [ps,w,FocusInfo] = noiseSpectrumSpec(SysData(ct),3,wspec,true);
         d.Focus = FocusInfo.Focus*funitconv('rad/TimeUnit','rad/s',this.Model.TimeUnit);
         d.SoftFocus = FocusInfo.Soft;
      else
         % Reuse the current frequency vector for maximum speed
         [ps,w] = noiseSpectrum(SysData(ct),d.Frequency);
      end
            
      % Store in response data object (@magphasedata instance)
      % Use rad/s for all data.
      d.Frequency = w*funitconv('rad/TimeUnit','rad/s',this.Model.TimeUnit);
      d.Magnitude = abs(ps);
      d.Phase = zeros(size(ps)); % because not showing phase even for complex data
      d.Ts = Ts*tunitconv(this.Model.TimeUnit,'seconds');
      d.FreqUnits = 'rad/s';
   end
end
