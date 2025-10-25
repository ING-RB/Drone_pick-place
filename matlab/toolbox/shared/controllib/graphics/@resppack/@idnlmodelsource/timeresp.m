function timeresp(this, RespType, r)
% TIMERESP Updates time response data
%
%  RESPTYPE = {step, impulse, initial}
%  VARARGIN = {Tfinal or time vector}.

%  Copyright 2010-2022 The MathWorks, Inc.

SysData = this.Model;
NormalRefresh = strncmp(r.RefreshMode,'normal',1);
RefreshFocus = r.RefreshFocus;
Config = r.Context.Config;
t = r.Context.Time;

% Look for visible+cleared responses in response array
if isempty(r.Data.Amplitude) && strcmp(r.View.Visible,'on') && isfinite(SysData)
   % Recompute response
   d = r.Data;
   Ts = SysData.Ts;
   try
      if NormalRefresh
         % Regenerate data on appropriate grid based on input arguments
         [d.Amplitude,d.Time,d.Focus] = timeresp(SysData,RespType,t,Config);
         %[d.Amplitude,d.Time,d.Focus] = step(SysData, varargin{:});
         d.Ts = Ts;
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
         d.Amplitude = timeresp(SysData,RespType,t,Config);
      end
      d.TimeUnits = this.Model.TimeUnit;
   end
end
