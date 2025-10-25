classdef resultPolygonWrapper < handle
%MATLAB Code Generation Private Class

%   Copyright 2022 The MathWorks, Inc.

    %#codegen
    
    properties
        resultPolygonPtr
        clipperPolyPtr
    end

    methods

        function obj = resultPolygonWrapper()
            obj.resultPolygonPtr = coder.opaquePtr('void', coder.internal.null);
            obj.clipperPolyPtr = coder.opaquePtr('void', coder.internal.null);
            coder.internal.clipperAPI.createResultPoly(obj);
        end

        function delete(obj)
            coder.internal.clipperAPI.deleteResultPoly(obj);
        end
    end

end
