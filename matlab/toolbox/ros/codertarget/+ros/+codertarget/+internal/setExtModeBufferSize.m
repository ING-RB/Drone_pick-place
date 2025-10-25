function setExtModeBufferSize(hObj, hDlg, tag, ~)
%setExtModeBufferSize - Validate the logging buffer size values entered by the user

%Copyrights 2024 The MathWorks, Inc.
    hCS = hObj.getConfigSet();

    % Save existing 'ExtModeStaticAllocSize'
    oldBufferDepth = get_param(hCS, 'ExtModeStaticAllocSize');
    codertarget.data.setParameterValue(hCS, 'ExtModeInfo.BufferSize', oldBufferDepth);
    t800 = onCleanup(@()cleanup(hCS, oldBufferDepth));
    
    % Get new buffer depth
    validateattributes(hDlg.getWidgetValue(tag),{'char','numeric'},{'nonempty'},'','Logging buffer size');
    newBufferDepth = str2double( hDlg.getWidgetValue(tag));
    validateattributes(newBufferDepth,{'numeric'},{'nonempty','nonnan','scalar','>=',100,'<=',256000000},'','Logging buffer size');
    
    % Set new value to 'ExtModeStaticAllocSize' and 'ExtModeInfo.BufferSize'
    codertarget.data.setParameterValue(hCS, 'ExtModeInfo.BufferSize', newBufferDepth);
    set_param(hCS, 'ExtModeStaticAllocSize', newBufferDepth);

end

% -------------------------------------------------------------------------
% If we somehow end up in a situation where 'ExtModeInfo.BufferSize' and
% 'ExtModeStaticAllocSize' not same, revert.
function cleanup(hCS, existingBufferDepth)
    if( get_param(hCS, 'ExtModeStaticAllocSize') ...
            ~= codertarget.data.getParameterValue(hCS, 'ExtModeInfo.BufferSize'))
        codertarget.data.setParameterValue(hCS, 'ExtModeInfo.BufferSize', existingBufferDepth);
    end
end