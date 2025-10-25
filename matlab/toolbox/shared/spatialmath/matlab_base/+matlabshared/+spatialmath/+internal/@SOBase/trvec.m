function transl = trvec(obj, varargin)
%TRVEC Create translation vector
%   TRANSL = TRVEC(R) creates a 2-element or 3-element row vector
%   corresponding to zero translation. TRANSL is [0 0] or [0 0 0].
%
%   If R is an array with R rotations, then TRANSL is an N-by-2 or N-by-3
%   matrix containing N translation rows.
%
%   TRANSL = TRVEC(..., Name=Value) specifies additional options using one
%   or more name-value pair arguments. Specify the options after all other
%   input arguments.
%
%       IsCol - If true, then TRANSL is an 2-by-N or 3-by-N matrix
%       containing N translation columns. Default: false
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

    if ~isCol
        transl = zeros(size(obj.M,3),obj.Dim,"like",obj.M);
    else
        transl = zeros(obj.Dim,size(obj.M,3),"like",obj.M);
    end

end
