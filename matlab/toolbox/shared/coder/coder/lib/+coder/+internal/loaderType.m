classdef loaderType
    %#codegen

%   Copyright 2020 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
        size;
        classname;
        isComplex;
        varDims;
    end
    methods
        function out = loaderType(s,cn, cmplx, varDims)
            out.size = s;
            out.classname = cn;
            out.isComplex = cmplx;
            out.varDims = varDims;
        end
    end
end
