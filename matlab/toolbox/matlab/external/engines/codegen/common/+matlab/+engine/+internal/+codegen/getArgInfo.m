function [cppArgTypes, matlabArgTypes, argNames] = getArgInfo(functionName)
%getArgInfo takes a function's name and returns info on its arguments.
%   Examines the input args of a function or method and returns how the
%   types should be represented in C++. The matlab classes and names are
%   also returned.

%   Copyright 2020-2023 The MathWorks, Inc.

    import matlab.engine.internal.codegen.*

    argMetadata = builtin("_get_function_metadata",char(functionName));
    argNames = [];
    cppArgTypes = [];
    matlabArgTypes = [];
    
    for arg = argMetadata
        argNames = [argNames, string(arg.name)];
        argType = arg.class;
        matlabArgTypes = [matlabArgTypes string(argType)];
        dimensions = arg.dimensions;
        
        lengthdims = length(dimensions);
        dims = zeros(1, lengthdims);
        for j=1:lengthdims
            dims(j) = dimensions{j};
        end
        
        arrtype = classifyArraySize(dims);
        
        % Search for relevant validators
        isReal = 0;
        for i = 1 : numel(arg.validators)
            validator = string(char(arg.validators{i}));
            if validator.matches("mustBeReal")
                isReal = 1;
            end
        end
        
        tc = matlab.engine.internal.codegen.cpp.CPPTypeConverter;
        
        cppType = tc.convertType2CPP(argType, arrtype, isReal);
        cppArgTypes = [cppArgTypes cppType];
        
    end
    
end

