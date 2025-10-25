function [tf,tfRow] = withinrange(tt,timeSpec)
%

%   Copyright 2019-2024 The MathWorks, Inc.

[tfRow,ttMin,ttMax,timeSpec] = concurrencyCommon(tt,timeSpec);

switch timeSpec.type
case 'open'
    tf = ttMin>timeSpec.first && ttMax<timeSpec.last;
case 'closed'
    tf = ttMin>=timeSpec.first && ttMax<=timeSpec.last;
case {'openleft', 'closedright'}
    tf = ttMin>timeSpec.first && ttMax<=timeSpec.last;
case {'openright', 'closedleft'}
    tf = ttMin>=timeSpec.first && ttMax<timeSpec.last;
end
