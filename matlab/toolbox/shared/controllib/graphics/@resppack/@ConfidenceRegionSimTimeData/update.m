function update(this,r)
%UPDATE  Data update method @ConfidenceRegionSimTimeData class.

%   Copyright 1986-2022 The MathWorks, Inc.

if ~isempty(this.Data), return; end
PlotType = r.Parent.PlotType;
ModelSrc = r.DataSrc;
Context = r.Context;
K = Context.Horizon;
kexp = Context.ExpNo;
idxModel = find(r.Data==this.Parent);
if strcmp(PlotType,'compare')
   Init = Context.IC;
else
   Init = Context.Options.IC_;
end
Init = localGetInitForOneExp(Init, kexp);

% add protection for empty source etc
sys = ModelSrc.Model;
sys_ = sys(:,:,idxModel);
if isa(sys_,'iddata') || isa(sys_, 'idnlarx') || isa(sys_, 'idnlhw') || ...
      ~isa(sys_,'idmodel')
   return;
end

uOrd = Context.DataInputOrder;
yOrd = Context.DataOutputOrder;
I = ~isnan(yOrd);
Options = Context.Options;
[ny, ~] = iosize(sys_);

% response changes only when IC or K changes
datasrc = r.Parent.RefData.DataSrc;
if isa(datasrc,'resppack.ltisource')
   data = datasrc.Model;
else
   data = datasrc.IOData.getData;
   data = getexp(data,kexp);
end

ysd = cell(size(r.Data));
if strcmp(PlotType,'forecast')
   uFuture = r.Parent.RefData.Context.FutureInput;
   if ~isempty(uFuture)
      uFuture = getexp(uFuture,kexp);
   end
   Options = getsubsysOptions(Options, yOrd, uOrd);
   data = data(:,yOrd,uOrd);
   if ~isempty(uFuture)
      uFuture = uFuture(:, :, uOrd);
   end
   if isa(sys_,'idnlgrey')
      sys_ = idnlgrey.getOneExpSys(sys_,kexp);
   end
   Options.InitialCondition = Init;
   Options.ComputeYSD = true;
   Out = forecast_(sys_, data, K, uFuture, Options);
   ysd = {Out.Y.SD};
elseif (isinf(K) && isa(sys_,'idParametric')) || isa(sys_,'idnlgrey')
   if strcmp(PlotType,'compare')
      [~,~,~,~,ysd] = idpack.compareResp(data,sys_,K,Init,kexp,uOrd,...
         yOrd,Options,false,true);
   else
      % call iduis.plots.sim 
   end
elseif ~strcmp(PlotType,'compare')
  assert(false,'Unknown PlotType "%s" for ConfidenceRegionSimTimeData.',PlotType)
else
   return % compare with finite horizon
end

ysd1 = ysd{1};
if ~isempty(ysd1) && norm(ysd1,1)>0
   if datasrc.IsReal
      r.Data(idxModel).AmplitudeSD = ysd1(:,I);
   else
      r.Data(idxModel).AmplitudeSD = cat(3,real(ysd1(:,I)),imag(ysd1(:,I)));
   end
else
   r.Data(idxModel).AmplitudeSD = [];
end

k = 1;
for ky = 1:ny
   if I(ky)
      % do not create "Data" container for missing channels (I(ky) false). 
      this.Data(k).Amplitude = r.Data(idxModel).Amplitude(:,k);
      ysd2 = r.Data(idxModel).AmplitudeSD;
      if ~isempty(ysd2)
         this.Data(k).AmplitudeSD = this.NumSD*ysd2(:,k);
      else
         this.Data(k).AmplitudeSD = [];
      end
      this.Data(k).Time = r.Data(idxModel).Time;
      k = k+1;
   end
end
this.Ts = sys_.Ts;
this.TimeUnit = sys_.TimeUnit;

%--------------------------------------------------------------------------
function Initkexp = localGetInitForOneExp(Init, kexp)
% Slice initial condition value for one data experiment.

if isequal(Init,[])
   Initkexp = Init;
elseif isa(Init,'param.Continuous') && size(Init.Value,2)>1
   Initkexp = subsrefParameter(Init,{':',kexp});
elseif isnumeric(Init)
   Initkexp = Init(:,min(kexp,end));
else
   Initkexp = Init;
end
