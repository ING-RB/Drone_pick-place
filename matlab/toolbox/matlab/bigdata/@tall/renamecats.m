function tb = renamecats(ta,varargin)
%RENAMECATS Rename categories in a tall categorical array.
%   B = RENAMECATS(A,NAMES)
%   B = RENAMECATS(A,OLDNAMES,NEWNAMES)
%
%   See also CATEGORICAL/RENAMECATS.

%   Copyright 2016-2019 The MathWorks, Inc.

narginchk(2,3);
if nargout == 0
    if nargin < 3
        error(message('MATLAB:categorical:NoLHS',upper(mfilename),',NEWNAMES'));
    else
        error(message('MATLAB:categorical:NoLHS',upper(mfilename),',OLDNAMES,NEWNAMES'));
    end
end
tb = categoricalPiece(mfilename, ta, varargin{:});
end
