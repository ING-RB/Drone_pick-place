function ifpofpresp(this,r,type,wspec)
%IFPOFPRESP   Updates IFP/OFP data.

%   Copyright 1986-2015 The MathWorks, Inc.
nsys = length(r.Data);
NormalRefresh = strncmp(r.RefreshMode,'normal',1);
SysData = getModelData(this);
if numel(SysData)~=nsys
    return  % number of models does not match number of data objects
end
TU = this.Model.TimeUnit;

% Get new data from the @ltisource object.
for ct=1:nsys
   % Look for visible+cleared responses in response array
   Ts = SysData(1).Ts;
   if isempty(r.Data(ct).Index) && strcmp(r.View(ct).Visible,'on') && ...
         isfinite(SysData(ct))
      % Get frequency response data
      d = r.Data(ct);
      try
         if NormalRefresh
            % Default behavior: regenerate data on appropriate grid based on input arguments
            [INDX,w,FocusInfo,InfFlag] = ifpofpresp(SysData(ct),type,wspec,true);
         else
            % Dynamic update: reuse the current frequency vector for maximum speed
            [INDX,w,~,InfFlag] = ifpofpresp(SysData(ct),type,d.Frequency,true);
         end
         if InfFlag
            d.Exception = true;
            d.ExceptionReason = message('Control:analysis:passiveplot');
         else
            % Store in response data object (@SectorIndexData instance)
            d.Frequency = w*funitconv('rad/TimeUnit','rad/s',TU);
            d.Index = INDX.';
            d.Ts = Ts*tunitconv(TU,'seconds');
            d.FreqUnits = 'rad/s';
            d.Focus = FocusInfo.Focus*funitconv('rad/TimeUnit','rad/s',TU);
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