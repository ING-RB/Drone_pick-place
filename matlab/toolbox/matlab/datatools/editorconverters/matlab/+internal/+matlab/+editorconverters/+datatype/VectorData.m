classdef VectorData
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2017-2018 The MathWorks, Inc.

    properties(Access = private)
        Vector;
    end
    
    methods
        function this = VectorData(v)
            this.Vector = v;
        end
        
        function v = getVector(this)
            v = this.Vector;
        end
    end
end
