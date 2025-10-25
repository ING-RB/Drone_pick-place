function targetname = getTargetHardwareName()
%getTargetHardwareName() is used to get the name of the Target from config
%set

%   Copyright 2020 The MathWorks, Inc.
modelName = bdroot;
hCS = getActiveConfigSet(modelName);
tgtInfo = codertarget.targethardware.getTargetHardware(hCS);
% Check if target is set in config set
if isa(tgtInfo,'codertarget.targethardware.TargetHardwareInfo')
    targetname = tgtInfo.Name;
else
    targetname = '';
end
end