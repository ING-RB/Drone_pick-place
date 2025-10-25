function UpdateFlag = fillresp(this, r, Tfinal)
%FILLRESP  Update data to span the current X-axis range.

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2023 The MathWorks, Inc.

% Tfinal is assummed to be in visual units. Need to convert to Data Units
Tfinal = Tfinal*tunitconv(r.Parent.AxesGrid.XUnits,this.getTimeUnits);
UpdateFlag = false;
if ~isfield(r.Context,'Type')
   return
else
   RespType = r.Context.Type;   
end

% Check for missing data
for ct=1:numel(r.Data)
   t = r.Data(ct).Time;
   ns = numel(t);
   if ~all(isfinite(r.Data(ct).Amplitude(ns,:)))
      ns = ns-1;
   end
   % Note: Be robust to rounding errors from unit conversions etc
   UpdateFlag = (ns>0 && t(ns)<Tfinal-0.001*(t(2)-t(1)));
   if UpdateFlag
      break
   end
end

% Plot-type-specific settings
if UpdateFlag
   Config = r.Context.Config;
   SysData = getModelData(this);
   for ct=1:numel(r.Data)
      d = r.Data(ct);
      Tstart = d.Focus(1);
      if isfinite(SysData(ct))
         % Extend response past Tfinal
         [d.Amplitude, d.Time] = timeresp(SysData(ct), RespType, [Tstart 1.5*Tfinal], Config);
      end
   end
end
