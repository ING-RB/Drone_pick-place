function src = validateNodeID(G, s)
%

%   Copyright 2021 The MathWorks, Inc.
%#codegen
coder.inline('always');
coder.internal.assert(isnumeric(s),'MATLAB:graphfun:codegen:NodeNamesNotSupported');

s = s(:);
validID = true;
numNodes = numnodes(G);
coder.internal.assert(isreal(s),'MATLAB:graphfun:codegen:ComplexNodeID');

if coder.internal.isConst(s)
    coder.unroll(); % This allows constant folding for constant vector inputs
end
for ii = coder.internal.indexInt(1):numel(s)
    currentS = s(ii);
    validID = validID && fix(currentS) == currentS ...
        && currentS >= 1 && currentS <= numNodes;
end

if coder.internal.isConst(validID)
    % Error without numnodes if validID is const so this error can be
    % thrown during code generation
    coder.internal.assert(validID, 'MATLAB:graphfun:codegen:InvalidNodeID');
else
    coder.internal.assert(validID, ['MATLAB:graphfun:' G.errTag ':InvalidNodeID'], numnodes(G));
end
src = double(s);
end