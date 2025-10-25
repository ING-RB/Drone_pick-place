classdef (Hidden) I2CSensorProperties < handle
    %Base class for I2C Interface

    %   Copyright 2023 The MathWorks, Inc.

    %#codegen

    properties(Abstract, Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList;
    end

    properties(SetAccess=protected)
        Bus;
        I2CAddress;
        Interface = 'I2C';
        BitRate = 100000;
        SDAPin = '';
        SCLPin = '';
    end
end
