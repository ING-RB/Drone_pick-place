function initFcnHookBase(blk)
%initFcnHookBase() is used to call target specific initFcn method.
% All the sensor blocks will call this method in initFcn in their
% respective Block Paramters. InitFcn of a block get invoked during
% "Update Diagram". If the target authors are using the sensor block 
% directly, they need to implement a function initFcnHook
% in their sensor specific file location and need to take cares of all
% operations related to Update Diagram in the fucntion. This may include
% resource management, conflict check, DDUX etc.

%   Copyright 2020 The MathWorks, Inc.
targetname = matlabshared.sensors.simulink.internal.getTargetHardwareName;
fileLocation = matlabshared.sensors.simulink.internal.getTargetSpecificFileLocationForSensors(targetname);
maskType = get_param(gcb, "MaskType");
funcName = [fileLocation,'.initFcnHook'];
functionPath = which(funcName);
if ~isempty(functionPath)
    funcHandle = str2func(funcName);
    funcHandle(blk,maskType);
end
end