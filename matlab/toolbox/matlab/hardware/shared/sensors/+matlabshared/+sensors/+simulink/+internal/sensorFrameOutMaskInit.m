function sensorFrameOutMaskInit(blkH, varargin)
%sensorFrameOutMaskInit is the mask init callback for sensors which give
% out frame output using a subsystem approach

%   Copyright 2022-2023 The MathWorks, Inc.
% Return if simulation is paused or running or during external mode.
if strcmpi(get_param(bdroot, 'SimulationStatus'), 'paused') || ...
        strcmpi(get_param(bdroot, 'SimulationStatus'), 'running') ||...
        strcmpi(get_param(bdroot,"ExtModeConnected"),'on')
    return;
end
blkFullName = getfullname(blkH);
% Check the sample time of the block
st = get_param(blkH,"Sampletime");
st = slResolve(st,blkH); % Fetch the variable from Model Workspace or Base Workspace as applicable.
matlabshared.sensors.simulink.internal.validateSampleTime(st);
if ~strcmpi(get_param(blkH,'spf'),'1') && ismember(st(1),[0,-1,inf])
    error(message('matlab_sensors:general:InvalidSampleTime'));
end
% Get the sensor object handle inside the subsystem
baseSensorBlkh  = find_system(blkH,'SearchDepth',1,'LookUnderMasks','on','FollowLinks','on','Name','Base sensor block');
% Extract output port names from mask
maskStr = get_param(baseSensorBlkh,'MaskDisplay');
startPat = "'output'," + digitsPattern(1) + ",'";
endPat = "')";
selectedOutputs = extractBetween(maskStr,startPat,endPat);
% Connect outports
matlabshared.sensors.simulink.internal.manageOutportSensorBlocksWithFrameOut(blkH, baseSensorBlkh, selectedOutputs);
% update mask display
set_param(blkFullName,'MaskDisplay',maskStr);
% Update queue size factor for efficient streaming when buffer is used
spfStr = get_param(blkH,'spf');
if ischar(spfStr) || isstring(spfStr)
    spfVal = evalin('base',spfStr);
else
    spfVal = spfStr;
end
validateattributes(spfVal, {'numeric'},{'nonempty','scalar','integer','>',0,'<',2^16,'nonnan'},'', 'Samples per frame');
try
    baseBlock = get_param(baseSensorBlkh,'System');
    sysObj = eval(baseBlock);
    if isa(sysObj,'matlabshared.sensors.simulink.internal.SimulinkStreamingUtilities') || isa(sysObj,'matlabshared.devicedrivers.internal.SimulinkStreamingUtilities')
        spfStr = get_param(blkH,'spf');
        set_param(blkH,'QueueSizeFactor',spfStr);
    end
catch
end
end
