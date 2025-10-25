function likelihood = fullStateMeasurement(pf, predictParticles, measurement)
%fullStateMeasurement Compute likelihood of a full state measurement.
%   All state variables are assumed to be non-circular.

%   Copyright 2015-2019 The MathWorks, Inc.

%#codegen

    likelihood = matlabshared.tracking.internal.fullStateMeasurement(pf, predictParticles, measurement);

end
