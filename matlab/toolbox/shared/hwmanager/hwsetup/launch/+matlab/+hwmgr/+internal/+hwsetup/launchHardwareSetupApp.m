function launchHardwareSetupApp(workflow, basecode)
% LAUNCHHARDWARESETUPAPP(WORKFLOW, BASECODE) launches the Hardware Setup 
%   defined by WORKFLOW for the product specified by BASECODE

% Copyright 2017 The MathWorks, Inc.

% Validate inputs
validateattributes(workflow, {'char', 'string'},{'nonempty'});
validateattributes(basecode, {'char', 'string'},{'nonempty'});
% Check if workflow class exists
if ~exist(workflow, 'class')
    error(message('hwsetup:workflow:WorkflowDoesNotExist', workflow));
end
% Instantiate the workflow object
try
    wObj = feval(workflow, 'basecode', basecode);
catch ex
    assert(false, message('hwsetup:workflow:WorkflowConstructionError', workflow, ex.message));
end
% Launch the Hardware Setup workflow
try
    wObj.launch()
catch ex
    error(message('hwsetup:workflow:ErrorAppLaunch', [ex.message]))
end
   

end