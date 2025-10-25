function validateRotationMatrix2D(R, funcname, varname, varargin)
%This function is for internal use only. It may be removed in the future.

%validateRotationMatrix2D Validate rotation matrix
%   validateRotationMatrix2D(R, FUNCNAME, VARNAME) validates whether the input
%   R represents a valid rotation matrix. R should be a 2x2xN
%   matrix and orthonormal. FUNCNAME and VARNAME are used
%   in VALIDATEATTRIBUTES to construct the error id and message.
%
%   validateRotationMatrix2D(___, VARARGIN) specifies additional attributes
%   supported in VALIDATEATTRIBUTES, such as sizes and dimensions, in a
%   cell array VARARGIN.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

% Main validation step
% Optionally, apply additional validations

    validateattributes(R, {'single','double'}, {'nonempty', ...
                                                'real','3d','size',[2 2 NaN],varargin{:}}, ...
                       funcname, varname);

    % Rotation matrices are orthogonal (have rank 2) and should be
    % normalized. We are not checking for that here, since this
    % kind of check would be expensive and fragile.
end
