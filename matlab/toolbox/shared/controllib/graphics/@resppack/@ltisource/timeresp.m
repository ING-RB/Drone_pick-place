function timeresp(this, RespType, r)
% TIMERESP Updates time response data
%
%  RESPTYPE = {step, impulse, initial}

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2022 The MathWorks, Inc.
nsys = length(r.Data);
SysData = getModelData(this);
if numel(SysData)~=nsys
   return  % number of models does not match number of data objects
end
NormalRefresh = strncmp(r.RefreshMode,'normal',1);
RefreshFocus = r.RefreshFocus;
Config = r.Context.Config;
t = r.Context.Time;

% Get new data from the @ltisource object.
for ct = 1:nsys
   % Look for visible+cleared responses in response array
   if isempty(r.Data(ct).Amplitude) && strcmp(r.View(ct).Visible,'on') && isfinite(SysData(ct))
      % Recompute response
      d = r.Data(ct);
      Dsys = SysData(ct);
      Ts = Dsys.Ts;
      try
         if NormalRefresh
            % Regenerate data on appropriate grid based on input arguments
            [Amplitude,Time,Focus] = timeresp(Dsys,RespType,t,Config);
            if isComplexResponse(Amplitude)
                d.Exception = true;
                d.ExceptionReason = message('Controllib:plots:PlotComplexData');
            else
                d.Amplitude = real(Amplitude);
                d.Time = Time;
                d.Focus = Focus;
                d.Ts = Ts;
            end
         else
            % Reuse the current sampling time for maximum speed
            t = d.Time;
            if isempty(RefreshFocus)
               % Reuse the current time vector.
               % RE: Beware of t(end)=Inf for final value encoding
               lt = length(t);
               t(lt) = t(lt-1) + t(2)-t(1);
            else
               % Use time vector that fills visible X range
               % RE: Used in SISO Tool for max efficiency and visual comfort
               if Ts==0
                  dt = max(RefreshFocus(2)/500,t(2)-t(1));  % 500 points max
               else
                  dt = Ts;
               end
               t = 0:dt:RefreshFocus(2);
            end
            d.Time = t;
            d.Amplitude = real(timeresp(Dsys,RespType,t,Config));
         end
         d.TimeUnits = this.Model.TimeUnit;
      catch ME
         d.Exception = true;
         d.ExceptionReason = ME.message;
      end
   end
end

end


