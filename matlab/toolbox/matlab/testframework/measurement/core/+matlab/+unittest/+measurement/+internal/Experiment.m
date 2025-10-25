classdef (Hidden, Abstract) Experiment < handle
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties (Hidden, SetAccess = immutable, GetAccess = protected)
        TestRunner;
        Operator;
    end
    
    properties (Hidden, SetAccess = immutable, GetAccess = protected)
        MeasurementPlugin;
    end
    
    methods (Access = protected)
        function experiment = Experiment(runner, operator, plugin)
            experiment.TestRunner =  runner;
            experiment.Operator = operator;
            experiment.MeasurementPlugin = plugin;
        end
    end
    
    methods(Abstract)
        result = run(experiment, suite, varargin) 
    end
end