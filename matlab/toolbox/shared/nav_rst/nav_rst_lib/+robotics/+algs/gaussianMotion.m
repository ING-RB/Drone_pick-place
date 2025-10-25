function predictParticles = gaussianMotion(varargin)
%gaussianMotion Simple linear motion model that adds zero-mean Gaussian noise to the set of particles
%   robotics.algs.gaussianMotion is not recommended. Use nav.algs.gaussianMotion instead.
%
%   See also: nav.algs.gaussianMotion.

%   Copyright 2015-2019 The MathWorks, Inc.

%#codegen

    % Forward all arguments to new function
    predictParticles = nav.algs.gaussianMotion(varargin{:});

end
