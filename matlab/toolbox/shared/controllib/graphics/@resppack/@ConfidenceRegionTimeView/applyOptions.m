function applyOptions(this, Options)
% APPLYOPTIONS  Synchronizes plot options with those of characteristics
 
%  Author(s): Craig Buhr
%  Copyright 2009-2010 The MathWorks, Inc.

% Set new preferences
if isfield(Options, 'ConfidenceRegionDisplayType')
    this.UncertainType = Options.ConfidenceRegionDisplayType;
end