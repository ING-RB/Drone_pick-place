function dir = sortDirectionChoices(flag)
% A list of valid values for the direction input of sort, sortrows, issorted, issortedrows,
% and topkrows.

%   Copyright 2020 The MathWorks, Inc.
if nargin == 0
    dir = {'ascend','descend'};
elseif strcmp(flag,'is*')
    dir = {'ascend','descend','monotonic','strictascend','strictdescend','strictmonotonic'};
else
    assert(false);
end