function C = edgecount(G,s_in,t_in)
%

%   Copyright 2021 The MathWorks, Inc.
%#codegen

% Validate s
if isnumeric(s_in)
    s = G.validateNodeID(s_in);
    % This throws a separate error message for complex s, which the in-memory code does not do
    coder.internal.assert(~issparse(s),'MATLAB:graphfun:findnode:ArgType');
else
    % This branch will always error.
    % Check if s is valid for in-memory but not codegen
    s = s_in;
    coder.internal.assert(~matlab.internal.coder.isValidNameType(s),'MATLAB:graphfun:codegen:NodeNamesNotSupported');
    % s is an invalid type
    coder.internal.assert(false,'MATLAB:graphfun:findnode:ArgType')
end

% Validate t
if isnumeric(t_in)
    t = G.validateNodeID(t_in);
    % This throws a separate error message for compex t, which the in-memory code does not do
    coder.internal.assert(~issparse(t),'MATLAB:graphfun:findnode:ArgType');
else
    % This branch will always error.
    % Check if t is valid for in-memory but not codegen
    t = t_in;
    coder.internal.assert(matlab.internal.coder.isValidNameType(t),'MATLAB:graphfun:codegen:NodeNamesNotSupported');
    % t is an invalid type
    coder.internal.assert(false,'MATLAB:graphfun:findnode:ArgType')
end

[edgeind, tind] = findedge(G.Underlying, s(:), t(:));

if isscalar(s)
    numToFind = numel(t);
else
    numToFind = numel(s);
end

C = zeros(numToFind,1);
ONE = coder.internal.indexInt(1);

if G.ismultigraph
    edgeIter = ONE;
    for ii = ONE:numToFind
        if edgeind(edgeIter) ~= 0
            C(ii) = 1;
            edgeIter = edgeIter + ONE;
            while edgeIter <= numel(tind) && tind(edgeIter) == ii
                % No need to check edgeind again - it will be non-zero until tind(edgeIter)~=ii
                C(ii) = C(ii) + 1;
                edgeIter = edgeIter + ONE;
            end
        else
            edgeIter = edgeIter + ONE;
        end
    end
else
    for ii = ONE:numToFind
        if edgeind(ii) ~= 0
            C(ii) = 1;
        end
    end
end
end