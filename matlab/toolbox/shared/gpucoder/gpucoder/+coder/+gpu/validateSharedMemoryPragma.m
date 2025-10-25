% inputs should be a of the form
% [ varName, baseX, rangeX, baseY, rangeY]
%#codegen
function flag = validateSharedMemoryPragma(symbol, varargin)
    coder.internal.allowHalfInputs;
    %   Copyright 2016-2024 The MathWorks, Inc.
    if (~coder.target('MATLAB'))
        coder.allowpcode('plain');
        flag = false; %#ok<NASGU>
        minNumDim = 1;
        maxNumDim = 2;
        numDim = nargin - 1;
        coder.internal.assert(numDim <= maxNumDim, 'gpucoder:common:SharedMemPragmaInvalidNumArgs');
        coder.internal.assert(numDim >= minNumDim, 'gpucoder:common:SharedMemPragmaInvalidNumArgs');

        symbolDim = size(symbol);
        num_non_singleton_dims = sum(symbolDim > 1);
        coder.internal.assert((numDim <= numel(symbolDim)) && ...
                              (numDim >= num_non_singleton_dims),...
                              'gpucoder:common:SharedMemPragmaDimMismatch');
        for k = 1:nargin-1
            checkDim(k, varargin{k});
        end
        flag = true;
    end
end

function checkDim(dim, spec)
    coder.allowpcode('plain');
    coder.internal.assert(numel(spec) == 2, 'gpucoder:common:SharedMemPragmaInvalidDimSpec', dim);
end
