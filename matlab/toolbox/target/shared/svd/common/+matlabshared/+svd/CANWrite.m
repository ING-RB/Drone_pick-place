classdef (StrictDefaults)CANWrite < matlabshared.svd.CAN
    %CANWRITEBLOCK Send data to CAN Bus.
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    %#codegen
    properties (Hidden, Nontunable)
        Logo = 'Generic'
    end
    
    properties (Nontunable)
        %OutputStatus Output status
        OutputStatus (1, 1) logical = false;
        BlockingMode_ (1, 1) logical = false;
    end
    
    methods
        % Constructor
        function obj = CANWrite(varargin)
            obj = obj@matlabshared.svd.CAN(varargin{:});
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods(Access = protected)
        function varargout = stepImpl(obj, varargin)
            Status = uint8(0);
            if coder.target('Rtw')
                if obj.DataFormat == "Raw Data"
                    if obj.Identifier == "Standard (11-bit identifier)"
                        ext = uint8(0);
                    else
                        ext = uint8(1);
                    end
                    
                    if obj.RemoteFrame
                        rem = uint8(1);
                    else
                        rem = uint8(0);
                    end
                    Status = write(obj, varargin{1}, obj.MsgId, obj.MsgLen, uint8(rem), uint8(ext));
                else
                    Status = write(obj, varargin{1}.Data, varargin{1}.ID, varargin{1}.Length, varargin{1}.Remote, varargin{1}.Extended);
                end
            end
            if nargout > 0
                varargout{1} = Status;
            end
        end
        
        function validateInputsImpl(obj, data)
            if obj.DataFormat == "Raw Data"
                if obj.MsgLen > 0
                    validateattributes(data, {'uint8'},{'nonnan','finite','size',[obj.MsgLen,1]}, '', 'data');
                end
            end
        end
        
        function setupImpl(obj)
            % Initialise CAN Module
            open(obj);
        end
        
        function releaseImpl(obj)
            % Release resources, such as file handles
            close(obj);
        end
        
        
        function num = getNumInputsImpl(~)
            % Define total number of inputs for system with optional inputs
            num = 1;
        end
        
        function num = getNumOutputsImpl(obj)
            % Define total number of outputs for system with optional
            % outputs
            if obj.OutputStatus
                num = 1;
            else
                num = 0;
            end
        end
        
        function varargout = getInputNamesImpl(~)
            % Return input port names for System block
            varargout{1} = 'Tx';
        end
        
        function varargout = getOutputNamesImpl(obj)
            if obj.OutputStatus
                varargout{1} = 'Status';
            else
                varargout = {};
            end
        end
        
        function varargout = getOutputSizeImpl(obj)
            % Return size for each output port
            if obj.OutputStatus
                varargout{1} = [1 1];
            end
        end
        
        function varargout = getOutputDataTypeImpl(obj)
            % Return data type for each output port
            if obj.OutputStatus
                varargout{1} = 'uint8';
            end
        end
        
        function out = isOutputComplexImpl(~)
            % Return true for each output port with complex data
            out = false;
        end
        
        function varargout = isOutputFixedSizeImpl(obj)
            % Return true for each output port with fixed size
            if obj.OutputStatus
                varargout{1} = true;
            end
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
                if obj.RemoteFrame == true
                    maskDisplayCmds_Specific = [ ...
                        ['text(50, 35, ''\fontsize{10}' idType{1} int2str(obj.MsgId) '' ''',''texmode'',''on'',''horizontalAlignment'', ''center'');',newline]  ...
                        ['text(50, 25, ''\fontsize{10}' 'Remote Frame' '' ''',''texmode'',''on'',''horizontalAlignment'', ''center'');',newline]  ...
                        ];
                else
                    maskDisplayCmds_Specific = ['text(50, 35, ''\fontsize{10}' idType{1} int2str(obj.MsgId) '' ''',''texmode'',''on'',''horizontalAlignment'', ''center'');',newline];
                end
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
                ['text(50,50,''\fontsize{12}\bfCAN Write'',''texmode'',''on'',''horizontalAlignment'',''center'',''verticalAlignment'',''middle'');', newline], ...
                ['text(50,10,' canname ',''horizontalAlignment'', ''center'');', newline], ...
                inport_label, ...
                outport_label, ...
                ];
            
            maskDisplayCmds = [maskDisplayCmds_Common, maskDisplayCmds_Specific];
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
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','CAN Write', ...
                'Text', ['Send serial data to CAN Bus.' newline newline ...
                'In "Raw data" mode, the block accepts a 1-D array of type uint8. In "CAN Msg" mode, the block accepts input as Simulink bus signal from CAN Pack block']);
        end
        
        function [groups, PropertyList] = getPropertyGroupsImpl
            % CAN base property list
            [~, PropertyListOut] = matlabshared.svd.CAN.getPropertyGroupsImpl;
            
            %OutputStatus Output status
            OutputStatusProp = matlab.system.display.internal.Property('OutputStatus', 'Description', 'svd:svd:OutputStatusPrompt');
            RemoteFrameProp = matlab.system.display.internal.Property('RemoteFrame', 'Description', 'svd:svd:CANRemoteFramePrompt');
            
            % Property list
            PropertyListOut{end+1} = RemoteFrameProp;
            PropertyListOut{end+1} = OutputStatusProp;
            
            
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
