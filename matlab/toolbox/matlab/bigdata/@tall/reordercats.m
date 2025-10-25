function tb = reordercats(ta,varargin)
%REORDERCATS Reorder categories in a tall categorical array.
%   B = REORDERCATS(A)
%   B = REORDERCATS(A,NEWORDER)
%
%   See also CATEGORICAL/REORDERCATS.

%   Copyright 2016-2023 The MathWorks, Inc.

narginchk(1,2);
if nargout == 0
    error(message('MATLAB:categorical:NoLHS',upper(mfilename),',NEWORDER'));
end
tb = categoricalPiece(mfilename, ta, varargin{:});
end
