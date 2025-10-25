function getFundamentalFreq(this,characteristic,gridsize,freq,frequnits)
%  GETFUNDAMENTALFREQ obtains the fundamental frequency data for the
%  characteristics.
%
%


% Author(s): Erman Korkut 18-Mar-2009
% Revised:
% Copyright 1986-2010 The MathWorks, Inc.

% Find response the frequency
resp = characteristic.Parent;
[junk,freqind] = min(abs(resp.Data.Frequency(:)-freq*funitconv(frequnits,resp.Data.FreqUnits)));

for ctin = 1:gridsize(2)
    for ctout = 1:gridsize(1)
        characteristic.Data.Frequency(ctout,ctin) = freq*funitconv(frequnits,resp.Parent.AxesGrid.XUnits);
        % Ppopulate gain/phase        
        characteristic.Data.PeakGain(ctout,ctin) = resp.Data.Magnitude(freqind,ctout,ctin);
        characteristic.Data.PeakPhase(ctout,ctin) = resp.Data.Phase(freqind,ctout,ctin);
    end
end














