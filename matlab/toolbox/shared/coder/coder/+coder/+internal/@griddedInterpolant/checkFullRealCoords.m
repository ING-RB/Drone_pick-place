function checkFullRealCoords(A)
    % sparsity and type testing
    
    %   Copyright 2022 The MathWorks, Inc.

    %#codegen

    coder.internal.assert(isa(A,'double') || isa(A,'single'), 'MATLAB:griddedInterpolant:NonFloatInpPtsErrId');
    coder.internal.assert(~issparse(A), 'MATLAB:griddedInterpolant:SparseDataPtErrId');
    coder.internal.assert(isreal(A), 'MATLAB:griddedInterpolant:ComplexDataPointErrId');
    
end
