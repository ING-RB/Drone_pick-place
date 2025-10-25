classdef SPI < handle
    
    % SPI is the codegen redirector class for
    % matlabshared.ioclient.peripherals.spi. During code generation this
    % class replaces the IO class automatically.
    
    % Copyright 2019 The MathWorks, Inc.
    
    %#codegen
    
    % This APIs are assuming that the hardware is in SPI Master mode always
    properties(Access = protected)
        MW_SPI_HANDLE
    end
    
    methods(Access = public)
        
        function obj = SPI()
            coder.allowpcode('plain');
        end
        function openSPI(obj, SPIModule, MOSIPin, MISOPin, SCLK, SSPin, isActiveLowSSPin)
            coder.cinclude('MW_SPI.h');
            obj.MW_SPI_HANDLE = coder.opaque('MW_Handle_Type','HeaderFile','MW_SVD.h');
            % SPI ID
            if isnumeric(SPIModule)
                SPINameLoc = SPIModule;
            else
                SPINameLoc = coder.opaque('uint32_T', SPIModule);
            end
            % Slave select pin
            if isnumeric(SSPin)
                SSPinNameLoc = SSPin;
            else
                SSPinNameLoc = coder.opaque('uint32_T', SSPin);
            end
            
            % MOSI
            
            if isempty(MOSIPin)
                MOSIPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
            else
                if isnumeric(MOSIPin)
                    MOSIPinLoc = uint32(MOSIPin);
                else
                    MOSIPinLoc = coder.opaque('uint32_T', MOSIPin);
                end
            end
            
            % MISO
            
            if isempty(MISOPin)
                MISOPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
            else
                if isnumeric(MISOPin)
                    MISOPinLoc = uint32(MISOPin);
                else
                    MISOPinLoc = coder.opaque('uint32_T', MISOPin);
                end
            end
            
            % SCLK
            
            if isempty(SCLK)
                SCLKPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
            else
                if isnumeric(SCLK)
                    SCLKPinLoc = uint32(SCLK);
                else
                    SCLKPinLoc = coder.opaque('uint32_T', SCLK);
                end
            end
            
            obj.MW_SPI_HANDLE = coder.ceval('MW_SPI_Open',SPINameLoc,...
                MOSIPinLoc,MISOPinLoc,SCLKPinLoc,...
                SSPinNameLoc, isActiveLowSSPin, SVDTypes.MW_Master);
        end
        
        function writeStatus = setFormatSPI(obj, targetBitsPerFrame, ClockModeValue, MsbFirstTransferLoc)
            coder.cinclude('MW_SPI.h');
            writeStatus = coder.nullcopy(uint8(0));
            writeStatus = coder.ceval('MW_SPI_SetFormat', obj.MW_SPI_HANDLE, targetBitsPerFrame, ClockModeValue, MsbFirstTransferLoc);
        end
        
        function writeStatus = setBusSpeedSPI(obj, busspeed)
            coder.cinclude('MW_SPI.h');
            writeStatus = coder.nullcopy(uint8(0));
            writeStatus = coder.ceval('MW_SPI_SetBusSpeed', obj.MW_SPI_HANDLE, busspeed);
        end
        
        function [rdDataRaw, writeStatus] = writeReadSPI(obj, wrDataRaw, rdDataRaw)
            coder.cinclude('MW_SPI.h');
            writeStatus = coder.ceval('MW_SPI_MasterWriteRead_8bits', obj.MW_SPI_HANDLE, ...
                coder.rref(wrDataRaw), coder.wref(rdDataRaw), ...
                uint32(numel(wrDataRaw)));
        end
        
        function status = getStatusSPI(obj)
            status = coder.nullcopy(uint8(0));
            coder.cinclude('MW_SPI.h');
            status = coder.ceval('MW_SPI_GetStatus', obj.MW_SPI_HANDLE);
        end
        
        function closeSPI(obj, MOSIPin, MISOPin, SCLK, SSPin)
            % Slave select pin
            if isnumeric(SSPin)
                SSPinNameLoc = SSPin;
            else
                SSPinNameLoc = coder.opaque('uint32_T', SSPin);
            end
            
            % MOSI
            
            if isempty(MOSIPin)
                MOSIPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
            else
                if isnumeric(MOSIPin)
                    MOSIPinLoc = uint32(MOSIPin);
                else
                    MOSIPinLoc = coder.opaque('uint32_T', MOSIPin);
                end
            end
            
            % MISO
            
            if isempty(MISOPin)
                MISOPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
            else
                if isnumeric(MISOPin)
                    MISOPinLoc = uint32(MISOPin);
                else
                    MISOPinLoc = coder.opaque('uint32_T', MISOPin);
                end
            end
            
            % SCLK
            
            if isempty(SCLK)
                SCLKPinLoc = coder.opaque('uint32_T', 'MW_UNDEFINED_VALUE');
            else
                if isnumeric(SCLK)
                    SCLKPinLoc = uint32(SCLK);
                else
                    SCLKPinLoc = coder.opaque('uint32_T', SCLK);
                end
            end
            coder.ceval('MW_SPI_Close', obj.MW_SPI_HANDLE, MOSIPinLoc, MISOPinLoc, SCLKPinLoc, SSPinNameLoc);
        end
        
        function status = setSlaveSelectSPI(obj, SSPin, activeLowSSPinEnum)
            coder.cinclude('MW_SPI.h');
            
            % Slave select pin
            if isnumeric(SSPin)
                PinNameLoc = uint8(SSPin);
            else
                PinNameLoc = coder.opaque('uint32_T', SSPin);
            end
            % Call the function to configure
            status = coder.ceval('MW_SPI_SetSlaveSelect', obj.MW_SPI_HANDLE, PinNameLoc, activeLowSSPinEnum);
        end
    end
end