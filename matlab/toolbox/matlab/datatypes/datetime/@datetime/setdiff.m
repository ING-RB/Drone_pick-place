function [c,ia] = setdiff(a,b,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

[rows,sorted] = setMembershipFlags(varargin{:});

[aData,bData,c] = datetime.compareUtil(a,b);

if nargout < 2
    cData = setdiff(aData,bData,varargin{:});
    if sorted
        cData = setMembershipSort(cData,rows);
    end
else
    [cData,ia] = setdiff(aData,bData,varargin{:});
    if sorted
        [cData,ia] = setMembershipSort(cData,ia,rows);
    end
end
c.data = cData;
