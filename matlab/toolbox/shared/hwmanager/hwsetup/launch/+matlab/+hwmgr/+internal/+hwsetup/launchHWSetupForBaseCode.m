function launchHWSetupForBaseCode(basecode)
% LAUNCHHWSETUPFORBASECODE(BASECODE) launches the HW Setup workflow for the
% specified base code. The function returns aftre launch the HW Setup App.

% Copyright 2016 MathWorks Inc.


validateattributes(basecode, {'char'}, {'nonempty'},...
    'launchHWSetupForBaseCode', 'basecode');

workflowNames = matlab.hwmgr.internal.hwsetup.util.getWorkflowNameForBaseCode(basecode);
if isempty(workflowNames)
    error(message('hwsetup:workflow:WorkflowNotFoundForBaseCode', basecode));
end
matlab.hwmgr.internal.hwsetup.util.launchHWSetupForWorkflows(workflowNames);

end