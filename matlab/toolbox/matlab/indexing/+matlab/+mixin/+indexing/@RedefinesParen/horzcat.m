%HORZCAT  Horizontal concatenation
%   Given inputs A and B, the default implementation calls cat(2, A, B).
%
%   See also vertcat, cat

%    Copyright 2020-2021 The MathWorks, Inc.

function C = horzcat(varargin)
    C = cat(2, varargin{:});
end
