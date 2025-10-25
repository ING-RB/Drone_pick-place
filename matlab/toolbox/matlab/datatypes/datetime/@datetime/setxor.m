function [c,ia,ib] = setxor(a,b,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

[rows,sorted] = setMembershipFlags(varargin{:});

[aData,bData,c] = datetime.compareUtil(a,b);

if nargout < 2
    cData = setxor(aData,bData,varargin{:});
    if sorted
        cData = setMembershipSort(cData,rows);
    end
else
    [cData,ia,ib] = setxor(aData,bData,varargin{:});
    if sorted
        cData = setMembershipSort(cData,rows);
        [~,ia] = setMembershipSort(aData(ia),ia,rows);
        [~,ib] = setMembershipSort(bData(ib),ib,rows);
    end
end


c.data = cData;
