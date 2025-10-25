classdef (StrictDefaults)CANRead < matlabshared.svd.CAN & ...
        matlabshared.svd.BlockSampleTime
        %CANREADBLOCK Read data From CAN Bus.
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    %#codegen
    properties (Hidden, Nontunable)
        Logo = 'Generic'
    end
    
    properties (Nontunable)
        OutputStatus (1, 1) logical = false;
        BlockingMode_ (1, 1) logical = false;
        %SampleTime Sample time
        SampleTime = -1;
    end
    
    methods
        % Constructor
        function obj = CANRead(varargin)
            obj = obj@matlabshared.svd.CAN(varargin{:});
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});
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
            % Initialise CAN Module
            open(obj);
        end
        
        function varargout = stepImpl(obj)
            idx = 1;
            if coder.target('Rtw')
                rx = read(obj);
                if obj.DataFormat == "Raw Data"
                    if obj.MsgLen > 0
                        varargout{idx} = uint8(rx.data);
                        idx = idx + 1;
                    end
                    if obj.OutputStatus
                        varargout{idx} =  uint8(rx.status);
                        idx = idx + 1;
                    end
                    if obj.RemoteFrame
                        varargout{idx} =  uint8(rx.rtr);
                    end
                else
                    varargout{1}.Extended = uint8(rx.extended);
                    varargout{1}.Length = uint8(rx.dataLength);
                    varargout{1}.Remote = uint8(rx.rtr);
                    varargout{1}.Error =uint8(0);
                    varargout{1}.ID = uint32(rx.id);
                    varargout{1}.Timestamp = 0;
                    varargout{1}.Data = rx.data';
                    if obj.OutputStatus
                        varargout{2} =uint8(rx.status);
                    end
                end
            else
                if obj.DataFormat == "Raw Data"
                    if obj.MsgLen > 0
                        varargout{idx} = uint8(zeros(1, obj.MsgLen));
                        idx = idx + 1;
                    end
                    if obj.OutputStatus
                        varargout{idx} =  uint8(0);
                        idx = idx + 1;
                    end
                    if obj.RemoteFrame
                        varargout{idx} =  uint8(0);
                    end
                    
                else
                    varargout{1}.Extended = uint8(0);
                    varargout{1}.Length = uint8(0);
                    varargout{1}.Remote = uint8(0);
                    varargout{1}.Error =uint8(0);
                    varargout{1}.ID = uint32(0);
                    varargout{1}.Timestamp = 0;
                    varargout{1}.Data = uint8(zeros(obj.MsgLen,1));
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
            if obj.DataFormat == "Raw Data"
                N = 0;
                if obj.MsgLen > 0
                    N = N + 1;
                end
                if obj.OutputStatus
                    N = N + 1;
                end
                if obj.RemoteFrame
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
            N = 1;
            if obj.DataFormat == "Raw Data"
                if obj.MsgLen > 0
                    varargout{N} = 'Data';
                    N = N + 1;
                end
                
                if obj.OutputStatus
                    varargout{N} = 'Status';
                    N = N + 1;
                end
                
                if obj.RemoteFrame
                    varargout{N} = 'Remote';
                end
            else
                varargout{N} = 'CAN Msg';
                N = N + 1;
                if obj.OutputStatus
                    varargout{N} = 'Status';
                end
            end
        end %getOutputNamesImpl
        
        function varargout = getOutputSizeImpl(obj)
            % Return output port names for System block
            N = 1;
            if obj.DataFormat == "Raw Data"
                if obj.MsgLen > 0
                    varargout{N} = [1 obj.MsgLen];
                    N = N + 1;
                end
                
                if obj.OutputStatus
                    varargout{N} = [1 1];
                    N = N + 1;
                end
                
                if obj.RemoteFrame
                    varargout{N} = [1 1];
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
            if obj.DataFormat == "Raw Data"
                if obj.MsgLen > 0
                    varargout{N} = 'uint8';
                    N = N + 1;
                end
                
                if obj.OutputStatus
                    varargout{N} = 'uint8';
                    N = N + 1;
                end
                
                if obj.RemoteFrame
                    varargout{N} = 'uint8';
                end
            else
                varargout{N} = "Bus: CANMsg";
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
            
            if isnumeric(obj.CANModule)
                canname = ['sprintf(''CAN: %X'',' num2str(obj.CANModule) ')'];
            else
                canname = ['sprintf(''CAN: %s'',''' obj.CANModule ''')'];
            end
            
            if obj.DataFormat == "Raw Data"
                idType = "Standard ID:";
                if obj.Identifier == "Extended (29-bit identifier)"
                    idType = "Extended ID:";
                end
                maskDisplayCmds_Specific = ['text(50, 35, ''\fontsize{10}' idType{1} int2str(obj.MsgId) '' ''',''texmode'',''on'',''horizontalAlignment'', ''center'');',newline];
            else
                maskDisplayCmds_Specific = [];
            end
            
            maskDisplayCmds_Common = [ ...
                ['color(''white'');', newline]...                                     % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([100,100,100,100],[100,100,100,100]);', newline]...
                ['plot([0,0,0,0],[0,0,0,0]);', newline]...
                ['color(''blue'');', newline] ...                                     % Drawing mask layout of the block
                ['text(99, 92, ''' obj.Logo ''', ''horizontalAlignment'', ''right'');', newline] ...
                ['color(''black'');', newline] ...
                ['text(50,50,''\fontsize{12}\bfCAN Read'',''texmode'',''on'',''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');', newline], ...
                ['text(50,10,' canname ',''horizontalAlignment'', ''center'');', newline], ...
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
                'Title','CAN Read', ...
                'Text', ['Read data From the CAN Bus.' newline newline ...
                'In "Raw data" mode, the block outputs values received as [1xN] array of type uint8.' newline newline ...
                'In "CAN Msg" mode, the block outputs Simulink bus signal.', newline ...
                'To extract data from Simulink bus signal, connect it to CAN Unpack block from Vehicle Network Toolbox']);
        end
        
        function [groups, PropertyList] = getPropertyGroupsImpl
            % CAN base property list
            [~, PropertyListOut] = matlabshared.svd.CAN.getPropertyGroupsImpl;
            %OutputStatus Output status
            OutputStatusProp = matlab.system.display.internal.Property('OutputStatus', 'Description', 'svd:svd:OutputStatusPrompt');
            %SampleTime Sample time
            SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'svd:svd:SampleTimePrompt');
            
            RemoteFrameProp = matlab.system.display.internal.Property('RemoteFrame', 'Description', 'svd:svd:CANReadRemoteFramePrompt');
            
            PropertyListOut{end+1} = RemoteFrameProp;
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
