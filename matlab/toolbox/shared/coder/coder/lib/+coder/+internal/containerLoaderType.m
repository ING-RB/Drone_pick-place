classdef containerLoaderType < coder.internal.loaderType
    %#codegen

%   Copyright 2020-2022 The MathWorks, Inc.

    properties(SetAccess = immutable)
        subTypes
        actual
        homogeneous
    end
    methods
        function this = containerLoaderType(s,subs, actual, homogeneous, vDims, classname)
            this@coder.internal.loaderType(s,classname, false, vDims);
            this.subTypes = subs;    
            this.actual = actual;
            this.homogeneous = homogeneous;
        end
    end
    
end
