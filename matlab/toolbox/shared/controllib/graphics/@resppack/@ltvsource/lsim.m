function lsim(this, r)
% Updates lsim plot response data

%  Copyright 1986-2020 The MathWorks, Inc.

SimInput = r.Parent.Input; % @siminput instance
sys = this.Model; % LTV or LPV
nu = size(sys,2);

% Retrieve t,u data
if strcmp(r.Parent.InputStyle,'tiled')
   % If there are insufficient inputs or missing time vectors ->
   % exception
   InputData = SimInput.Data(r.Context.InputIndex); % handle vector
   if any(cellfun('isempty',get(InputData,{'Amplitude'})))
      return
   end
   % Get the input data and initial states
   % Convert Time Units to System Units
   t = InputData(1).Time;
   tTimeUnits = InputData(1).TimeUnits;
   for ct=nu:-1:1
      u(:,ct) = InputData(ct).Amplitude;  % ns-by-nu
   end
else
   t = SimInput.Data.Time;
   tTimeUnits = SimInput.Data.TimeUnits;
   u = SimInput.Data.Amplitude;
end

% Update data
% Convert data time units to system time units for simulation
t = t*tunitconv(tTimeUnits,this.getTimeUnits);
xinit = r.Context.IC;
p = r.Context.Parameter;
if isempty(r.Data.Amplitude) && strcmp(r.View.Visible,'on')
   d = r.Data;
   try
      % Skip if model is NaN or response cannot be computed
      Amplitude = fastlsim(sys,u,t,xinit,p);
      if isComplexResponse(Amplitude)
         d.Exception = true;
         d.ExceptionReason = message('Controllib:plots:PlotComplexData');
      else
         d.Amplitude = real(Amplitude);
      end
      d.Time = t;
      d.Focus = [t(1) t(end)];
      d.Ts = sys.Ts;
      d.TimeUnits = this.getTimeUnits;
   catch ME
      d.Exception = true;
      d.ExceptionReason = ME.message;
   end
end
