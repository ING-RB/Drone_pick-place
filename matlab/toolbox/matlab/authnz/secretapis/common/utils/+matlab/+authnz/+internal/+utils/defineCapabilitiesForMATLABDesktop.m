function defineCapabilitiesForMATLABDesktop()
%   This function ensures that all the capabilities
%   are present for MATLAB desktop usecase and their
%   absence can indicate the following:-
%   1. InteractiveCommandLine: Batch mode
%   2. Swing: nojvm mode
%
%   Copyright 2023-2024 The MathWorks, Inc.

import matlab.internal.capability.Capability
Capability.require([Capability.InteractiveCommandLine ...
    Capability.Swing]);
end