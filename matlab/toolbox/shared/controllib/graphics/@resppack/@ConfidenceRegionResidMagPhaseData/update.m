function update(this,r)
%UPDATE  Data update method @ConfidenceRegionResidMagPhaseData class.

%   Copyright 2015 The MathWorks, Inc.

[~,ny,nu] = size(this.Parent.Magnitude);
modelTU = r.DataSrc.Model.TimeUnit;
modelTs = r.DataSrc.Model.Ts;

w = this.Parent.Frequency;
f = funitconv(this.Parent.FreqUnits,'rad/TimeUnit',modelTU)*w;
SDMag = this.Parent.MagnitudeSD;
SDPhase = this.Parent.PhaseSD;
Mag = this.Parent.Magnitude;
Phase = this.Parent.Phase;
if ~isempty(SDMag)
   for yct = 1:ny
      for uct = 1:nu
         thisMag = Mag(:,yct,uct);
         thisSDMag = squeeze(SDMag(yct,uct,:));
         thisPhase = Phase(:,yct,uct);
         thisSDPhase = squeeze(SDPhase(yct,uct,:));
         
         this.Data(yct,uct).Magnitude = thisMag;
         this.Data(yct,uct).MagnitudeSD = this.NumSD*thisSDMag;
         this.Data(yct,uct).Phase = thisPhase;
         this.Data(yct,uct).PhaseSD = this.NumSD*thisSDPhase;
         this.Data(yct,uct).Frequency = f;
      end
   end
end

this.Ts = modelTs;
this.TimeUnits = modelTU;
