function update(this,~)
%UPDATE  Data update method @ConfidenceRegionStepTimeData class

% Copyright 2015 The MathWorks, Inc.

% Struct Data(ny,nu,2).Amplitude
%                     .SD
Amp = this.Parent.Amplitude;
SD = this.Parent.AmplitudeSD;
[N,ny,nu] = size(this.Parent.Amplitude);
for yct = 1:ny
   for uct = 1:nu
      this.Data(yct,uct).Amplitude = Amp(:,yct,uct);
      this.Data(yct,uct).AmplitudeSD = this.NumSD*SD(yct,uct)*ones(N,1);
   end
end
