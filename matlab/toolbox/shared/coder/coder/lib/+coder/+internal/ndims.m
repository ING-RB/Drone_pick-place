function numDimensions = ndims(x)
    %MATLAB Code Generation Private Function

    %Copyright 2022 The MathWorks, Inc.
    %#codegen
    coder.internal.allowHalfInputs;
    coder.internal.allowEnumInputs;
    if ~coder.target('MATLAB')
        eml_transient;
    end
    coder.internal.assert(nargin > 0, 'MATLAB:minrhs');
    
    numDimensions = length(size(x));
    coder.internal.assert(coder.internal.isConst(numDimensions), 'Coder:toolbox:NDIMSSizeConstantLength', class(x));

end