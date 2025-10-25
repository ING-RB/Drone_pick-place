function validateRotationMatrix(R, funcname, varname, varargin)
%This function is for internal use only. It may be removed in the future.

%validateRotationMatrix Validate rotation matrix
%   validateRotationMatrix(R, FUNCNAME, VARNAME) validates whether the input
%   R represents a valid rotation matrix. R should be a 3x3xN
%   matrix and orthonormal. FUNCNAME and VARNAME are used
%   in VALIDATEATTRIBUTES to construct the error id and message.
%
%   validateRotationMatrix(___, VARARGIN) specifies additional attributes
%   supported in VALIDATEATTRIBUTES, such as sizes and dimensions, in a
%   cell array VARARGIN.

%   Copyright 2014-2023 The MathWorks, Inc.

%#codegen

% Main validation step
% Optionally, apply additional validations

    validateattributes(R, {'single','double'}, {'nonempty', ...
                                                'real','3d','size',[3 3 NaN],varargin{:}}, ...
                       funcname, varname);

    % Rotation matrices are orthogonal (have rank 3) and should be
    % normalized. Should we check for this?

end
