classdef I2C < handle
    %Codegen redirector class for I2C device driver
    
    % Copyright 2019-2021 The MathWorks, Inc.
    
    %#codegen
    properties (Access = protected)
        MW_I2C_HANDLE;
    end
    
    methods(Access = public)
        function obj = I2C(varargin)
            coder.allowpcode('plain');
            obj.MW_I2C_HANDLE = coder.opaque('MW_Handle_Type','NULL','HeaderFile','MW_SVD.h');
        end
        
        % Initialize the I2C device
        function openI2CBus(obj, i2cModule, mode)
            % Init I2C device
            if(nargin<3)
                % Default mode is master as currently HWSDK does not
                % support slave mode
                mode = SVDTypes.MW_Master;
            end
            coder.cinclude('MW_I2C.h');
            obj.MW_I2C_HANDLE = coder.opaque('MW_Handle_Type','HeaderFile','MW_SVD.h');
            modename = coder.const(@matlabshared.devicedrivers.coder.I2C.getI2CModeType,mode);
            modename = coder.opaque('MW_I2C_Mode_Type',modename);
            if isnumeric(i2cModule)
                obj.MW_I2C_HANDLE = coder.ceval('MW_I2C_Open', i2cModule, modename);
            else
                i2cname = coder.opaque('uint32_T', i2cModule);
                obj.MW_I2C_HANDLE = coder.ceval('MW_I2C_Open', i2cname, modename);
            end
        end
        
        % Read the data from I2C device
        function [output_raw, status] = rawI2CRead(obj, slaveAddress, nBytes, repeatedStart, NoAck)
            
            % TODO: Get the handle from I2C Module first
            
            if(nargin < 5)
                % Default values of NoAck and RepeatedStart
                NoAck = false;
                repeatedStart = false;
            end
            % TODO: Get the handle from I2C Module first
            % Allocate output
            output_raw = coder.nullcopy(uint8(zeros(nBytes, 1)));
            
            status = coder.nullcopy(uint8(0));
            coder.cinclude('MW_I2C.h');
            
            status = coder.ceval('MW_I2C_MasterRead', obj.MW_I2C_HANDLE, ...
                slaveAddress, ...
                coder.wref(output_raw), ...
                uint32(nBytes), ...
                repeatedStart,NoAck);
            
        end
        % Read a register from I2C device using raw read functions
        function [output, status] = registerI2CRead(obj, slaveAddress, registerAddress, nBytes)
            
            output = uint8(zeros(nBytes,1));
            status=uint8(0);
            % Write address to Slave device
            status = rawI2CWrite(obj, slaveAddress, registerAddress, true, false);
            if (~status)
                % Read data from the slave device
                [output, status] = rawI2CRead(obj, slaveAddress, nBytes, false, true);
            end
        end
        
        % Transmit or write to I2C device
        function status = rawI2CWrite(obj, slaveAddress, data, RepeatedStart, NoAck)
            
            % TODO: Get the handle from I2C Module first
            
            if nargin < 5
                NoAck = false;
                RepeatedStart = false;
            end
            
            dataLength = numel(data);
            status = coder.nullcopy(uint8(0));
            
            % Write to I2C device
            coder.cinclude('MW_I2C.h');
            
            status = coder.ceval('MW_I2C_MasterWrite', obj.MW_I2C_HANDLE, ...
                slaveAddress, ...
                coder.rref(data), ...
                uint32(dataLength), ...
                RepeatedStart, NoAck);
            
        end
        
        % Transmit or write to I2C device using raw write
        function status = registerI2CWrite(obj, slaveAddress, registerAddress, data)
            % Is this needed?
            addr_size = size(registerAddress);
            data_size = size(data);
            
            if (addr_size(1) == data_size(1)) && (addr_size(1) == 1)
                data = [registerAddress, data];
            else
                data = [registerAddress'; data];
            end
            status = uint8(0); %#ok<NASGU>
            status = rawI2CWrite(obj, slaveAddress, data,...
                false, false);
        end
        
        % Release the I2C module
        function closeI2CBus(obj)
            %             if ~isempty(obj.MW_I2C_HANDLE)
            coder.cinclude('MW_I2C.h');
            coder.ceval('MW_I2C_Close', obj.MW_I2C_HANDLE);
            %             end
        end
        
        function status = setI2CFrequency(obj, busSpeed)
            
            status = coder.nullcopy(uint8(0));
            % take care of mode in the caller function. Slave should not
            % call this.
            
            coder.cinclude('MW_I2C.h');
            % Init Bus speed
            status = coder.ceval('MW_I2C_SetBusSpeed', obj.MW_I2C_HANDLE, busSpeed);
            
        end
        
        % Get the status of I2C
        function status = getStatus(obj)
            status = coder.nullcopy(uint8(0));
            % Init PWM
            coder.cinclude('MW_I2C.h');
            status = coder.ceval('MW_I2C_GetStatus', obj.MW_I2C_HANDLE);
        end
        
    end

    methods(Static, Hidden)
        function ret = getI2CModeType(mode)
            coder.inline('always');
            switch mode
                case 0
                    ret = 'MW_I2C_MASTER';
                case 1
                    ret = 'MW_I2C_Slave';
                otherwise
                    ret = 'MW_I2C_MASTER';
            end
        end
    end
end


