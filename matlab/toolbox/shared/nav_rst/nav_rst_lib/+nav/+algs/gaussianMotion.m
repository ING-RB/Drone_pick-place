function predictParticles = gaussianMotion(pf, prevParticles)
%gaussianMotion Simple linear motion model that adds zero-mean Gaussian noise to the set of particles
%   All state variables are assumed to be non-circular.

%   Copyright 2015-2019 The MathWorks, Inc.

%#codegen

    predictParticles = matlabshared.tracking.internal.gaussianMotion(pf, prevParticles);

end
