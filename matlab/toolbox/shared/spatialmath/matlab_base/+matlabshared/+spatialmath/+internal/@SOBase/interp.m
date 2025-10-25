function Rint = interp(R1, R2, pts)
%INTERP Interpolate rotations
%
%   TINT = INTERP(R1, R2, PTS) interpolates between rotations R1 and R2.
%   PTS varies from 0 (at rotation R1) to 1 (at rotation R2).
%   If PTS is a vector (1xN) then the output, TINT, will
%   be a row vector of rotations.
%   Either R1 or R2 must be a scalar. If one of the rotations is an
%   array with M elements, the function will interpolate between the scalar and each
%   array element in linear ordering. In this case, the output TINT will be
%   an M-by-N object array, with each row corresponding to one interpolation.
%
%   TINT = INTERP(R1, R2, N) returns a 1-by-N vector of rotations,
%   interpolated between R1 and R2 in N steps. N needs to be an integer
%   >= 1.
%
%   The rotation is interpolated through a quaternion slerp.
%   If not already normalized, R1 and R2 will be normalized if they are
%   part of the output array TINT.
%
%   See also normalize, rottraj.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Parse inputs
    narginchk(3,3)
    [interpVec, numRows] = matlabshared.spatialmath.internal.SpatialMatrixBase.parseInterpInput(R1,R2,pts);
    numCols = length(interpVec);

    % Extract and expand rotations (scalar expansion, so if a
    % scalar is passed in R1 and R2, we expand to the full length of the
    % non-scalar). Convert rotations to quaternions
    q1 = toQuaternion(R1, numRows);
    q2 = toQuaternion(R2, numRows);

    % Preallocate output. Use a numeric matrix for performance.
    % Use "z" to figure out what data type the resulting array should be
    % (based on standard MATLAB rules for output types of operations).
    z = zeros(1,underlyingType(R1)) + zeros(1,underlyingType(R2));
    Mint = zeros(R1.Dim, R1.Dim, numRows*numCols, class(z));

    % For each requested interpolation
    for i = 1:numRows
        qint = slerp(q1(i), q2(i), interpVec);

        % Assign row in output array
        idx = sub2ind([numRows numCols], i*ones(1,numCols), 1:numCols);
        Mint(:,:,idx) = R1.quatToRotm(qint);
    end

    % Convert to rotation object
    Rint = R1.fromMatrix(Mint, [numRows numCols]);

end
