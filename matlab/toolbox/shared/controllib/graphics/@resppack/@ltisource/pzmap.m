function pzmap(this,r,ioflag,PadeOrder)
%PZMAP   Updates Pole Zero Plots based on i/o flag. 
%        This is the  Data-Source implementation of pzmap.         

%  Author(s): Kamesh Subbarao
%   Copyright 1986-2011 The MathWorks, Inc.

% IOFLAG is either absent or set to 'io' string
if nargin < 3 || isempty(ioflag)
   ioflag = false;
else
   ioflag = true;
end

nsys = length(r.Data);
SysData = getModelData(this);
TimeUnits = this.Model.TimeUnit;
if numel(SysData)~=nsys
   return  % number of models does not match number of data objects
end

% Always set IOFLAG=true in SISO case to compute zeros consistent with ZPK
% representation
if nsys>0 && isequal(iosize(SysData(1)),[1 1])
   ioflag = true;
end

% Get new data from the @ltisource object.
if ioflag
   % Pole/zero map for individual I/O pairs
   for ct=1:nsys
      % Look for visible+cleared responses in response array
      if strcmp(r.View(ct).Visible,'on') && isfinite(SysData(ct)) && ...
            isempty(r.Data(ct).Poles)
         Dsys = SysData(ct);
         d = r.Data(ct);
         try
            if nargin == 4 && ~isempty(PadeOrder) && hasInternalDelay(Dsys)
               Dsys = pade(Dsys,PadeOrder,PadeOrder,PadeOrder);
            end
            [d.Zeros,d.Poles] = iodynamics(Dsys);
            d.Ts = Dsys.Ts;
            d.TimeUnits = TimeUnits;
         catch ME
            d.Exception = true;
            d.ExceptionReason = ME.message;
         end
      end
   end
   
else
   % Poles and transmission zeros (only for MIMO with IOFLAG=false)
   for ct=1:nsys
      % Look for visible+cleared responses in response array
      if strcmp(r.View(ct).Visible,'on') && isfinite(SysData(ct)) && ...
            isempty(r.Data(ct).Poles)
         Dsys = SysData(ct);
         d = r.Data(ct);
         try
             if nargin == 4 && ~isempty(PadeOrder) && hasInternalDelay(Dsys)
                 Dsys = pade(Dsys,PadeOrder,PadeOrder,PadeOrder);
             end
            d.Poles = {pole(Dsys)};
            d.Zeros = {tzero(Dsys)};
            d.Ts = Dsys.Ts;
            d.TimeUnits = TimeUnits;
         catch ME
            d.Exception = true;
            d.ExceptionReason = ME.message;
         end
      end
   end
   
end
