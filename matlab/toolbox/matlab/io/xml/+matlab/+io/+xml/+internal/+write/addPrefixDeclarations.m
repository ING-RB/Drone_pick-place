function prefixesWithDeclarations = addPrefixDeclarations(prefixes)
%

%   Copyright 2020 The MathWorks, Inc.

prefixesWithDeclarations = strings(length(prefixes), 2);

for idx = 1:length(prefixes)
    prefixesWithDeclarations(idx, 1) = "xmlns:" + prefixes(idx);
    prefixesWithDeclarations(idx, 2) = "https://mathworks.com/table/ns_" + idx;
end

end