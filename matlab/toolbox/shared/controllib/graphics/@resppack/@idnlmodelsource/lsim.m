function lsim(this, r)
% Updates lsim plot response data

%  Author(s): Rajiv Singh
%  Copyright 1986-2005 The MathWorks, Inc.

SimInput = r.Parent.Input; % @siminput instance
SysData = this.Model;
NormalRefresh = strncmp(r.RefreshMode,'normal',1);
[~,nu] = iosize(SysData(1));

% Retrieve t,u,x0 data
if strcmp(r.Parent.InputStyle,'tiled')
   % If there are insufficient inputs or missing time vectors ->
   % exception
   InputData = SimInput.Data(r.Context.InputIndex); % handle vector
   if NormalRefresh && any(cellfun('isempty',get(InputData,{'Amplitude'})))
      return
   end
   % Get the input data and initial states
   t = InputData(1).Time;
   for ct=nu:-1:1
      u(:,ct) = InputData(ct).Amplitude;  % ns-by-nu
   end
else
   t = SimInput.Data.Time;
   u = SimInput.Data.Amplitude;
end
x0 = r.Context.IC;

% Update data
% Look for visible+cleared responses in response array
if isempty(r.Data.Amplitude) && ...
      strcmp(r.View.Visible,'on') && isfinite(SysData)
   d = r.Data;
   try
      % Skip if model is NaN or response cannot be computed
      Warn = ctrlMsgUtils.SuspendWarnings; %#ok<NASGU>
      d.Amplitude = lsim(SysData,u,t,x0,SimInput.Interpolation);
      
      d.Time = t;
      d.Focus = [t(1) t(end)];
      d.Ts =  SysData.Ts;
   end
end
