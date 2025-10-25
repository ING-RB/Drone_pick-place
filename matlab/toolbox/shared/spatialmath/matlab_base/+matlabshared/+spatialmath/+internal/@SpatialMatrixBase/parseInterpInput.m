function [interpVec, numInterps] = parseInterpInput(T1,T2,pts)
%This method is for internal use only. It may be removed in the future.

%parseInterpInput Parses the input to the normalize function
%   [INTERPVEC, NUMINTERPS] = parseInterpInput(T1,T2,PTS) parses the arguments provided to
%   interp, T1, T2, and PTS, and returns the interpolation points in the
%   range [0,1] as INTERPVEC. NUMINTERPS contains the number of
%   interpolations that have to be performed. If both T1 and T2 are
%   scalars, NUMINTERPS is 1. If one of them is an array, NUMINTERPS
%   contains max(numel(T1), numel(T2)).

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Make sure both spatial matrix objects are of the same type
    matlabshared.spatialmath.internal.SpatialMatrixBase.parseSpatialMatrixInput(T1,T2);

    % Ensure at least one object is a scalar
    numInterps = max(numel(T1), numel(T2));
    coder.internal.assert(isscalar(T1) || isscalar(T2), "shared_spatialmath:matobj:ScalarArg", "interp");
    if isempty(T1) || isempty(T2)
        % If one of the inputs is empty, return an empty set of
        % interpolations
        numInterps = 0;
    end

    validateattributes(pts, "numeric", {'real', 'row', 'nonnegative', 'nonnan', 'finite'}, "interp", "pts");
    if isscalar(pts) && pts >= 1
        % Syntax: INTERP(T1,T2,N)
        % Interpolate for N number of steps. This needs to be an integer
        coder.internal.assert(floor(pts)==pts, "shared_spatialmath:matobj:ExpectedInteger", "pts");
        interpVec = linspace(0,1,pts);
    else
        % Syntax: INTERP(T1, T2, PTS)
        % Just take the validated pts as-is.
        interpVec = pts;
    end

end
