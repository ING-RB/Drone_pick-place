classdef (Abstract) LegacyBase < matlabshared.transportlib.internal.compatibility.ILegacyUnsupported & ...
                                 matlabshared.transportlib.internal.compatibility.ILegacyCommon
    %LEGACYADAPTOR Abstract base class for all specific legacy
    %compatibility interfaces (e.g. LegacySerial, LegacyVisa, etc.).

    % Copyright 2021-2023 The MathWorks, Inc.

    %#codegen

    %% Pass-through properties
    % Pass-through properties support interface compatibility 

    properties (Hidden, SetAccess = private)
        Status = 'open'
    end

    properties (Hidden)
        % By default, OutputBufferSize = 2 * InputBufferSize (to simplify
        % testing).
        InputBufferSize = matlabshared.transportlib.internal.compatibility.LegacyBase.BufferSize
        OutputBufferSize = 2 * matlabshared.transportlib.internal.compatibility.LegacyBase.BufferSize
    end

    properties (Hidden, Dependent)
        % ErrorFcn - refers to ErrorOccurredFcn
        ErrorFcn (1, 1) function_handle
    end

    properties (Hidden, SetAccess = private, Dependent)
        % BytesAvailable - refers to NumBytesAvailable
        BytesAvailable
    end
    
    %% Internal properties

    properties (Hidden)
        NumToRead double {mustBeInteger, mustBePositive}
        Format char
    end

    properties (Constant, Access = private)
        BufferSize = 512
    end

    %% Getters / Setters
    
    methods
        function value = get.BytesAvailable(obj)
            value = obj.NumBytesAvailable;
        end

        function value = get.ErrorFcn(obj)
            value = obj.ErrorOccurredFcn;
        end

        function set.ErrorFcn(obj, value)
            obj.ErrorOccurredFcn = value;
        end        
    end

    %% Common legacy methods
    methods (Sealed, Hidden)
        function fopen(obj)
            % Does not change the state of the connection.
            % Does not warn or error.
            fopenHook(obj);
        end

        function fclose(obj) %#ok<MANU> 
            % Do not change the state of the connection
            % Explicitly indicate that the connection does not change as a
            % result of calling this method.

            sendMessage("transportlib:legacy:DoesNotCloseConnection")
        end

        function flushinput(obj)
            flush(obj, "input");
        end

        function flushoutput(obj)
            flush(obj, "output");
        end
    end

    methods (Access = protected)
        function fopenHook(obj) %#ok<MANU>
            % By default, does nothing
        end
    end

    %% Unsupported methods
    methods (Sealed, Hidden)
        % INSTRHELP
        function instrhelp(obj)
            unsupportedMethod(obj, "instrhelp")
        end

        % READASYNC
        function readasync(obj)
            unsupportedMethod(obj, "readasync")
        end

        % STOPASYNC
        function stopasync(obj)
            unsupportedMethod(obj, "stopasync")
        end

        % PROPINFO
        function propinfo(obj)
            unsupportedMethod(obj, "propinfo")
        end

        % RECORD
        function record(obj)
            unsupportedMethod(obj, "record")
        end

        % INSTRID
        function instrid(obj)
            unsupportedMethod(obj, "instrid")
        end

        % INSTRSUPPORT
        function instrsupport(obj)
            unsupportedMethod(obj, "instrsupport")
        end

        % INSTRCALLBACK
        function instrcallback(obj)
            unsupportedMethod(obj, "instrcallback")
        end

        % INSTRNOTIFY
        function instrnotify(obj)
            unsupportedMethod(obj, "instrnotify")
        end

        % INSTRFIND
        function instrfind(obj)
            unsupportedMethod(obj, "instrfind")
        end

        % INSTRFINDALL
        function instrfindall(obj)
            unsupportedMethod(obj, "instrfindall")
        end
    end

    %% Lifetime
    methods
        %This dummy constructor is needed for codegen support
        function obj = LegacyBase
            coder.allowpcode('plain');
        end
    end

    methods (Access = private)
        function unsupportedMethod(~, methodName) % (obj, methodName)
            % warn that this method is not supported (will eventually error
            % out)
            id = "transportlib:legacy:MethodNotSupported";
            sendMessage(id, methodName)
        end

        function unsupportedProperty(~, propertyName) % (obj, propertyName)
            % warn that this property is not supported (will eventually
            % error out)
            id = "transportlib:legacy:PropertyNotSupported";
            sendMessage(id, propertyName)
        end        
    end

    %% Unsupported Properties

    properties (Hidden, Dependent)
        BreakInterruptFcn
        BusManagementStatus
        BytesToOutput
        CompareBits
        ConfirmationFcn
        DatagramAddress
        DatagramPort        
        DataTerminalReady
        DriverName
        DriverSessions
        DriverType
        HandshakeStatus
        InputDatagramPacketSize
        InterruptFcn
        LocalPortMode
        MappedMemoryBase
        MappedMemorySize
        MemoryBase
        MemoryIncrement
        MemorySize
        MemorySpace
        NetworkRole
        ObjectVisibility
        OutputDatagramPacketSize
        OutputEmptyFcn
        PinStatusFcn
        Profile
        ReadAsyncMode
        RecordDetail
        RecordMode
        RecordName
        RecordStatus
        RequestToSend
        Sessions
        TimerFcn
        TimerPeriod
        TransferStatus
        TriggerFcn
        TriggerLine
        TriggerType
        ValuesReceived
        ValuesSent       
    end

    methods
        function value = get.BreakInterruptFcn(obj)
            value = [];
            unsupportedProperty(obj, "BreakInterruptFcn");
        end

        function set.BreakInterruptFcn(obj, ~)
            unsupportedProperty(obj, "BreakInterruptFcn");
        end

        function value = get.BusManagementStatus(obj)
            value = [];
            unsupportedProperty(obj, "BusManagementStatus");
        end

        function set.BusManagementStatus(obj, ~)
            unsupportedProperty(obj, "BusManagementStatus");
        end

        function value = get.BytesToOutput(obj)
            value = [];
            unsupportedProperty(obj, "BytesToOutput");
        end

        function set.BytesToOutput(obj, ~)
            unsupportedProperty(obj, "BytesToOutput");
        end

        function value = get.CompareBits(obj)
            value = [];
            unsupportedProperty(obj, "CompareBits");
        end

        function set.CompareBits(obj, ~)
            unsupportedProperty(obj, "CompareBits");
        end

        function value = get.ConfirmationFcn(obj)
            value = [];
            unsupportedProperty(obj, "ConfirmationFcn");
        end

        function set.ConfirmationFcn(obj, ~)
            unsupportedProperty(obj, "ConfirmationFcn");
        end

        function value = get.DatagramAddress(obj)
            value = [];
            unsupportedProperty(obj, "DatagramAddress");
        end

        function set.DatagramAddress(obj, ~)
            unsupportedProperty(obj, "DatagramAddress");
        end

        function value = get.DatagramPort(obj)
            value = [];
            unsupportedProperty(obj, "DatagramPort");
        end

        function set.DatagramPort(obj, ~)
            unsupportedProperty(obj, "DatagramPort");
        end

        function value = get.DataTerminalReady(obj)
            value = [];
            unsupportedProperty(obj, "DataTerminalReady");
        end

        function set.DataTerminalReady(obj, ~)
            unsupportedProperty(obj, "DataTerminalReady");
        end

        function value = get.DriverName(obj)
            value = [];
            unsupportedProperty(obj, "DriverName");
        end

        function set.DriverName(obj, ~)
            unsupportedProperty(obj, "DriverName");
        end

        function value = get.DriverSessions(obj)
            value = [];
            unsupportedProperty(obj, "DriverSessions");
        end

        function set.DriverSessions(obj, ~)
            unsupportedProperty(obj, "DriverSessions");
        end

        function value = get.DriverType(obj)
            value = [];
            unsupportedProperty(obj, "DriverType");
        end

        function set.DriverType(obj, ~)
            unsupportedProperty(obj, "DriverType");
        end

        function value = get.HandshakeStatus(obj)
            value = [];
            unsupportedProperty(obj, "HandshakeStatus");
        end

        function set.HandshakeStatus(obj, ~)
            unsupportedProperty(obj, "HandshakeStatus");
        end

        function value = get.InputDatagramPacketSize(obj)
            value = [];
            unsupportedProperty(obj, "InputDatagramPacketSize");
        end

        function set.InputDatagramPacketSize(obj, ~)
            unsupportedProperty(obj, "InputDatagramPacketSize");
        end

        function value = get.InterruptFcn(obj)
            value = [];
            unsupportedProperty(obj, "InterruptFcn");
        end

        function set.InterruptFcn(obj, ~)
            unsupportedProperty(obj, "InterruptFcn");
        end

        function value = get.LocalPortMode(obj)
            value = [];
            unsupportedProperty(obj, "LocalPortMod");
        end

        function set.LocalPortMode(obj, ~)
            unsupportedProperty(obj, "LocalPortMod");
        end

        function value = get.MappedMemoryBase(obj)
            value = [];
            unsupportedProperty(obj, "MappedMemoryBase");
        end

        function set.MappedMemoryBase(obj, ~)
            unsupportedProperty(obj, "MappedMemoryBase");
        end

        function value = get.MappedMemorySize(obj)
            value = [];
            unsupportedProperty(obj, "MappedMemorySize");
        end

        function set.MappedMemorySize(obj, ~)
            unsupportedProperty(obj, "MappedMemorySize");
        end

        function value = get.MemoryBase(obj)
            value = [];
            unsupportedProperty(obj, "MemoryBase");
        end

        function set.MemoryBase(obj, ~)
            unsupportedProperty(obj, "MemoryBase");
        end

        function value = get.MemoryIncrement(obj)
            value = [];
            unsupportedProperty(obj, "MemoryIncrement");
        end

        function set.MemoryIncrement(obj, ~)
            unsupportedProperty(obj, "MemoryIncrement");
        end

        function value = get.MemorySize(obj)
            value = [];
            unsupportedProperty(obj, "MemorySize");
        end

        function set.MemorySize(obj, ~)
            unsupportedProperty(obj, "MemorySize");
        end

        function value = get.MemorySpace(obj)
            value = [];
            unsupportedProperty(obj, "MemorySpace");
        end

        function set.MemorySpace(obj, ~)
            unsupportedProperty(obj, "MemorySpace");
        end

        function value = get.NetworkRole(obj)
            value = [];
            unsupportedProperty(obj, "NetworkRole");
        end

        function set.NetworkRole(obj, ~)
            unsupportedProperty(obj, "NetworkRole");
        end

        function value = get.ObjectVisibility(obj)
            value = [];
            unsupportedProperty(obj, "ObjectVisibility");
        end

        function set.ObjectVisibility(obj, ~)
            unsupportedProperty(obj, "ObjectVisibility");
        end

        function value = get.OutputDatagramPacketSize(obj)
            value = [];
            unsupportedProperty(obj, "OutputDatagramPacketSize");
        end

        function set.OutputDatagramPacketSize(obj, ~)
            unsupportedProperty(obj, "OutputDatagramPacketSize");
        end

        function value = get.OutputEmptyFcn(obj)
            value = [];
            unsupportedProperty(obj, "OutputEmptyFcn");
        end

        function set.OutputEmptyFcn(obj, ~)
            unsupportedProperty(obj, "OutputEmptyFcn");
        end

        function value = get.PinStatusFcn(obj)
            value = [];
            unsupportedProperty(obj, "PinStatusFcn");
        end

        function set.PinStatusFcn(obj, ~)
            unsupportedProperty(obj, "PinStatusFcn");
        end

        function value = get.Profile(obj)
            value = [];
            unsupportedProperty(obj, "Profile");
        end

        function set.Profile(obj, ~)
            unsupportedProperty(obj, "Profile");
        end

        function value = get.ReadAsyncMode(obj)
            value = [];
            unsupportedProperty(obj, "ReadAsyncMode");
        end

        function set.ReadAsyncMode(obj, ~)
            unsupportedProperty(obj, "ReadAsyncMode");
        end

        function value = get.RecordDetail(obj)
            value = [];
            unsupportedProperty(obj, "RecordDetail");
        end

        function set.RecordDetail(obj, ~)
            unsupportedProperty(obj, "RecordDetail");
        end

        function value = get.RecordMode(obj)
            value = [];
            unsupportedProperty(obj, "RecordMode");
        end

        function set.RecordMode(obj, ~)
            unsupportedProperty(obj, "RecordMode");
        end

        function value = get.RecordName(obj)
            value = [];
            unsupportedProperty(obj, "RecordName");
        end

        function set.RecordName(obj, ~)
            unsupportedProperty(obj, "RecordName");
        end

        function value = get.RecordStatus(obj)
            value = [];
            unsupportedProperty(obj, "RecordStatus");
        end

        function set.RecordStatus(obj, ~)
            unsupportedProperty(obj, "RecordStatus");
        end

        function value = get.RequestToSend(obj)
            value = [];
            unsupportedProperty(obj, "RequestToSend");
        end

        function set.RequestToSend(obj, ~)
            unsupportedProperty(obj, "RequestToSend");
        end

        function value = get.Sessions(obj)
            value = [];
            unsupportedProperty(obj, "Sessions");
        end

        function set.Sessions(obj, ~)
            unsupportedProperty(obj, "Sessions");
        end

        function value = get.TimerFcn(obj)
            value = [];
            unsupportedProperty(obj, "TimerFcn");
        end

        function set.TimerFcn(obj, ~)
            unsupportedProperty(obj, "TimerFcn");
        end

        function value = get.TimerPeriod(obj)
            value = [];
            unsupportedProperty(obj, "TimerPeriod");
        end

        function set.TimerPeriod(obj, ~)
            unsupportedProperty(obj, "TimerPeriod");
        end

        function value = get.TransferStatus(obj)
            value = [];
            unsupportedProperty(obj, "TransferStatus");
        end

        function set.TransferStatus(obj, ~)
            unsupportedProperty(obj, "TransferStatus");
        end

        function value = get.TriggerFcn(obj)
            value = [];
            unsupportedProperty(obj, "TriggerFcn");
        end

        function set.TriggerFcn(obj, ~)
            unsupportedProperty(obj, "TriggerFcn");
        end

        function value = get.TriggerLine(obj)
            value = [];
            unsupportedProperty(obj, "TriggerLine");
        end

        function set.TriggerLine(obj, ~)
            unsupportedProperty(obj, "TriggerLine");
        end

        function value = get.TriggerType(obj)
            value = [];
            unsupportedProperty(obj, "TriggerType");
        end

        function set.TriggerType(obj, ~)
            unsupportedProperty(obj, "TriggerType");
        end

        function value = get.ValuesReceived(obj)
            value = [];
            unsupportedProperty(obj, "ValuesReceived");
        end

        function set.ValuesReceived(obj, ~)
            unsupportedProperty(obj, "ValuesReceived");
        end

        function value = get.ValuesSent(obj)
            value = [];
            unsupportedProperty(obj, "ValuesSent");
        end

        function set.ValuesSent(obj, ~)
            unsupportedProperty(obj, "ValuesSent");
        end
    end    
end

function sendMessage(id, varargin)
    matlabshared.transportlib.internal.compatibility.Utility.sendWarning(id, varargin{:});
end
