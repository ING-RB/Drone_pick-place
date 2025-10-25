classdef encodedLoaderType < coder.internal.loaderType
    %#codegen

%   Copyright 2020 The MathWorks, Inc.

    properties(SetAccess = immutable)
        baseClass
    end
    methods
        function this = encodedLoaderType(s,c,e, vDims)
            this@coder.internal.loaderType(s,c, false, vDims);
            this.baseClass = e;    
        end
    end
    
end
