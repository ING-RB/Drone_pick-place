function varargout = ros2configrmw
%% Launch ROS Middleware Configuration Setup Screens
%

% Copyright 2022 The MathWorks, Inc.
workflow = findobjinternal(0,'Type','Figure','Name', ...
    getString(message('ros:mlros2:rmwsetup:MainWindowTitle')));
if isempty(workflow)
    workflow = ros.internal.rmwsetup.register.ROSMiddlewareConfigurationWorkflow();
    workflow.launch;
else
    focus(workflow);
end

if nargout > 0
    varargout{1} = workflow;
end
end
