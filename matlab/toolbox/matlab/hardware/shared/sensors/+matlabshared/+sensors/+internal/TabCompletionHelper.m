classdef TabCompletionHelper < handle
    % helper class for dynamic input arguments' values for
    % resources/functionSignatures.json of sensor
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    methods (Static)
        function buses = getAvailableI2CBusIDs(hardwareObj)
            %getAvailableI2CBusIDs Gets the I2C Buses supported by the
            %hardware
            % functionSignatures.json file requires cell as input
            buses = {};
            if isa(hardwareObj,'matlabshared.i2c.controller')
                % hwsdk based targets has a property AvailableI2CBusIDs
                % which gives the Bus IDs
                buses = num2cell(hardwareObj.AvailableI2CBusIDs);
            elseif isa(hardwareObj,'matlabshared.sensors.I2CSensorUtilities')
                % getAvailableI2CBusIDs is a abstract method target author
                % has to implement
                temp = getAvailableI2CBusIDs(hardwareObj);
                if iscell(temp)
                    buses = temp;
                else
                    buses = num2cell(temp);
                end
            end
        end
        
        function serialPorts = getAvailableSerialPorts(hardwareObj)
            %getAvailableI2CBusIDs Gets the I2C Buses supported by the
            %hardware
            % functionSignatures.json file requires cell as input
            serialPorts = {};
            if isa(hardwareObj,'matlabshared.serial.controller')
                % hwsdk based targets has a property AvailableI2CBusIDs
                % which gives the Bus IDs
                serialPorts = num2cell(hardwareObj.AvailableSerialPortIDs);
            end
        end

        function spibuses = getAvailableSPIBusIDs(hardwareObj)
            spibuses = hardwareObj.AvailableSPIBusIDs - 1;
        end

        function taps = getBartlettFilterTaps()
            taps = {1,2,4,8,16,32};
        end
    end
end
