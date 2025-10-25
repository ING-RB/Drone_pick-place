function applyNumSDOptions(this, Options)
% APPLYOPTIONS  Synchronizes plot options with those of characteristics
 
%  Author(s): Bora Eryilmaz
%  Copyright 1986-2011 The MathWorks, Inc.

cOpts = get(this(1), 'NumSD');

% Set new preferences
if isfield(Options, 'ConfidenceNumSD') && ...
      (Options.ConfidenceNumSD ~= cOpts)
  clear(this); % Vectorized clear
  set(this, 'NumSD', Options.ConfidenceNumSD);
end
