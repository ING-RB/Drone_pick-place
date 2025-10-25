classdef sparseLoaderType < coder.internal.loaderType
    %MATLAB Code Generation Private Class
    %#codegen
    %   Copyright 2021 The MathWorks, Inc.

    properties
        iType;
        jType;
        vType;
    end
    methods
        function this = sparseLoaderType(s,cn, cmplx, varDims)
            this@coder.internal.loaderType(s,cn, cmplx, varDims);
            this.iType = coder.internal.loaderType([prod(s), 1], 'double', false, [1,0]);
            this.jType = coder.internal.loaderType([prod(s), 1], 'double', false, [1,0]);
            if strcmp(cn, 'logical')
                this.vType = coder.internal.encodedLoaderType([prod(s), 1], 'uint8', 'logical', [1,0]);
            else
                this.vType = coder.internal.loaderType([prod(s), 1], cn, cmplx, [1,0]);
            end
        end
    end
end