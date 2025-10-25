% This class is unsupported and might change or be removed without notice
% in a future version.

% Provides a bare-minimum workspace for use by Import -- which just needs to add
% variables to it, and provide a way to get variables out of it.

% Copyright 2019 The MathWorks, Inc.

classdef ImportWorkspace < handle
    properties
        data
    end
    
    methods
        function this = ImportWorkspace()
            this.data = struct;
        end
        
        function assignin(this, name, value)
            this.data.(name) = value;
        end
        
        function d = getData(this)
            d = this.data;
        end
    end
end