function pvPairs = structToPVPairs(structValue)
%structToPVPairs convert a structure into pvpair format

%   Copyright 2017 The MathWorks, Inc.

if isempty(structValue)
    pvPairs = {};
    return;
end

params = fieldnames(structValue);
values = struct2cell(structValue);
pvPairs = [params values]';
pvPairs = pvPairs(:);

% [EOF]
