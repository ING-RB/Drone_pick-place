function returnValue = isROSTimeModelSteppingEnabled(hObj)
%This function is for internal use only. It may be removed in the future.

% isROSTimeSteppingEnabled Returns the status of "Enable ROS Time model
% stepping" check box

% Copyright 2019-2022 The MathWorks, Inc.

cs = hObj.getConfigSet;
paramName = 'ROS.ROSTimeStepping';
ctdata = codertarget.data.getData(cs);
if isempty(ctdata) || ~codertarget.data.isValidParameter(cs,paramName)
    % Target Hardware Resources not set or older saved model whose
    % configuration set has not updated with new settings
    returnValue = false;
else
    returnValue = codertarget.data.getParameterValue(cs, 'ROS.ROSTimeStepping');
end
end
