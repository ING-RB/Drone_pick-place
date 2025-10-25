classdef (StrictDefaults)CANFDRead < matlabshared.svd.CANFD & ...
        matlabshared.svd.BlockSampleTime
        %CANREADBLOCK Read data From CAN Bus.
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    %#codegen
    
    properties (Hidden, Nontunable)
        Logo = 'Generic'
        Title = 'CAN-FD Read'
    end
    properties (Nontunable)
        % OutputType: packed or unpacked data
        OutputType (1,:) char {matlab.system.mustBeMember(OutputType,{'Packed', 'Unpacked'})} = 'Packed';
        % CANFDMsg: assign to bus output during simulation
        CANFDMsg;
        % CANFDMsgType: Bus Output type 
        CANFDMsgType = 'CAN_FD_MESSAGE_BUS';
        % RxIndex: Receive Index
        RxIndex = 0;
    
        % OutputStatus: status output of block 
        OutputStatus (1, 1) logical = false;

        %SampleTime Sample time
        SampleTime = -1;
    end

    properties(Access = protected)
        PrevOutCellArray = {}; % Cell array to store previous values
    end

    methods
        % Constructor
        function obj = CANFDRead(varargin)
            obj = obj@matlabshared.svd.CANFD(varargin{:});
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});
            obj.CANFDMsg = struct('ProtocolMode',uint8(0),'Extended', uint8(0),...
                'Length', uint8(0), 'Remote', uint8(0), ...
                'Error', uint8(0), 'BRS',uint8(0),'ESI',uint8(0),'DLC',uint8(0),...
                'ID', uint32(0),'Reserved', uint32(0),'Timestamp',0,...
                'Data',uint8(zeros(1, 64)'));
        end

        function set.SampleTime(obj,newTime)
            coder.extrinsic('error');
            coder.extrinsic('message');

            newTime = matlabshared.svd.internal.validateSampleTime(newTime);
            obj.SampleTime = newTime;
        end
    end
    
    methods(Access = protected)
        function setupImpl(obj)
            % This is to initialize the cell array which contains previous
            % outputs if no new output is found
            resetPrevOutCellArray(obj);
            % Initialise CAN Module
            open(obj);
        end

        function resetPrevOutCellArray(obj)
            % Initialize cell array to store previous values with zeros
            outputNum = getNumOutputsImpl(obj);
            if obj.OutputStatus
                outputNum = outputNum - 1;
            end
            obj.PrevOutCellArray = cell(1,outputNum);
            if isequal(obj.OutputType, 'Unpacked')
                obj.PrevOutCellArray{1} = uint32(0);
                obj.PrevOutCellArray{2} = uint8(0);
                obj.PrevOutCellArray{3} = uint8(0);
                obj.PrevOutCellArray{4} = uint8(0);
                obj.PrevOutCellArray{5} = uint8(0);
                obj.PrevOutCellArray{6} = uint8(0);
                obj.PrevOutCellArray{7} = uint8(zeros(1, 64)');
            else
                obj.PrevOutCellArray{1} = obj.CANFDMsg;
            end
        end
        
        function varargout = stepImpl(obj)
            if coder.target('Rtw')
                [rx,status] = read(obj,obj.RxIndex);
                if isequal(obj.OutputType, 'Unpacked')
                    if isequal(status,0)
                        % provide multiple outut ports
                        varargout{1} = uint32(rx.ID);
                        varargout{2} = uint8(rx.Extended);
                        varargout{3} = uint8(rx.ProtocolMode);
                        varargout{4} = uint8(rx.BRS);
                        varargout{5} = uint8(rx.Length);
                        varargout{6} = uint8(rx.Remote);
                        varargout{7} = rx.Data';
                        for index = 1:7
                           obj.PrevOutCellArray{index} = varargout{index};
                        end
                    else
                        for index = 1:7
                           varargout{index} = obj.PrevOutCellArray{index};
                        end
                    end
                    if obj.OutputStatus
                        varargout{8} =uint8(status);
                    end
                else
                    if isequal(status,0)
                        % provide Bus output
                        rcv.ProtocolMode = uint8(rx.ProtocolMode);
                        rcv.Extended = uint8(rx.Extended);
                        rcv.Length = uint8(rx.Length);
                        rcv.Remote = uint8(rx.Remote);
                        rcv.Error = uint8(0);
                        rcv.BRS = uint8(rx.BRS);
                        rcv.ESI = uint8(0);
                        rcv.DLC = uint8(rx.DLC);
                        rcv.ID = uint32(rx.ID);
                        rcv.Reserved = uint32(0);
                        rcv.Timestamp = 0;
                        rcv.Data = rx.Data';
                        varargout{1} = rcv;
                        obj.PrevOutCellArray{1} = varargout{1};
                    else
                        varargout{1} = obj.PrevOutCellArray{1};
                    end
                    if obj.OutputStatus
                        varargout{2} =uint8(status);
                    end
                end
            else
                %Output during simulation
                if isequal(obj.OutputType, 'Unpacked')
                    varargout{1} = uint32(0); 
                    varargout{2} = uint8(0);
                    varargout{3} = uint8(0);
                    varargout{4} = uint8(0);
                    varargout{5} = uint8(0);
                    varargout{6} = uint8(0);
                    varargout{7} = uint8(zeros(1, 64)');
                    if obj.OutputStatus
                        varargout{8} =uint8(0);
                    end

                else
                    varargout{1} = obj.CANFDMsg;
                    if obj.OutputStatus
                        varargout{2} =uint8(0);
                    end
                end
            end
        end
        
        function releaseImpl(obj)
            % Release resources, such as file handles
            close(obj);
        end
        
        function num = getNumInputsImpl(~)
            % Define total number of inputs for system with optional inputs
            num = 0;
        end
        
        function N = getNumOutputsImpl(obj)
            if isequal(obj.OutputType, 'Unpacked')
                N = 7;
                if obj.OutputStatus
                    N = N + 1;
                end  
            else
                N = 1;
                if obj.OutputStatus
                    N = N + 1;
                end
            end
        end
        
        function varargout = getOutputNamesImpl(obj)
            % Return output port names for System block
            if isequal(obj.OutputType, 'Unpacked')
                varargout{1} = 'ID';
                varargout{2} = 'XTD';
                varargout{3} = 'FDF';
                varargout{4} = 'BRS';
                varargout{5} = 'LEN';
                varargout{6} = 'RTR';
                varargout{7} = 'Data';
                if obj.OutputStatus
                    varargout{8} = 'Status';
                end
            else
                N = 1;
                varargout{N} = 'Msg';
                N = N + 1;
                if obj.OutputStatus
                    varargout{N} = 'Status';
                end
            end
        end %getOutputNamesImpl
        
        function varargout = getOutputSizeImpl(obj)
            % Return output port names for System block
            N = 1;
            if isequal(obj.OutputType, 'Unpacked')
                varargout{1} = [1 1];
                varargout{2} = [1 1];
                varargout{3} = [1 1];
                varargout{4} = [1 1];
                varargout{5} = [1 1];
                varargout{6} = [1 1];
                varargout{7} = [64 1];
                if obj.OutputStatus
                    varargout{8} = [1 1];
                end
            else
                varargout{N} = [1 1];
                N = N + 1;
                if obj.OutputStatus
                    varargout{N} = [1 1];
                end
            end
        end
        
        function varargout = getOutputDataTypeImpl(obj)
            N = 1;
            if isequal(obj.OutputType, 'Unpacked')
                varargout{1} = 'uint32'; %ID
                varargout{2} = 'uint8';
                varargout{3} = 'uint8';
                varargout{4} = 'uint8';
                varargout{5} = 'uint8';
                varargout{6} = 'uint8';
                varargout{7} = 'uint8';
                if obj.OutputStatus
                    varargout{8} = 'uint8';
                end
            else
                varargout{N} = obj.CANFDMsgType;
                N = N + 1;
                if obj.OutputStatus
                    varargout{N} = 'uint8';
                end
            end
        end
        
        function varargout = isOutputComplexImpl(obj)
            % Return true for each output port with complex data
            for N = 1 : obj.getNumOutputsImpl
                varargout{N} = false;
            end
        end
        
        function varargout = isOutputFixedSizeImpl(obj)
            % Return true for each output port with fixed size
            for N = 1 : obj.getNumOutputsImpl
                varargout{N} = true;
            end
        end
        
        function sts = getSampleTimeImpl(obj)
            sts = getSampleTimeImpl@matlabshared.svd.BlockSampleTime(obj);
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
    
    methods (Access=protected)
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            inport_label = [];
            num = getNumInputsImpl(obj);
            if num > 0
                inputs = cell(1,num);
                [inputs{1:num}] = getInputNamesImpl(obj);
                for i = 1:num
                    inport_label = [inport_label 'port_label(''input'',' num2str(i) ',''' inputs{i} ''');' newline]; %#ok<AGROW>
                end
            end
            
            outport_label = [];
            num = getNumOutputsImpl(obj);
            if num > 0
                outputs = cell(1,num);
                [outputs{1:num}] = getOutputNamesImpl(obj);
                for i = 1:num
                    outport_label = [outport_label 'port_label(''output'',' num2str(i) ',''' outputs{i} ''');' newline]; %#ok<AGROW>
                end
            end
            maskDisplayCmds_Specific = [];
            maskDisplayCmds_Common = [ ...
                ['color(''white'');', newline]...                                     % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([100,100,100,100],[100,100,100,100]);', newline]...
                ['plot([0,0,0,0],[0,0,0,0]);', newline]...
                ['color(''blue'');', newline] ...                                     % Drawing mask layout of the block
                ['text(99, 92, ''' obj.Logo ''', ''horizontalAlignment'', ''right'');', newline] ...
                ['color(''black'');', newline] ...
                ['text(50,50,''\bf' obj.Title ''', ''texmode'',''on'',''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');', newline], ...
                inport_label, ...
                outport_label, ...
                ];
            
            maskDisplayCmds = [maskDisplayCmds_Common, maskDisplayCmds_Specific];
        end
    end
    
    methods(Static, Access=protected)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','CAN-FD Read', ...
                'Text', ['Read data From the CAN Bus.' newline newline ...
                'In "Unpack" mode, the block outputs the different fields of unpacked CAN Msg.' newline newline ...
                'In "Packed" mode, the block outputs Simulink bus signal.', newline ...
                'To extract data from Simulink bus signal, connect it to CAN-FD Unpack block.']);
        end
        
        function [groups, PropertyList] = getPropertyGroupsImpl
            % CAN base property list
            [~, PropertyListOut] = matlabshared.svd.CANFD.getPropertyGroupsImpl;
            %OutputType CAN Message type
            OutputTypeProp = matlab.system.display.internal.Property('OutputType', 'Description', 'svd:svd:OutputTypePrompt');
            %OutputStatus Output status
            OutputStatusProp = matlab.system.display.internal.Property('OutputStatus', 'Description', 'svd:svd:OutputStatusPrompt');
            %SampleTime Sample time
            SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'svd:svd:SampleTimePrompt');
            
            PropertyListOut{end+1} = OutputTypeProp;
            PropertyListOut{end+1} = OutputStatusProp;
            PropertyListOut{end+1} = SampleTimeProp;
            
            % Create mask display
            Group = matlab.system.display.Section(...
                'PropertyList',PropertyListOut);
            
            groups = Group;
            
            % Return property list if required
            if nargout > 1
                PropertyList = PropertyListOut;
            end
        end
    end
end
