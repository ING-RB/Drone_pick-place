function out = matlabCodegenFromRedirected(obj)
%This method is for internal use only. It may be removed in the future.

%matlabCodegenFromRedirected Enables se2 objects to be returned from generated MEX to MATLAB
%   This method is executed in MATLAB.

% Copyright 2022-2024 The MathWorks, Inc.

    out = se2.fromMatrix(obj.M, size(obj.MInd));
end
