%#codegen
function [G, EdgeProps, NodeProps] = constructFromTable(...
    underlyingCtor, msgFlag, ETable, varargin)
% CONSTRUCTFROMTABLE Construct graph/digraph from tables

% Copyright 2021 The MathWorks, Inc.

coder.internal.assert(nargin <= 5, 'MATLAB:maxrhs');
coder.internal.assert(ETable.Properties.VariableNames{1} == "EndNodes", ...
    ['MATLAB:graphfun:' msgFlag ':InvalidTableFormat']);
EndNodes = ETable.EndNodes;
coder.internal.assert(ismatrix(EndNodes) && size(EndNodes,2) == 2 && ...
        (isnumeric(EndNodes) || iscellstr(EndNodes) || isstring(EndNodes)), ...
        ['MATLAB:graphfun:' msgFlag ':InvalidTableSize']);
% Peel off back argument and check for 'omitselfloops'
if coder.internal.isConstTrue(numel(varargin) > 0)
    flag = varargin{end};
    if (ischar(flag) && isrow(flag)) || (isstring(flag) && isscalar(flag))
        omitLoops = startsWith("omitselfloops", flag, 'IgnoreCase', true) && strlength(flag) > 0;
        coder.internal.assert(omitLoops, ['MATLAB:graphfun:' msgFlag ':InvalidFlag']);
        coder.internal.assert(coder.internal.isConst(flag),'Coder:toolbox:OptionStringsMustBeConstant');
        if numel(varargin) > 1
            vararginDuplicate = varargin{1:end-1};
        else
            vararginDuplicate = {};
        end
        omitFlag = {flag};
    else
        coder.internal.assert(nargin ~= 5, ['MATLAB:graphfun:' msgFlag ':InvalidFlag']);
        vararginDuplicate = varargin;
        omitFlag = {};
    end
else
    vararginDuplicate = varargin;
    omitFlag = {};
end

if ~isempty(vararginDuplicate)
    coder.internal.assert(istable(vararginDuplicate{1}), ['MATLAB:graphfun:' msgFlag ':SecondNotTable']);
    NTable = {vararginDuplicate{1}};
else
    NTable = {};
end
[G, EdgeProps, NodeProps] = matlab.internal.coder.constructFromEdgeList(...
        underlyingCtor, msgFlag, ...
        EndNodes(:,1), EndNodes(:,2), ETable(:,2:end), NTable{:}, omitFlag{:});

