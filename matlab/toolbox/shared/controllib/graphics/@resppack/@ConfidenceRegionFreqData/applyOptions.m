function applyOptions(this, Options)
% APPLYOPTIONS  Synchronizes plot options with those of characteristics
 
%  Author(s):  C. Buhr
%  Copyright 1986-2011 The MathWorks, Inc.

% Call parent classes options
applyNumSDOptions(this, Options)

cOpts = get(this(1), 'ConfidenceDisplaySampling');

% Set new preferences
if isfield(Options, 'ConfidenceDisplaySampling') && ...
      (Options.ConfidenceDisplaySampling ~= cOpts)
  clear(this); % Vectorized clear
  set(this, 'ConfidenceDisplaySampling', Options.ConfidenceDisplaySampling);
end
