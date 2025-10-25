function update(this,r)
%UPDATE  Data update method @UncertainRegionMagPhaseData class.

%   Copyright 1986-2016 The MathWorks, Inc.

if ~isempty(this.Data), return; end
PlotType = 'bode';
if isprop(r.Parent,'PlotType')
   PlotType = r.Parent.PlotType;
end

if any(strcmp(PlotType,{'compare','sim'})) && r.Parent.IsIddata
   updateOutputResponse(this, r)
   return
end

idxModel = find(r.Data==this.Parent);
w = this.Parent.Frequency;
sys = r.DataSrc.getModelData(idxModel); %#ok<FNDSB>

if isa(r.DataSrc.Model, 'idmodel')
    if isa(sys,'idpack.frddata')
        cov = sys.ResponseCovariance;
    else
        cov = sys.Covariance; % works for both models and idpack.ltidata
    end
else
    return
end

[ny, nu] = iosize(sys);
modelTU = r.DataSrc.Model.TimeUnit;
f = funitconv(this.Parent.FreqUnits,'rad/TimeUnit',modelTU)*w;
[CovMag, CovPh] = covMagPhaseSpectrum(sys, f);
SDMag = sqrt(CovMag); SDPhase = sqrt(CovPh);

Mag = this.Parent.Magnitude;
Phase = this.Parent.Phase;
%[Mag,Phase,w,SDMag,SDPhase] = bode(r.DataSrc.Model(:,:,idxModel),this.Parent.Frequency);
NeedInterp = isa(sys,'idpack.frddata') && ~FRDModel.isSameFrequencyGrid(sys.Frequency,f);
if NeedInterp
   w0 = sys.Frequency;
   [CovMag0, CovPh0] = covMagPhaseSpectrum(sys, w0);
   SDMag0 = sqrt(CovMag0); SDPhase0 = sqrt(CovPh0);
end
if ~isempty(SDMag)
   for yct = 1:ny
      for uct = 1:nu
         thisMag = Mag(:,yct,uct);
         thisSDMag = squeeze(SDMag(yct,uct,:));
         thisPhase = Phase(:,yct,uct);
         thisSDPhase = squeeze(SDPhase(yct,uct,:));
         if NeedInterp
            % interpolate for possible NaN values
            thisSDMag = interp1(w0, squeeze(SDMag0(yct,uct,:)),f);
            thisSDPhase = interp1(w0, squeeze(SDPhase0(yct,uct,:)),f);
         end
         
         this.Data(yct,uct).Magnitude = thisMag;
         this.Data(yct,uct).MagnitudeSD = this.NumSD*thisSDMag;
         this.Data(yct,uct).Phase = thisPhase;
         this.Data(yct,uct).PhaseSD = this.NumSD*thisSDPhase;
         this.Data(yct,uct).Frequency = f;
      end
   end
else
   for yct = 1:ny
      for uct = 1:nu
         this.Data(yct,uct).Magnitude = [];
         this.Data(yct,uct).Phase = [];
         this.Data(yct,uct).MagnitudeSD = [];
         this.Data(yct,uct).PhaseSD = [];
         this.Data(yct,uct).Frequency = []; 
      end
   end
end

this.Ts = sys.Ts;
this.TimeUnits = modelTU;

%
%    % Compute uncertain responses
% if isempty(r.DataSrc)% || ~isUncertain(r.DataSrc)
% % If there is no source do not give a valid yf gain result.
%    % Set Data to NaNs
%    this.Ts = r.DataSrc.Ts;
%    %yf = NaN(nrows,ncols);
% else
%    % If the response contains a source object compute the uncertain
%    % Responses
%    %t = this.Parent.Time(1:end-1);
%    %getUncertainTimeRespData(r.DataSrc,'step',r,this,t);
%    getUncertainMagPhaseData(r.DataSrc,'bode',r,this,[]);
%
% end
%