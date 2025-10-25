function validateHomogeneousTransform(H, funcname, varname, varargin)
%This function is for internal use only. It may be removed in the future.

%validateHomogeneousTransform Validate homogeneous transformation
%   validateHomogeneousTransform(H, FUNCNAME, VARNAME) validates whether the input
%   H represents a valid homogeneous transformation. H should be a 4x4xN
%   matrix. FUNCNAME and VARNAME are used in VALIDATEATTRIBUTES to construct
%   the error id and message.
%
%   validateHomogeneousTransform(___, VARARGIN) specifies additional attributes
%   supported in VALIDATEATTRIBUTES, such as sizes and dimensions, in a
%   cell array VARARGIN.

%   Copyright 2014-2023 The MathWorks, Inc.

%#codegen

% Main validation step
% Optionally, apply additional validations

    validateattributes(H, {'single','double'}, {'nonempty','real','3d', ...
                                                'size',[4 4 NaN],varargin{:}}, ...
                       funcname, varname);

    % Homogeneous matrices should be normalized. Should we check for this?

end
