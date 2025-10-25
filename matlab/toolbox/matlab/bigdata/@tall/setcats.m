function tb = setcats(ta,varargin)
%SETCATS Add categories to a tall categorical array.
%   B = SETCATS(A,NEWCATEGORIES)
%
%   See also CATEGORICAL/SETCATS.

%   Copyright 2016-2019 The MathWorks, Inc.

narginchk(2,2);
if nargout == 0
    error(message('MATLAB:categorical:NoLHS',upper(mfilename),',NEWCATEGORIES'));
end
tb = categoricalPiece(mfilename, ta, varargin{:});
end
