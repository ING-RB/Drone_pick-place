function setFreqFocus(this,fspec,funits)
% Sets user-defined x-range in frequency-domain plots like BODE. 
%
% FSPEC is a frequency range {FMIN,FMAX}, a frequency grid, or [].

%  Copyright 1986-2021 The MathWorks, Inc.
FreqFocus = ltipack.getFreqFocus(fspec,0);  % user-defined focus, in funits
this.FreqFocus = FreqFocus * funitconv(funits,'rad/s'); % stored in rad/s
