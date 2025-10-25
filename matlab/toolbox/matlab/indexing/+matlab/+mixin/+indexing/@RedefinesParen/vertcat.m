%VERTCAT  Vertical concatenation
%   Given inputs A and B, the default implementation calls cat(1, A, B).
%
%   See also horzcat, cat

%   Copyright 2020-2021 The MathWorks, Inc.

function C = vertcat(varargin)
    C = cat(1, varargin{:});
end
