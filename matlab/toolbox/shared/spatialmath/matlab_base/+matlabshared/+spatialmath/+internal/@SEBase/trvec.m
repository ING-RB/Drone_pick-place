function transl = trvec(obj, varargin)
%TRVEC Extract translation vector
%
%   TRANSL = TRVEC(T) extracts the translational part of the SE3
%   transformation, T, and returns it as a 3-element row vector,
%   TRANSL. The rotational part of T is ignored.
%
%   If T is an array with N transformations, then TRANSL is an
%   N-by-3 matrix containing N translation rows. Each row vector
%   is of the form [x y z].
%
%   TRANSL = TRVEC(..., Name=Value) specifies additional
%   options using one or more name-value pair arguments.
%   Specify the options after all other input arguments.
%
%       IsCol - If true, then TRANSL is an 3-by-N matrix containing
%       N translation columns. Each column vector is of the form
%       [x y z]'. Default: false
%
%   See also rotm, tform.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Make name-value parser persistent to improve performance over
% multiple calls
    persistent parser

    % Parse name-value pairs (if they are specified)
    isCol = false;
    if nargin > 1
        if isempty(parser)
            parser = robotics.core.internal.NameValueParser({'IsCol'}, {false});
        end
        parse(parser, varargin{:});
        isCol = robotics.internal.validation.validateLogical(parameterValue(parser, 'IsCol'));
    end

    d = obj.Dim;

    % Extract translation vector from last column
    translMD = obj.M(1:d-1, d, :);

    % Shape output as specified
    if ~isCol
        transl = permute(translMD, [3 1 2]);
    else
        transl = squeeze(translMD);
    end

end
