function c = countcats(a,dim)
%

%   Copyright 2013-2024 The MathWorks, Inc. 

if nargin < 2
    c = histc(a.codes,1:length(a.categoryNames)); %#ok<HISTC>
else
    c = histc(a.codes,1:length(a.categoryNames),dim); %#ok<HISTC>
end

