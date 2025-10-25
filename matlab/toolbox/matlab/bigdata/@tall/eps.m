function y = eps(varargin)
%EPS  Spacing of floating point numbers for tall arrays
%   Y = EPS(T)
%   Y = EPS("like",T)
%
%   See also: eps, tall.

%   Copyright 2021 The MathWorks, Inc.


narginchk(1,2);
if nargin>1
    if ~matlab.internal.datatypes.isScalarText(varargin{1}) ...
            || ~startsWith("like",varargin{1},"IgnoreCase",true)
        error(message("MATLAB:eps:mustBeLike"));
    end
    y = epsLike(varargin{2});
else
    y = elementfun(@eps, varargin{1});
    y.Adaptor = varargin{1}.Adaptor; % Input and output are same size and type
end

end
