function validateNumericMatrix(M, funcname, varname, varargin)
%This function is for internal use only. It may be removed in the future.

%validateNumericMatrix Validate numeric matrix
%   validateNumericMatrix(M, FUNCNAME, VARNAME) validates whether the input
%   M represents a valid numeric matrix.  Each input vector is expected to
%   be in one row. FUNCNAME and VARNAME are used in VALIDATEATTRIBUTES to
%   construct the error id and message.
%
%   validateNumericMatrix(___, VARARGIN) specifies additional attributes
%   supported in VALIDATEATTRIBUTES, such as sizes and dimensions, in a
%   cell array VARARGIN.

%   Copyright 2014-2023 The MathWorks, Inc.

%#codegen

% Main validation step. Only use validations that do not require
% element-by-element access (for performance).
% Optionally, apply additional validations
    validateattributes(M, {'single','double'}, {'nonempty','real','2d',varargin{:}}, ...
                       funcname, varname);

end
