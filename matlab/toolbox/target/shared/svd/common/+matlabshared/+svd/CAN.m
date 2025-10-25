classdef (StrictDefaults)CAN < matlab.System
    % Interfaces to access CAN bus
    %
    % Type <a href="matlab:methods('matlabshared.svd.CAN')">methods('matlabshared.svd.CAN')</a> for a list of methods of the CAN object.
    %
    % Type <a href="matlab:properties('matlabshared.svd.CAN')">properties('matlabshared.svd.CAN')</a> for a list of properties of the CAN object.
    
    %#codegen
    %#ok<*EMCA>
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties (Hidden)
        Hw = [];
    end
    
    properties (Abstract,Nontunable)
        %CANModule CAN Module
        CANModule;
    end
    
    % Public, nontunable properties.
    properties (Nontunable)
        MsgId = 100;
        MsgLen = 8;
        Identifier = 'Standard (11-bit identifier)';
        DataFormat = 'Raw Data';
    
        RemoteFrame (1, 1) logical = false;
    end
    
    % CAN Drop-down list
    properties (Constant, Hidden)
        IdentifierSet = matlab.system.StringSet({'Standard (11-bit identifier)','Extended (29-bit identifier)'});
        DataFormatSet = matlab.system.StringSet({'Raw Data', 'CAN Msg'});
    end
    
    properties (Access = protected)
        MW_CAN_HANDLE;
    end
    
    %% Constructor, Get/Set functions
    methods
        % Constructor
        function obj = CAN(varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});
        end
        
        function set.MsgLen(obj,value)
            validateattributes(value,...
                {'numeric'},...
                {'real','nonnegative','integer','scalar','<=',8},...
                '', ...
                'Length (bytes)');
            obj.MsgLen = value;
        end
        
        function set.MsgId(obj,value)
            if obj.Identifier == "Standard (11-bit identifier)"
                msgIdLimit = hex2dec('7ff');
            else
                msgIdLimit = hex2dec('1fffffff');
            end
            validateattributes(value,...
                {'numeric'},...
                {'real','nonnegative','integer','scalar','<=',msgIdLimit},...
                '', ...
                'Message ID');
            obj.MsgId = value;
        end
    end
    
    %% CAN formal functions
    methods
        % Initialize the CAN device
        function open(obj)
            if coder.target('Rtw')
                coder.cinclude('MW_CAN.h');
                obj.MW_CAN_HANDLE = coder.opaque('MW_Handle_Type','HeaderFile','MW_SVD.h');
                obj.MW_CAN_HANDLE = coder.ceval('MW_CAN_Open', uint32(obj.CANModule));
            end
        end
        
        % Transmit the data over CAN
        function varargout = write(obj, TxData, Id, DataLength, Type, Format)
            Status = coder.nullcopy(uint8(0));
            In = cast(TxData,'uint8');
            if coder.target('Rtw')
                coder.cinclude('MW_CAN.h');
                Status = coder.ceval('MW_CAN_TransmitMessage',obj.MW_CAN_HANDLE,uint32(Id),coder.rref(In),uint8(DataLength), uint8(Type), uint8(Format));
                varargout{1} = Status;
            end
        end
        
        % Receive the data over CAN
        function receivedFrame = read(obj)
            Status = uint8(0);
            id = uint32(0);
            len = uint8(0);
            type = uint8(0);
            fmt = uint8(0);
            if coder.target('Rtw')
                coder.cinclude('MW_CAN.h');
                if obj.DataFormat == "Raw Data"
                    if obj.Identifier == "Extended (29-bit identifier)"
                        fmt = uint8(1);
                    end
                    RxData = uint8(zeros(obj.MsgLen,1));
                    id = uint32(obj.MsgId);
                    len = uint8(obj.MsgLen);
                    Status =coder.ceval('MW_CAN_ReceiveMessages_By_ID', obj.MW_CAN_HANDLE, uint32(id), coder.wref(RxData), len, coder.wref(type), fmt);
                else
                    RxData = uint8(zeros(8,1));
                    Status =coder.ceval('MW_CAN_ReceiveMessages',obj.MW_CAN_HANDLE, coder.wref(id), coder.wref(RxData), coder.wref(len), coder.wref(type), coder.wref(fmt));
                end
                receivedFrame.id = id;
                receivedFrame.data = RxData';
                receivedFrame.dataLength = len;
                receivedFrame.extended = fmt;
                receivedFrame.rtr = type;
                receivedFrame.status = Status;
            end
        end
        
        % Release the CAN module
        function close(obj)
            if coder.target('Rtw')
                coder.cinclude('MW_CAN.h');
                coder.ceval('MW_CAN_Close',obj.MW_CAN_HANDLE);
            else
                % Place simulation setup code here
            end
        end
        
    end
    
    % System object methods
    methods (Access = protected)
        function varargout = stepImpl(~,varargin)
            varargout{1} = 0;
        end
        
        function flag = isInactivePropertyImpl(obj,prop)
            switch prop
                case {'MsgId', 'MsgLen', 'Identifier', 'RemoteFrame'}
                    if obj.DataFormat == "Raw Data"
                        flag = false;
                    else
                        flag = true;
                    end
                otherwise
                    flag = false;
            end
        end
    end
    
    methods (Static, Access=protected)
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
    end
    
    methods(Static, Access=protected)
        function [groups, PropertyList] = getPropertyGroupsImpl
            DataFormatProp = matlab.system.display.internal.Property('DataFormat', 'Description', 'svd:svd:CANDataFormatPrompt');
            CANModuleProp = matlab.system.display.internal.Property('CANModule', 'Description', 'svd:svd:CANModulePrompt');
            CANIdProp  = matlab.system.display.internal.Property('Identifier', 'Description', 'svd:svd:CANIdentifierPrompt');
            CANMsgIDProp  = matlab.system.display.internal.Property('MsgId', 'Description', 'svd:svd:CANMsgIdPrompt');
            CANMsgLenProp  = matlab.system.display.internal.Property('MsgLen', 'Description', 'svd:svd:CANMsgLenPrompt');
            
            PropertyListOut = {CANModuleProp, DataFormatProp, CANIdProp, CANMsgIDProp, CANMsgLenProp};
            
            Group = matlab.system.display.Section(...
                'PropertyList',PropertyListOut);
            
            groups = Group;
            
            if nargout > 1
                PropertyList = PropertyListOut;
            end
        end
    end
end