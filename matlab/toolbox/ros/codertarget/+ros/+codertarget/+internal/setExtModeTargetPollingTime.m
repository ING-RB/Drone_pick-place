function setExtModeTargetPollingTime(hObj, hDlg, tag, dec)
%setExtModeTargetPollingTime - Validate the polling time values entered by the user

%Copyrights 2024 The MathWorks, Inc.
hCS = hObj.getConfigSet();
val = hDlg.getWidgetValue(tag);
pollingTime = str2double(val);
validateattributes(pollingTime,{'numeric'},{'nonempty','nonnan','scalar','positive','integer'},'','XCP target polling time');
% Set new value to 'ExtModeInfo.TargetPollingTime'
codertarget.data.setParameterValue(hCS, 'ExtModeInfo.TargetPollingTime', val);
widgetChangedCallback(hObj, hDlg, tag, dec);
end