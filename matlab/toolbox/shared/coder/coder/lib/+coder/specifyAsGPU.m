function specifyAsGPU(in, className)
    %CODER.SPECIFYASGPU Specify that IN is a GPU input for GPU code generation
    %
    %   CODER.SPECIFYASGPU(IN, CLASSNAME) is primarily used to specify
    %   that IN is a GPU input with an underlying class of CLASSNAME
    %   for code generation.
    %
    %   The CODER.SPECIFYASGPU validator has three distinct behaviors:
    %   - In MATLAB execution, CODER.SPECIFYASGPU throws an error if
    %   IN is a GPU array with an underlying type that does not match
    %   CLASSNAME. Alternatively, if IN is not a GPU array, CODER.SPECIFYASGPU
    %   throws an error if the type of IN does not match CLASSNAME.
    %   - During input-type specification using function argument validation,
    %   CODER.SPECIFYASGPU specifies that IN is a GPU array with an
    %   underlying type of CLASSNAME.
    %   - During code generation, CODER.SPECIFYASGPU throws an error if
    %   the type of IN does not match CLASSNAME.
    %
    %   The CLASSNAME parameter must be a character vector or string scalar.
    %   CLASSNAME must be the name of a class supported for gpuArray.
    %
    %   Example:
    %     function out = multiplyByThree(in)
    %         arguments
    %             in (16,16) {coder.specifyAsGPU(in, 'double')}
    %         end
    %         out = in*3;
    %     end
    %

    %   Copyright 2023 The MathWorks, Inc.

    %#codegen
    arguments
       in
       className {mustBeTextScalar,...
                  mustBeValidGPUClass,...
                  mustBeMember(className, {'single', 'double', 'int8', 'int16', 'int32', 'int64', 'uint8', 'uint16', 'uint32', 'uint64', 'logical'})}
    end

    coder.internal.allowEnumInputs;
    coder.internal.allowHalfInputs;

    isCorrectType = isa(in, className);
    if coder.target('MATLAB')
        if isa(in, 'gpuArray')
            isCorrectType = isUnderlyingType(in, className);
        end
    end
    coder.internal.assert(isCorrectType, 'Coder:FE:FAVGPUIncorrectType', className);
end

function mustBeValidGPUClass(className)
    validClasses = {'single', 'double', 'int8', 'int16', 'int32', 'int64', 'uint8', 'uint16', 'uint32', 'uint64', 'logical'};
    isValidClassName = any(strcmp(className, validClasses));
    coder.internal.assert(isValidClassName, 'Coder:FE:FAVGPUOnUnsupportedClassSimple', coder.const(feval('strjoin', validClasses, ', ')));
end
