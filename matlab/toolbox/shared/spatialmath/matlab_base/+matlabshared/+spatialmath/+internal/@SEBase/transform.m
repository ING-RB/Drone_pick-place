function tpts = transform(obj, pts, varargin)
%TRANSFORM Apply rigid body transformation to points
%   TPTS = TRANSFORM(T, PTS) applies the rigid body
%   transformation of T to the input 3D points PTS and
%   returns the transformed points TPTS. Both PTS and TPTS are
%   assumed to by N-by-3 matrices. If T is an array of M transformations,
%   the output TPTS will be an N-by-3-by-M matrix with each of the
%   M pages corresponding to the transformation of PTS by each element in T.
%
%   TPTS = TRANSFORM(..., Name=Value) specifies additional
%   options using one or more name-value pair arguments.
%   Specify the options after all other input arguments.
%
%       IsCol - If true, then the input PTS has point
%       coordinates as columns, so it is a 3-by-N matrix.
%       Default: false

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Parse name-value pairs (if they are specified)
    isCol = false;
    if nargin > 2
        params.IsCol = false;
        s = coder.internal.nvparse(params,varargin{:});
        isCol = robotics.internal.validation.validateLogical(s.IsCol);
    end

    d = obj.Dim;

    % Actual transformation code

    if ~isCol
        % Points are row vectors

        robotics.internal.validation.validateNumericMatrix(pts, "transform", "pts", "ncols", d-1);

        % Make points homogeneous by adding column of 1s
        ptsHom = horzcat(pts, ones(size(pts,1), 1, "like", pts));

        % Apply transformation. Use post-multiply here. For a larger number of
        % points, the overhead of transposing the matrix is cheaper than
        % transposing the points.
        tptsHom = pagemtimes(ptsHom, "none", obj.M, "transpose");

        % Convert back to Cartesian. We can just take the first 3 columns since
        % transformation matrices always have scale 1.
        tpts = tptsHom(:,1:d-1,:);
    else

        robotics.internal.validation.validateNumericMatrix(pts, "transform", "pts", "nrows", d-1);

        % Points are column vectors

        % Make points homogeneous by adding row of 1s
        ptsHom = vertcat(pts, ones(1, size(pts,2), "like", pts));

        % Apply transformation. Use pre-multiply here, since the points are
        % already column vectors.
        tptsHom = pagemtimes(obj.M, ptsHom);

        % Convert back to Cartesian. We can just take the first 3 rows since
        % transformation matrices always have scale 1.
        tpts = tptsHom(1:d-1,:,:);
    end

end
