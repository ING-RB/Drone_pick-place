function endianness = getEndianness()
%MATLAB Code Generation Private Function

%   Copyright 2022 The MathWorks, Inc.
%#codegen
if coder.internal.runs_in_matlab
    endianness = 'LittleEndian';
else
    opts = coder.internal.get_eml_option('CodegenBuildContext');
    if isempty(opts)
        endianness = 'LittleEndian';
        return
    end
    endianness = coder.const(feval('coder.internal.getEndiannessFromCtx', opts));
end


end