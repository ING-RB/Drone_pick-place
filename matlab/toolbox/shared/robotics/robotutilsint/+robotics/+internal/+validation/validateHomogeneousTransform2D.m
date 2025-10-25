function validateHomogeneousTransform2D(H, funcname, varname, varargin)
%This function is for internal use only. It may be removed in the future.

%validateHomogeneousTransform2D Validate 2D homogeneous transformation
%   validateHomogeneousTransform2D(H, FUNCNAME, VARNAME) validates whether the input
%   H represents a valid homogeneous transformation. H should be a 3x3xN
%   matrix. FUNCNAME and VARNAME are used in VALIDATEATTRIBUTES to construct
%   the error id and message.
%
%   validateHomogeneousTransform2D(___, VARARGIN) specifies additional attributes
%   supported in VALIDATEATTRIBUTES, such as sizes and dimensions, in a
%   cell array VARARGIN.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

% Main validation step
% Optionally, apply additional validations

    validateattributes(H, {'single','double'}, {'nonempty','real','3d', ...
                                                'size',[3 3 NaN],varargin{:}}, ...
                       funcname, varname);

    % Homogeneous matrices should be normalized and have an orthonormal
    % rotation submatrix. We are not checking for that here, since this
    % kind of check would be expensive and fragile.

end
