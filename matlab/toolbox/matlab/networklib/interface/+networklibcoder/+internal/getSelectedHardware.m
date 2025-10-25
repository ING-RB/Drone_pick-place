function hardwareName = getSelectedHardware()
    %GETSELECEDHARDWARE - Return the name of the hardware selected in the
    %coder config. If the Config is not set for 'exe' or "lib' and if
    %no hardware selection is made, the function returns an empty string.

    %Copyrights 2019-2024 The MathWorks, Inc.

    hardwareName = '';

    %Get the coder build config cache
    buildConfig = coder.internal.buildConfigCache();
    %Check if Coder.Hardware is available and it is not empty
    if isprop(buildConfig.ConfigData,'Hardware')
        if ~isempty(buildConfig.ConfigData.Hardware)
            hardwareName = buildConfig.ConfigData.Hardware.Name;
        end
    else
        % Get the Hardware name from Simulink Model
        hardwareName = getSelectedHardwareForSimulinkModel(buildConfig);
    end

function hWName = getSelectedHardwareForSimulinkModel(buildConfig)

    hWName = '';
    try
        configData = codertarget.data.getData(buildConfig.ConfigData);
    catch
        return
    end

    % Get the hardware name from Simulink model ConfigData
    if ~isfield(configData,'TargetHardware')
        return;
    end
    hWName = char(configData.TargetHardware);


