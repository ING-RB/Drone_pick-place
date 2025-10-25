function numericMatrix = validateQuaternion(q, funcname, varname)
%This function is for internal use only. It may be removed in the future.

%VALIDATEQUATERNION Validate quaternion and return it as N-by-4 numeric matrix
%   NUMERICMATRIX = VALIDATEQUATERNION(Q, FUNCNAME, VARNAME) validates
%   whether the input Q represents a valid quaternion and returns the input
%   quaternion, Q, as N-by-4 numeric matrix, NUMERICMATRIX, where each row
%   is one quaternion. The input quaternion, Q, is expected to be either
%   N-by-4 numeric matrix of row quaternions, or N-by-1 or 1-by-N vector of
%   QUATERNION objects. FUNCNAME and VARNAME are used in
%   VALIDATEATTRIBUTES to construct the error id and message.

%   Copyright 2017-2023 The MathWorks, Inc.

%#codegen

    if (isa(q, 'quaternion'))

        % Extract quaternion parts
        [w,x,y,z] = parts(q);

        % Validate that the input quaternion is non-empty and that the input is
        % a vector. The validateattributes function is not supported for
        % quaternion input. Therefore, the validateattributes is called on each
        % part separately.
        validateattributes(w, {'numeric'}, {'nonempty', 'vector'}, funcname, varname);
        validateattributes(x, {'numeric'}, {'nonempty', 'vector'}, funcname, varname);
        validateattributes(y, {'numeric'}, {'nonempty', 'vector'}, funcname, varname);
        validateattributes(z, {'numeric'}, {'nonempty', 'vector'}, funcname, varname);

        % If the quaternion input is a row vector, transpose it to get a column
        % vector
        if (isrow(w))
            w = w';
            x = x';
            y = y';
            z = z';
        end

        % Save quaternion parts as N-by-4 numeric matrix
        numericMatrix = [w,x,y,z];

    else

        % Validate that the input is N-by-4 numeric matrix
        robotics.internal.validation.validateNumericMatrix(q, funcname, varname, ...
                                                           'ncols', 4);

        % Return the input as is
        numericMatrix = q;

    end

end
