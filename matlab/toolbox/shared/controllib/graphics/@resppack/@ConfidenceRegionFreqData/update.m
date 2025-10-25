function update(this,r)
%UPDATE  Data update method @ConfidenceRegionFreqData class.

%   Author(s): Craig Buhr
%   Copyright 1986-2015 The MathWorks, Inc.

if ~isempty(this.Data), return; end
idxModel = find(r.Data==this.Parent);
m = r.DataSrc.getModelData(idxModel);
this.Ts = r.DataSrc.Model(:,:,idxModel).Ts;
this.TimeUnits = r.DataSrc.Model(:,:,idxModel).TimeUnit;
w = this.Parent.Frequency;
f = funitconv(this.Parent.FreqUnits,'rad/TimeUnit',this.TimeUnits)*w;
CovData = covFresp(m,f(1:this.ConfidenceDisplaySampling:end));
if ~isempty(CovData)   
    this.Data.Response = this.Parent.Response(1:this.ConfidenceDisplaySampling:end,:,:);
    this.Data.Frequency = f(1:this.ConfidenceDisplaySampling:end);
    this.Data.Cov =  (this.NumSD)^2*CovData;
end

