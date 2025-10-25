function applyOptions(this, Options)
% APPLYOPTIONS  Synchronizes plot options with those of characteristics
 
%  Author(s): Bora Eryilmaz
%  Copyright 1986-2007 The MathWorks, Inc.

cOpts = get(this(1), 'SettlingTimeThreshold');

% Set new preferences
if isfield(Options, 'SettlingTimeThreshold') && ...
      (Options.SettlingTimeThreshold ~= cOpts)
  clear(this); % Vectorized clear
  set(this, 'SettlingTimeThreshold', Options.SettlingTimeThreshold);
end
