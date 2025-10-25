function update(cd,~)
%UPDATE  Data update method.

%   Copyright 1986-2020 The MathWorks, Inc.
rdata = cd.Parent;
freq = rdata.Frequency*funitconv(rdata.FreqUnits,'rad/s');
Focus = rdata.Focus*funitconv(rdata.FreqUnits,'rad/s');
alpha = rdata.DiskMargin;
mag = unitconv(rdata.Magnitude,rdata.MagUnits,'abs');
phase = unitconv(rdata.Phase,rdata.PhaseUnits,'deg');

if all(alpha==0)
   % Unstable
   cd.DiskMargin = 0;
   cd.GainMargin = 1;
   cd.PhaseMargin = 0;
   cd.DMFrequency = 1;
else
   % Compute min disk margin
   [cd.DiskMargin,idx] = min(alpha);
   MarginFreq = freq(idx);
   cd.GainMargin = mag(idx);
   cd.PhaseMargin = phase(idx);
   cd.DMFrequency = MarginFreq;
   
   % Extend frequency focus by up to two decades to include margin markers
   if isempty(Focus)
      Focus = [min(MarginFreq)/2,2*max(MarginFreq)];
   elseif MarginFreq >= max(freq(1),Focus(1)/100) && ...
         MarginFreq <= min(freq(end),Focus(2)*100)
      Focus = [min([Focus(1),MarginFreq]),max([Focus(2),MarginFreq])];
   end
   rdata.Focus = Focus*funitconv('rad/s',rdata.FreqUnits);
end

