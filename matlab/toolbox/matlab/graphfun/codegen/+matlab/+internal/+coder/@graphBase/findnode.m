function ind = findnode(G, N)
%

%#codegen
%   Copyright 2021 The MathWorks, Inc.
if isnumeric(N)
    N = N(:);
    % Validate node numbers
    coder.internal.assert(isreal(N),'MATLAB:graphfun:findnode:PosInt');
    for ii = coder.internal.indexInt(1):numel(N)
        currentN = N(ii);
        coder.internal.assert(fix(currentN) == currentN && ...
            currentN >= 1, 'MATLAB:graphfun:findnode:PosInt');
    end
    ind = double(N);
    ind(ind > numnodes(G)) = 0;    
else
    % Pick which error to throw: NodeNamesNotSupported if N looks like
    % a node name, ArgType if it looks like a type that's not supported in
    % the in-memory version
    coder.internal.assert(~matlab.internal.coder.isValidNameType(N), ...
        'MATLAB:graphfun:codegen:NodeNamesNotSupported');    
    coder.internal.assert(false,'MATLAB:graphfun:findnode:ArgType');
end
