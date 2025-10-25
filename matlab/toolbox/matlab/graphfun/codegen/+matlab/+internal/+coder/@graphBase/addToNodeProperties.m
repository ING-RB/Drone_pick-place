function [nodeProperties, newnodes] = addToNodeProperties(G, N)
%

%   Copyright 2021 The MathWorks, Inc.
%#codegen

isValidNameType = matlab.internal.coder.isValidNameType(N);
coder.internal.assert(~isValidNameType,'MATLAB:graphfun:codegen:NodeNamesNotSupported');

if isnumeric(N) && coder.internal.isConstTrue(isscalar(N))
    nodeProperties = G.NodeProperties;
    coder.internal.assert(isreal(N) && fix(N) == N && N>=0 && isfinite(N), ...
        'MATLAB:graphfun:addnode:InvalidNrNodes');
    nodeProperties = nodeProperties.append([],N);
    % No special case if G has node properties - this is handled by graphPropertyContainer        
    newnodes = N;
else
    coder.internal.assert(istable(N),'MATLAB:graphfun:addnode:SecondInput')
    nodeProperties = G.NodeProperties;
    % Node name uniqueness not checked because names are not supported
    % in codegen
    nodeProperties = nodeProperties.append(N);
    newnodes = size(N,1);
end
end
