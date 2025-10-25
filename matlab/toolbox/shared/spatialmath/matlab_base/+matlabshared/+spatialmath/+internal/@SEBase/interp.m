function Tint = interp(T1, T2, pts)
%INTERP Interpolate poses
%
%   TINT = INTERP(T1, T2, PTS) interpolates between poses represented
%   by transformations T1 and T2. PTS varies from 0 (at pose T1) to
%   1 (at pose T2). If PTS is a vector (1xN) then the output, TINT, will
%   be a row vector of transformations.
%   Either T1 or T2 must be a scalar. If one of the transformations is an
%   array with M elements, the function will interpolate between the scalar and each
%   array element in linear ordering. In this case, the output TINT will be
%   an M-by-N object array, with each row corresponding to one interpolation.
%
%   TINT = INTERP(T1, T2, N) returns a 1-by-N vector of transformations,
%   interpolated between T1 and T2 in N steps. N needs to be an integer
%   >= 1.
%
%   The rotation is interpolated through a quaternion slerp.
%   The translation is linearly interpolated. If not already normalized,
%   T1 and T2 will be normalized if they are part of the output array TINT.
%
%   See also normalize, transformtraj, rottraj.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    narginchk(3,3)
    % Parse inputs
    [interpVec, numRows] = matlabshared.spatialmath.internal.SpatialMatrixBase.parseInterpInput(T1,T2,pts);
    numCols = length(interpVec);

    % Extract and expand translations and rotations (scalar expansion, so if a
    % scalar is passed in T1 and T2, we expand to the full length of the
    % non-scalar).
    % Convert rotations to quaternions
    t1 = toTrvec(T1, numRows);
    t2 = toTrvec(T2, numRows);
    q1 = toQuaternion(T1, numRows);
    q2 = toQuaternion(T2, numRows);


    % Preallocate output. Use a numeric matrix for performance.
    % Use "z" to figure out what data type the resulting array should be
    % (based on standard MATLAB rules for output types of operations).
    z = zeros(1,underlyingType(T1)) + zeros(1,underlyingType(T2));
    Mint = zeros(T1.Dim, T1.Dim, numRows*numCols, class(z));

    % For each requested interpolation
    for i = 1:numRows
        % Interpolate translation and rotation separately
        transl = t1(:,i) + (t2(:,i) - t1(:,i))*interpVec;
        qint = slerp(q1(i), q2(i), interpVec);
        rot = rotmat(qint,"point");

        % Assign row in output array
        idx = sub2ind([numRows numCols], i*ones(1,numCols), 1:numCols);
        Mint(:,:,idx) = rt2tform(T1,rot,transl);
    end

    % Convert to transformation object
    Tint = T1.fromMatrix(Mint, [numRows numCols]);

end
