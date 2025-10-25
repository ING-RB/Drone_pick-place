function p1 = copyPlotOptions(p1,p2)
% COPYPLOTOPTIONS Copies applicable properties from p2 to p1

%  Copyright 1986-2005 The MathWorks, Inc.

p1props = fields(p1);
p2props = fields(p2);

% Find common properties
p1p2props = intersect(p1props,p2props);

% Copy common properties
for ct = 1:length(p1p2props)
    p1.(p1p2props{ct}) = p2.(p1p2props{ct});
end
    