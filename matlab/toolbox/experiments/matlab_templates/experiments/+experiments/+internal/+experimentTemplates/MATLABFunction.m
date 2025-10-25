classdef MATLABFunction < experiments.internal.AbstractExperiment
%

%   Copyright 2023 The MathWorks, Inc.

    properties (SetAccess=private)
        SourceTemplate = fullfile(fileparts(mfilename('fullpath')), 'templates',  'template_blankMATLABFunction.m');
        HyperTable = {};
        ExperimentType = 'ParamSweep';
        Description = '';
        TrainingType = 'MATLABFunction';
    end

end
