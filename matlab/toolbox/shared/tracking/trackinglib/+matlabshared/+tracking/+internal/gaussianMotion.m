function predictParticles = gaussianMotion(pf, prevParticles)
%gaussianMotion Simple linear motion model that adds zero-mean Gaussian noise to the set of particles
%   All state variables are assumed to be non-circular.

%   Copyright 2015 The MathWorks, Inc.

%#codegen

% Linear state transition
stateTransitionModel = eye(pf.NumStateVariables);

% Gaussian unit variance on each state variable
processNoise = eye(pf.NumStateVariables);

% Sample the Gaussian noise
dist = matlabshared.tracking.internal.NormalDistribution(pf.NumStateVariables);
dist.Mean = zeros(1,pf.NumStateVariables);
dist.Covariance = processNoise;
noise = dist.sample(pf.NumParticles);

% Evolve the particle state and add Gaussian noise
predictParticles = prevParticles * stateTransitionModel.' + noise;

end
