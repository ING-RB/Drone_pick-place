function rpts = transform(obj, pts, varargin)
%TRANSFORM Apply rigid body rotation to points
%   RPTS = TRANSFORM(R, PTS) applies the rigid body rotation, R, to the
%   input 2-D or 3-D points PTS and returns the rotated points RPTS. Both
%   PTS and RPTS are assumed to by N-by-2 or N-by-3 matrices. If R is an
%   array of M rotations, the output RPTS will be an N-by-2-by-M or
%   N-by-3-by-M array with each of the M pages corresponding to the
%   rotations of PTS by each element in R.
%
%   TPTS = TRANSFORM(..., Name=Value) specifies additional options using
%   one or more name-value pair arguments. Specify the options after all
%   other input arguments.
%
%       IsCol - If true, then the input PTS has point coordinates as
%       columns, so it is a 2-by-N or 3-by-N matrix. Default: false

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

    % Actual rotation code

    if ~isCol
        % Points are row vectors

        robotics.internal.validation.validateNumericMatrix(pts, "transform", "pts", "ncols", d);

        % Apply rotation. Use post-multiply here. For a larger number of
        % points, the overhead of transposing the matrix is cheaper than
        % transposing the points.
        rpts = pagemtimes(pts, "none", obj.M, "transpose");
    else
        % Points are column vectors

        robotics.internal.validation.validateNumericMatrix(pts, "transform", "pts", "nrows", d);

        if isempty(obj)
            % Special handling of empty object array, since pagemtimes will
            % fail otherwise. The extra operations are necessary to ensure
            % that standard MATLAB data type and size handling applies.
            rpts = pagetranspose(pagemtimes(pts,"transpose",obj.M,"none"));
        else
            % Apply rotation. Use pre-multiply here, since the points are
            % already column vectors.
            rpts = pagemtimes(obj.M, pts);
        end
    end

end
