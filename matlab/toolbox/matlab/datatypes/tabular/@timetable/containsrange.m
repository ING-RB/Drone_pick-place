function [tf,tfRow] = containsrange(tt,timeSpec)
%

%   Copyright 2019-2024 The MathWorks, Inc.

[tfRow,ttMin,ttMax,timeSpec] = concurrencyCommon(tt,timeSpec);

if matches(timeSpec.type,'open') && timeSpec.first == timeSpec.last
    % degenerate open interval
    tf = false;
else
    tf = timeSpec.first>=ttMin && timeSpec.last<=ttMax;
end
