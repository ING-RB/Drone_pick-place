function vspresp(this,r,wspec,M0,W1,W2)
%VSPRESP   Updates I/O passivity index data for passiveplot.

%   Copyright 1986-2015 The MathWorks, Inc.
nsys = length(r.Data);
NormalRefresh = strncmp(r.RefreshMode,'normal',1);
SysData = getModelData(this);
if numel(SysData)~=nsys
    return  % number of models does not match number of data objects
end

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
            [INDX,w,FocusInfo,InfFlag] = sectorresp(SysData(ct),M0,W1,W2,wspec,true);
         else
            % Dynamic update: reuse the current frequency vector for maximum speed
            [INDX,w,~,InfFlag] = sectorresp(SysData(ct),M0,W1,W2,d.Frequency,true);
         end
         if InfFlag
            d.Exception = true;
            d.ExceptionReason = message('Control:analysis:passiveplot');
         else
            % Store in response data object (@SectorIndexData instance)
            d.Frequency = w*funitconv('rad/TimeUnit','rad/s',this.Model.TimeUnit);
            if ~isempty(INDX)
               R = INDX(1,:);
               INDX = 0.5*(1-R.^2)./(1+R.^2);
               INDX(isinf(R)) = -0.5;
            end
            d.Index = INDX';
            d.Focus = FocusInfo.Focus*funitconv('rad/TimeUnit','rad/s',this.Model.TimeUnit);
            d.SoftFocus = FocusInfo.Soft;
            d.Ts = Ts*tunitconv(this.Model.TimeUnit,'seconds');
            d.FreqUnits = 'rad/s';
            % Only w>=0 stored for real systems
            d.Real = isreal(SysData(ct));
         end
      catch ME
         d.Exception = true;
         d.ExceptionReason = ME.message;
      end
   end
end

