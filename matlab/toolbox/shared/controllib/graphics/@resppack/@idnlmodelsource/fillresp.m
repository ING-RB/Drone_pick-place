function UpdateFlag = fillresp(this, r, Tfinal)
%FILLRESP  Update data to span the current X-axis range.

%  Author(s): Rajiv Singh
%  Copyright 2010 The MathWorks, Inc.

UpdateFlag = false;
if ~isfield(r.Context,'Type')
   return
else
   RespType = r.Context.Type;
end

% Check for missing data
for ct=1:length(r.Data)
   rdata = r.Data(ct);
   ns = size(rdata.Amplitude,1);
   UpdateFlag = (ns>1 && rdata.Time(ns-1)<Tfinal && ...
      (rdata.Time(ns)<Tfinal || ~all(isfinite(rdata.Amplitude(ns,:)))));
   if UpdateFlag
      break
   end
end

% Plot-type-specific settings
if UpdateFlag
   if strcmp(RespType,'step')
      x0 = [];
   end
   % Extend response past Tfinal
   %SysData = getPrivateData(this.Model);
   d = r.Data;
   Tstart = d.Focus(1);
   [d.Amplitude, d.Time] = timeresp(this.Model, RespType, [Tstart 1.5*Tfinal], x0);
end
