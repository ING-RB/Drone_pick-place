function update(this,r)
%UPDATE  Data update method @ConfidenceRegionSpectrumData class.

%   Author(s): Rajiv Singh
%   Copyright 1986-2015 The MathWorks, Inc.

if ~isempty(this.Data), return; end
idxModel = find(r.Data==this.Parent);
m = r.DataSrc.getModelData(idxModel); %#ok<FNDSB>
modelTU = r.DataSrc.Model.TimeUnit;
[ny, ~] = iosize(m);
w = this.Parent.Frequency;
f = funitconv(this.Parent.FreqUnits,'rad/TimeUnit',modelTU)*w;
covns = covNoiseSpectrum(m,f); 
Mag = this.Parent.Magnitude;
SDMag = sqrt(covns);
%[Mag,w,SDMag] = spectrum(r.DataSrc.Model(:,:,idxModel),this.Parent.Frequency);
if ~isempty(SDMag)
    for yct = 1:ny
        for uct = 1:ny
            this.Data(yct,uct).Magnitude = Mag(:,yct,uct);
            this.Data(yct,uct).MagnitudeSD = this.NumSD*SDMag(yct,uct,:);
            this.Data(yct,uct).Frequency = f;
        end
    end
end

this.Ts = m.Ts;
this.TimeUnits = modelTU;
