function pOutputs = maskInitializationFcnPFOutputs(ProcessedMaskData)
% Mask initialization code for the Outputs  block underneath the particle
% filter block.
%
% Collect the relevant and necessary data from parent PF block's large data
% structure (ProcessedMaskData)

%   Copyright 2017 The MathWorks, Inc.

pOutputs = struct(...
    'IsStateOrientationColumn', ProcessedMaskData.IsStateOrientationColumn,...
    'IsStateVariableCircular', ProcessedMaskData.IsStateVariableCircular,...
    'StateEstimationMethod', ProcessedMaskData.StateEstimationMethod,...
    'OutputStateCovariance', ProcessedMaskData.OutputStateCovariance);
end