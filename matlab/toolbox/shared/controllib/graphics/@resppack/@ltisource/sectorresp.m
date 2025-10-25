function sectorresp(this,r,wspec,M0,W1,W2)
%SECTORRESP   Updates sector index data.

%   Copyright 1986-2015 The MathWorks, Inc.
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
   if isempty(r.Data(ct).SingularValues) && strcmp(r.View(ct).Visible,'on') && isfinite(SysData(ct))
      % Get frequency response data
      d = r.Data(ct);
      try
         if NormalRefresh
            % Default behavior: regenerate data on appropriate grid based on input arguments
            [INDX,w,FocusInfo,InfFlag] = sectorresp(SysData(ct),M0,W1,W2,wspec,true);
         else
            % Dynamic update: reuse the current frequency vector for maximum speed
            [INDX,w,~,InfFlag] = sectorresp(SysData(ct),M0,W1,W2,d.Frequency,true);
         end
         if InfFlag
            d.Exception = true;
            d.ExceptionReason = message('Control:analysis:sectorplot4');
         else
            % Store in response data object (@SectorIndexData instance)
            d.Frequency = UCF * w;
            d.SingularValues = INDX.';
            d.Ts = UCT * Ts;
            d.FreqUnits = 'rad/s';
            d.Focus = UCF * FocusInfo.Focus;
            d.SoftFocus = FocusInfo.Soft;
            % Only w>=0 stored for real systems
            d.Real = isreal(SysData(ct));
         end
      catch ME
         d.Exception = true;
         d.ExceptionReason = ME.message;
      end
   end
end

