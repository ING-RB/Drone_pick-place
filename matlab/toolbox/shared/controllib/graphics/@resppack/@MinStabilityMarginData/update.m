function update(cd,r)
%UPDATE  Data update method @MinStabilityMarginData class

%  Author(s): John Glass
%   Copyright 1986-2010 The MathWorks, Inc.

rdata = cd.Parent;
if length(r.RowIndex)==1 && length(r.ColumnIndex)==1
   freq = rdata.Frequency*funitconv(rdata.FreqUnits,'rad/s');
   Focus = rdata.Focus*funitconv(rdata.FreqUnits,'rad/s');
   try
      % May error if no data source of model is complex
      r.DataSrc.getmargin('min',cd,find(r.Data==rdata),freq);
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
      
      % Compute gain and phase margins for k=th model
      if isempty(mag)
         Gm = Inf;  Pm = 180;  Wcg = NaN;  Wcp = NaN;
      else
         [Gm,Pm,Wcg,Wcp] = imargin(mag,phase,freq);
      end
      % Compute Delay margins
      Dm = utComputeDelayMargins(Pm*(pi/180),Wcp,rdata.Ts,0);
      [Gm,Pm,Wcg,Wcp,Dm] = utMarginPlotData(Gm,Pm,Wcg,Wcp,Dm);
      cd.GainMargin  = Gm;   
      cd.GMFrequency = Wcg;
      cd.GMPhase = 180 * round(utInterp1(freq,phase,Wcg)/180);
      cd.PhaseMargin = Pm;
      cd.PMFrequency = Wcp;
      cd.PMPhase = utInterp1(freq,phase,Wcp);
      cd.DMFrequency = Wcp;
      cd.DelayMargin = Dm;
      cd.Ts = rdata.Ts;
      cd.Stable = NaN;
   end
   
   % Extend frequency focus by up to two decades to include margin markers
   MarginFreqs = [cd.GMFrequency cd.PMFrequency cd.DMFrequency];
   if isempty(Focus)
      MarginFreqs = MarginFreqs(:,isfinite(MarginFreqs) & MarginFreqs>0);
      Focus = [min(MarginFreqs)/2,2*max(MarginFreqs)];
   else
      MarginFreqs = MarginFreqs(:,MarginFreqs >= max(rdata.Frequency(1),Focus(1)/100) & ...
         MarginFreqs <= min(rdata.Frequency(end),Focus(2)*100));
      Focus = [min([Focus(1),MarginFreqs]),max([Focus(2),MarginFreqs])];
   end
   rdata.Focus = Focus*funitconv('rad/s',rdata.FreqUnits);
   
else
   cd.GMFrequency = zeros(1,0);
   cd.GainMargin = zeros(1,0);
   cd.PMFrequency = zeros(1,0);
   cd.PhaseMargin = zeros(1,0); 
   cd.DMFrequency = zeros(1,0);
   cd.DelayMargin = zeros(1,0);   
end
