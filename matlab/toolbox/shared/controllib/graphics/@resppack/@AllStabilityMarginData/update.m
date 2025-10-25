function update(cd,r)
%UPDATE  Data update method @AllStabilityMarginData class

%  Author(s): John Glass
%   Copyright 1986-2021 The MathWorks, Inc.

rdata = cd.Parent;
if length(r.RowIndex)==1 && length(r.ColumnIndex)==1
   freq = rdata.Frequency*funitconv(rdata.FreqUnits,'rad/s');
   Focus = rdata.Focus*funitconv(rdata.FreqUnits,'rad/s');
   try
      % Compute margins from model data
      r.DataSrc.getmargin('all',cd,find(r.Data==rdata),freq);
   catch
      % Compute margins from response data (IMARGIN, sparse)
      % If the response data type is resppack.freqdata, (i.e. Nyquist),
      % then convert to magnitude and phase.  Otherwise use the magnitude
      % and phase from the response data.
      if isa(rdata,'resppack.freqdata')
         mag = abs(rdata.Response);
         phase = unitconv(unwrap(angle(rdata.Response)),'rad','deg');
      else
         mag = unitconv(rdata.Magnitude,rdata.MagUnits,'abs');
         phase = unitconv(rdata.Phase,rdata.PhaseUnits,'deg');
      end
      
      % Compute gain and phase margins
      s = allmargin(mag,phase,freq,rdata.Ts,0);
      
      cd.GainMargin  = s.GainMargin;
      cd.GMFrequency = s.GMFrequency;
      cd.GMPhase = 180 * round(utInterp1(freq,phase,s.GMFrequency)/180);
      cd.PhaseMargin = s.PhaseMargin;
      cd.PMFrequency = s.PMFrequency;
      cd.PMPhase = utInterp1(freq,phase,s.PMFrequency);
      cd.DelayMargin = s.DelayMargin;
      cd.DMFrequency = s.DMFrequency;
      cd.Ts = rdata.Ts;
      cd.Stable = NaN;
   end
   
   % Extend frequency focus by up to two decades to include margin markers
   MarginFreqs = abs([cd.GMFrequency cd.PMFrequency cd.DMFrequency]);
   if isempty(Focus)
      MarginFreqs = MarginFreqs(:,MarginFreqs>0 & MarginFreqs<Inf);
      Focus = [min(MarginFreqs)/2,2*max(MarginFreqs)];
   else
      w = abs(rdata.Frequency);  w = sort(w(w>0,:));
      MarginFreqs = MarginFreqs(:,MarginFreqs >= max(w(1),Focus(1)/100) & ...
         MarginFreqs <= min(w(end),Focus(2)*100));
      Focus = [min([Focus(1),MarginFreqs]),max([Focus(2),MarginFreqs])];
   end
   rdata.Focus = Focus*funitconv('rad/s',rdata.FreqUnits);
   
else
   cd.GainMargin = zeros(1,0);
   cd.GMFrequency = zeros(1,0);
   cd.GMPhase = zeros(1,0);
   cd.PhaseMargin = zeros(1,0); 
   cd.PMFrequency = zeros(1,0);
   cd.PMPhase = zeros(1,0);
   cd.DelayMargin = zeros(1,0);   
   cd.DMFrequency = zeros(1,0);
end
