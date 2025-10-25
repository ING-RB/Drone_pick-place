function [bins, binSize] = conncomp(G, varargin)
%

%   Copyright 2021 The MathWorks, Inc.
%#codegen

coder.internal.prefer_const(varargin);
coder.internal.assert(coder.internal.isConst(varargin),'Coder:toolbox:OptionStringsMustBeConstant');
[strong, outputcell] = parseFlags(varargin{:});
coder.internal.assert(~outputcell,'MATLAB:graphfun:conncomp:CodegenCellNotSupported');

if strong
    [bins, nrbins] = connectedComponents(G.Underlying);
    % bins is in reverse topological order, revert again:
    bins = nrbins - bins + 1;
else
    bins = weakConnectedComponents(G.Underlying);
end

if nargout > 1
    binSize = zeros(1,max(bins),coder.internal.indexIntClass);
    for ii = 1:numel(bins)
        currentBin = bins(ii);
        binSize(currentBin) = binSize(currentBin) + 1;
    end
end
end

function [strong, outputcell] = parseFlags(varargin)
    coder.inline('always');
    strong = true;
    outputcell = false;
    
    for ii=1:2:numel(varargin)
        name = varargin{ii};
        coder.internal.assert(matlab.internal.coder.graphBase.isvalidoption(name), ...
            'MATLAB:graphfun:conncomp:ParseFlagsDir');
        nameIsType = matlab.internal.coder.graphBase.partialMatch(name, "Type");
        coder.internal.assert(nameIsType || ...
            matlab.internal.coder.graphBase.partialMatch(name, "OutputForm"), ...
            'MATLAB:graphfun:conncomp:ParseFlagsDir');
                
        if nameIsType
            coder.internal.assert(ii+1 <= numel(varargin), ...
                'MATLAB:graphfun:conncomp:KeyWithoutValue', 'Type');
            value = varargin{ii+1};
            coder.internal.assert(matlab.internal.coder.graphBase.isvalidoption(value), ...
                'MATLAB:graphfun:conncomp:ParseTypeDir');
            strong = matlab.internal.coder.graphBase.partialMatch(value, "strong");
            coder.internal.assert(strong || ...
                matlab.internal.coder.graphBase.partialMatch(value, "weak"), ...
                'MATLAB:graphfun:conncomp:ParseTypeDir');
        else
            coder.internal.assert(ii+1 <= numel(varargin), ...
                'MATLAB:graphfun:conncomp:KeyWithoutValue', 'OutputForm');
            value = varargin{ii+1};
            coder.internal.assert(matlab.internal.coder.graphBase.isvalidoption(value), ...
                'MATLAB:graphfun:conncomp:ParseOutput');
            outputcell = matlab.internal.coder.graphBase.partialMatch(value, "cell");
            coder.internal.assert(outputcell || ...
                matlab.internal.coder.graphBase.partialMatch(value, "vector"), ...
                'MATLAB:graphfun:conncomp:ParseOutput');
        end
    end
end