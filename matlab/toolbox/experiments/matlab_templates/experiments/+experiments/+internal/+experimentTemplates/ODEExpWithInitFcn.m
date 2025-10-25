classdef ODEExpWithInitFcn < experiments.internal.AbstractExperiment
%

%   Copyright 2024 The MathWorks, Inc.

    properties (SetAccess=private)
        SourceTemplate = fullfile(fileparts(mfilename('fullpath')), 'templates',  'template_odeExperimentFunction.m');
        HyperTable = {{'Alpha', '[1 2 3]', 'real', 'none'}, {'Beta', '[1 2 3 4]', 'real', 'none'}};
        ExperimentType = 'ParamSweep';
        Description = string(message('experiments:manager:SolveODEExpDescription'));
        TrainingType = 'MATLABFunction';
    end
    
    methods
        function obj = ODEExpWithInitFcn()
            obj.SuggestedHyperTable = {{'Alpha', '[1 2 3]', 'real', 'none'}, ...
                                       {'Beta', '[1 2 3 4]', 'real', 'none'}, ...
                                       {'endTime', '[10 15 20]', 'real', 'none'}};
            obj.InitializationFunctionTemplate = fullfile(fileparts(mfilename('fullpath')), 'templates',  'template_odeExpInitializationFunction.m');
        end
    end

end
