function filelocation = getTargetSpecificFileLocationForSensors(targetname)
%getTargetSpecificFileLocationForSensors() is used to get the file location of the
%   target specific files required for sensors. Target author can specify
%   the file location in this file or it can be specified in the
%   parameter.xml of the board

%   Copyright 2020-2022 The MathWorks, Inc.
filelocation = '';
if contains(targetname,'Arduino','IgnoreCase',true)
    %TO DO need to change
    filelocation = 'sensors.arduino';
elseif contains(targetname,'raspberry','IgnoreCase',true)
    filelocation = 'sensors.raspberrypi';
elseif contains(targetname,'TI ','IgnoreCase',true)
    filelocation = 'codertarget.tic2000.sensors.c2000';
else
    % Check if the file location is specified in parameter XML
    modelName = bdroot(gcb);
    hCS = getActiveConfigSet(modelName);
    tgtData = codertarget.data.getData(hCS);
    % Check if the Sensor and FileLocation tag is defined in parameter XML
    if isfield(tgtData,'Sensor') && isfield(tgtData.Sensor,'FileLocation')
        filelocation = tgtData.Sensor.FileLocation;
    end
end


end