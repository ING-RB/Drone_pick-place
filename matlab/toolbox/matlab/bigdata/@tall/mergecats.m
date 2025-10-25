function tb = mergecats(ta,varargin)
%MERGECATS Merge categories in a tall categorical array.
%   B = MERGECATS(A,OLDCATEGORIES,NEWCATEGORY)
%   B = MERGECATS(A,CATEGORIES)
%
%   See also CATEGORICAL/MERGECATS.

%   Copyright 2016-2019 The MathWorks, Inc.

narginchk(2,3);
if nargout == 0
    error(message('MATLAB:categorical:NoLHS',upper(mfilename),',OLD,NEW'));
end
tb = categoricalPiece(mfilename, ta, varargin{:});
end
