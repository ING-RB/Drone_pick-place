function lsim(this, r)
% Updates lsim plot response data

%  Copyright 1986-2020 The MathWorks, Inc.

SimInput = r.Parent.Input; % @siminput instance
nsys = length(r.Data);
SysData = getModelData(this);
if numel(SysData)~=nsys
   return  % number of models does not match number of data objects
end
NormalRefresh = strncmp(r.RefreshMode,'normal',1);
[~,nu] = iosize(SysData(1));

% Retrieve t,u data
if strcmp(r.Parent.InputStyle,'tiled')
   % If there are insufficient inputs or missing time vectors ->
   % exception
   InputData = SimInput.Data(r.Context.InputIndex); % handle vector
   if NormalRefresh && any(cellfun('isempty',get(InputData,{'Amplitude'})))
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
for ct = 1:nsys
   % Look for visible+cleared responses in response array
   if isempty(r.Data(ct).Amplitude) && ...
         strcmp(r.View(ct).Visible,'on') && isfinite(SysData(ct))
      Dsys = SysData(ct);
      d = r.Data(ct);
      try
         % Skip if model is NaN or response cannot be computed
         Amplitude = lsim(Dsys,u,t,xinit,SimInput.Interpolation,[]); % @ltidata method
         if isComplexResponse(Amplitude)
            d.Exception = true;
            d.ExceptionReason = message('Controllib:plots:PlotComplexData');
         else
            d.Amplitude = real(Amplitude);
         end
         d.Time = t;
         d.Focus = [t(1) t(end)];
         d.Ts = Dsys.Ts;
         d.TimeUnits = this.getTimeUnits;
      catch ME
         d.Exception = true;
         d.ExceptionReason = ME.message;
      end
   end
end

end


