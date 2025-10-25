classdef ostringstream < handle
    methods
        function this = ostringstream()
        end
        function this = sprintf(this, varargin)
            this.string = [this.string sprintf(varargin{:})];
        end
    end
    properties
        string
    end
end