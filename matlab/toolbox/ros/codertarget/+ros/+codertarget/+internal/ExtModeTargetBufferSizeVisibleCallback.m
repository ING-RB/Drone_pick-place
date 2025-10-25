function visibility = ExtModeTargetBufferSizeVisibleCallback(hObj)
% ExtModeTargetBufferSizeVisibleCallback - control visibility
% of the target buffer size configset options

%   Copyright 2024 The MathWorks, Inc.
visibility=false;
if(isfield(hObj.CoderTargetData, 'ExtMode'))
    hCS = hObj.getConfigSet();
    extModeInterface = codertarget.data.getParameterValue(hObj,'ExtMode.Configuration');
    if strcmp(extModeInterface,'XCP on TCP/IP')
        visibility=true;
        autoAllocSize = 'off';
    else
        visibility=false;
        autoAllocSize = 'on';
    end
    set_param(hCS, 'ExtModeAutomaticAllocSize', autoAllocSize);
end