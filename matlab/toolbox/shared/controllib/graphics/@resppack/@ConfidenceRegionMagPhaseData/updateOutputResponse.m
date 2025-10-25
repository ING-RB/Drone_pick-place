function updateOutputResponse(this,r)
%UPDATEOUTPUTRESPONSE UPDATE implementation for output signal.

% Copyright 2016 The MathWorks, Inc.

PlotType = r.Parent.PlotType;

% plot type could be sim, predict or compare
sys = r.DataSrc.Model;
idxModel = find(r.Data==this.Parent);
sys_ = sys(:,:,idxModel);
if isa(sys_,'iddata') || isa(sys_, 'idnlarx') || isa(sys_, 'idnlhw') ||...
      ~isa(sys_,'idmodel')
   return;
end

%sys = r.DataSrc.getModelData(idxModel); %#ok<FNDSB>
[ny, ~] = iosize(sys_);
Context = r.Context;
K = Context.Horizon;
Init = Context.IC;
kexp = Context.ExpNo;
datasrc = r.Parent.RefData.DataSrc;
if isa(datasrc,'resppack.ltisource')
   data = datasrc.Model;
else
   data = datasrc.IOData.getData;
   data = getexp(data,kexp);
end
uOrd = Context.DataInputOrder;
yOrd = Context.DataOutputOrder;
I = ~isnan(yOrd);
Options = Context.Options;

if isinf(K) && isa(sys_,'idParametric') || isa(sys_,'idnlgrey')
   if strcmp(PlotType,'compare')
      [~,~,~,~,ysd] = idpack.compareResp(data,sys_,K,Init,kexp,uOrd, yOrd,Options,false,true);
   else
      % call iduis.plots.sim
   end
else
   return
end

ysd1 = ysd{1};
if ~isempty(ysd1)
   r.Data(idxModel).MagnitudeSD = ysd1{1}(:,I);
   r.Data(idxModel).PhaseSD = ysd1{2}(:,I);
else
   r.Data(idxModel).MagnitudeSD = [];
   r.Data(idxModel).PhaseSD = [];
end

k = 1;
for ky = 1:ny
   if I(ky)
      this.Data(k).Frequency = r.Data(idxModel).Frequency;
      this.Data(k).Magnitude = r.Data(idxModel).Magnitude(:,k);
      this.Data(k).Phase = r.Data(idxModel).Phase(:,k);
      
      magsd = r.Data(idxModel).MagnitudeSD;
      phsd = r.Data(idxModel).PhaseSD;
      if ~isempty(magsd)
         this.Data(k).MagnitudeSD = this.NumSD*magsd(:,k);
         this.Data(k).PhaseSD = this.NumSD*phsd(:,k);
      else
         this.Data(k).MagnitudeSD = [];
         this.Data(k).PhaseSD = [];
      end
      k = k+1;
   end
end

this.Ts = sys.Ts;
this.TimeUnits = sys.TimeUnit;
