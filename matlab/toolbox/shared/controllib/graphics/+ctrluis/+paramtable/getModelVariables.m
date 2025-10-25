function vars = getModelVariables(mdl)
%GETMODELVARIABLES Return variables used by a model
%
%    Return a list of variables used by a simulink model. Only returns
%    variables in the model workspace, model data dictionray, base
%    workspace or brokered sources (MAT files).
%
%    vars = ctrluis.paramtable.getModelVariables(mdl)
%
%    Inputs:
%      mdl - Simulink model name
%
%    Outputs:
%      vars - structure with used variables. See Simulink.findVars for
%             description of structure
%
%    See also Simulink.findvars
%

% Copyright 2013-2022 The MathWorks, Inc.

%Get list of all model variables
vars = Simulink.findVars(mdl);
%Filter list to only contain model workspace, data dictionary, and base
%workspace variables.
srcType = {vars.SourceType};
idx     = strncmp(srcType,'base',4) | strncmp(srcType,'model',5) | strncmp(srcType,'data', 4) | strncmp(srcType, 'external', 8);
vars    = vars(idx);
end