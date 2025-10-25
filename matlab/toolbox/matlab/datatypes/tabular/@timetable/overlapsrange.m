function [tf,tfRow] = overlapsrange(tt,timeSpec)
%

%   Copyright 2019-2024 The MathWorks, Inc.

[tfRow,ttMin,ttMax,timeSpec] = concurrencyCommon(tt,timeSpec);

switch timeSpec.type
case 'open'
    tf = timeSpec.first<ttMax && timeSpec.last>ttMin;
case 'closed'
    tf = timeSpec.first<=ttMax && timeSpec.last>=ttMin;
case {'openleft', 'closedright'}
    tf = timeSpec.first<ttMax && timeSpec.last>=ttMin;
case {'openright', 'closedleft'}
    tf = timeSpec.first<=ttMax && timeSpec.last>ttMin;
end
