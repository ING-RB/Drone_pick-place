function timeresp(this, RespType, r)
% TIMERESP Updates time response data

%  Copyright 1986-2022 The MathWorks, Inc.
sys = this.Model; % LTV or LPV
Config = r.Context.Config;
t = r.Context.Time;
p = r.Context.Parameter;

if isempty(r.Data.Amplitude) && strcmp(r.View.Visible,'on')
   % Recompute response
   d = r.Data;
   Ts = sys.Ts;
   try
      [Amplitude,Time,Focus] = fastresp(sys,RespType,t,p,Config);
      if isComplexResponse(Amplitude)
         d.Exception = true;
         d.ExceptionReason = message('Controllib:plots:PlotComplexData');
      else
         d.Amplitude = real(Amplitude);
         d.Time = Time;
         d.Focus = Focus;
         d.Ts = Ts;
      end
      d.TimeUnits = this.Model.TimeUnit;
      % REVISIT: DataOptions handling?
   catch ME
      d.Exception = true;
      d.ExceptionReason = ME.message;
   end
end


