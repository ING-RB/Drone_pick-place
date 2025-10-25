function launchHWSetupForWorkflows(workflowNames)
% LAUNCHHWSETUPFORWORKFLOW(WORKFLOW) launches the HW Setup workflow for the
% support package whose Workflow class is WORKFLOWNAME

% Copyright 2016 MathWorks Inc.

if ~iscellstr(workflowNames)
    error(message('hwconnectinstaller:matlabshared:ExpectedInputAsCellStr'))
end

% The API can launch a single Workflow, launch the first one.
workflowToLaunch = workflowNames{1};
% Create workflow object
assert(isequal(exist(workflowToLaunch, 'class'),8), [workflowToLaunch  ' not found']);
workflowObj = eval(workflowToLaunch);
% Instantiate the first screen
try
    screenObj = feval(workflowObj.FirstScreenID, workflowObj);
catch ex
    error('Unable to create screen object');
end
assert(ismethod(screenObj, 'show'), 'HW Setup screen must have a method "show"');
screenObj.show();

