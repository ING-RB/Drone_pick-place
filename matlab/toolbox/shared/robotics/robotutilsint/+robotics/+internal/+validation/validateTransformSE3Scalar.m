function tform = validateTransformSE3Scalar(T, funcname, varname, attrArgs)
%This function is for internal use only. It may be removed in the future.

%validateTransformSE3Scalar Validate numeric or se3 transformation
%   validateTransformSE3Scalar(T, FUNCNAME, VARNAME) validates whether the
%   input T represents a valid scalar homogeneous transformation. T should
%   be a 4x4 numeric matrix or a scalar se3 object. FUNCNAME and VARNAME
%   are used in VALIDATEATTRIBUTES to construct the error id and message.
%
%   validateTransformSE3Scalar(___, ATTRARGS) specifies additional
%   attributes supported in VALIDATEATTRIBUTES, such as sizes and
%   dimensions, in a cell array ATTRARGS. These attributes will only be
%   applied if the input T is numerical.
%
%   TFORM = validateTransformSE3Scalar(___) optionally returns the
%   validated transformation as numeric 4x4 matrix, TFORM,

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen


% Main validation step
% Optionally, apply additional validations and return output argument

    if nargin < 4
        attrArgs = {};
    end

    if isfloat(T)
        validateattributes(T, {'single','double'}, {'nonempty','real','2d', ...
                                                    'size', [4 4], attrArgs{:}}, funcname, varname);

        if nargout > 0
            tform = T;
        end

    else
        validateattributes(T, {'se3'}, {'nonempty','scalar'}, ...
                           funcname, varname);

        if nargout > 0
            tform = T.tform;
        end
    end

end
