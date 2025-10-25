classdef ApplicationWindow < handle
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    properties
        Application
    end
    methods
        function this = ApplicationWindow(hApp)
            this.Application = hApp;
        end
    end
end
