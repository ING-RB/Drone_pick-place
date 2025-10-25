function out = matlabCodegenToRedirected(in)
%This method is for internal use only. It may be removed in the future.

%matlabCodegenToRedirected Enables se2 objects to be passed from MATLAB to generated MEX
%   This method is executed in MATLAB.

% Copyright 2022-2024 The MathWorks, Inc.

    out = matlabshared.spatialmath.internal.coder.SE2cg.fromMatrix(in.M, size(in.MInd));

end
