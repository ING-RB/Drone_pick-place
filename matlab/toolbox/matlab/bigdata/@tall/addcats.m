function tb = addcats(ta,varargin)
%ADDCATS Add categories to a tall categorical array.
%   B = ADDCATS(A,NEWCATEGORIES)
%   B = ADDCATS(A,NEWCATEGORIES,'Before',WHERE)
%   B = ADDCATS(A,NEWCATEGORIES,'After',WHERE)
%
%   See also CATEGORICAL/ADDCATS.

%   Copyright 2016-2019 The MathWorks, Inc.

narginchk(2,4);
if nargout == 0
    error(message('MATLAB:categorical:NoLHS',upper(mfilename),',NEW,...'));
end
tb = categoricalPiece(mfilename, ta, varargin{:});
end
