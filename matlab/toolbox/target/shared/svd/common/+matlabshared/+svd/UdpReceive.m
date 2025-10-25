classdef (StrictDefaults)UdpReceive < matlabshared.svd.UDPBlock ...
        & matlabshared.svd.BlockSampleTime
    % Receive data via UDP
    
    % Copyright 2016-2023 The MathWorks, Inc.
    
    %#codegen
    properties (Hidden, Nontunable)
        Logo = 'Generic'
    end
    
    properties (Nontunable)
        %SampleTime Sample time
        SampleTime = -1;
    end

    methods
        % Constructor
        function obj = UdpReceive(varargin)
            obj = obj@matlabshared.svd.UDPBlock(varargin{:});
            obj.Direction = 'Receive';
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:},'Length');
        end
        
        function set.SampleTime(obj,newTime)
            coder.extrinsic('error');
            coder.extrinsic('message');

            newTime = matlabshared.svd.internal.validateSampleTime(newTime);
            obj.SampleTime = newTime;
        end        
    end
    
    
    methods (Access=protected)
        
        
        function flag = isInactivePropertyImpl(obj,prop)
            flag = isInactivePropertyImpl@matlabshared.svd.UDP(obj, prop);
        end
        
        
        
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
            
            maskDisplayCmds = [ ...
                ['color(''white'');' newline], ...                                     % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([100,100,100,100]*1,[100,100,100,100]*1);' newline],...
                ['plot([100,100,100,100]*0,[100,100,100,100]*0);' newline],...
                ['color(''blue'');' newline], ...                                     % Drawing mask layout of the block
                ['text(99, 92, ''' obj.Logo ''', ''horizontalAlignment'', ''right'');' newline],   ...
                ['color(''black'');' newline],...
                ['text(50,10, '' UDP RCV '',''horizontalAlignment'',''center'');' newline]...
                ['plot([35,65],[50,50]);',newline]...
                ['plot([35,35],[50,40]);',newline]...
                ['plot([65,65],[50,40]);',newline]...
                ['plot([50,50],[60,40]);',newline]...
                ['patch([30 40 40 30],[25 25 35 35])',newline]...
                ['patch([45 55 55 45],[25 25 35 35])',newline]...
                ['patch([60 70 70 60],[25 25 35 35])',newline]...
                ['patch([45 55 55 45],[62 62 72 72])',newline]...
                inport_label, ...
                outport_label, ...
                ];
        end
        
        function sts = getSampleTimeImpl(obj)
          sts = getSampleTimeImpl@matlabshared.svd.BlockSampleTime(obj);
        end
    end
    
    
    
    methods(Static, Access=protected)
        function header = getHeaderImpl(~)
            header = matlab.system.display.Header(mfilename('class'), ...
                'ShowSourceLink', false, ...
                'Title', 'UDP Receive', 'Text', ...
                sprintf('Receives UDP packets from another UDP host specified by the Remote IP address.\n\nThe block outputs the values received as an [Nx1] array. \n\nThe sending UDP host must send UDP packets from the Remote IP Address to the Local IP port specified.'));
        end
        
        function [groups, PropertyList] = getPropertyGroupsImpl
            [~, PropertyListOut] = matlabshared.svd.UDPBlock.getPropertyGroupsImpl;
            
            for propIdx=1:numel(PropertyListOut)
                if isequal(PropertyListOut{propIdx}.Name, 'BlockingMode')
                    BlockingModeProp = matlab.system.display.internal.Property('BlockingMode', 'Description', 'svd:svd:TCPUDPReceiveBlockingModePrompt');
                    PropertyListOut{propIdx} = BlockingModeProp;
                end
            end
            SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'svd:svd:SampleTimePrompt');
            
            % Add to property list
            PropertyListOut{end+1} = SampleTimeProp;
            
            % Create mask display
            Group = matlab.system.display.Section(...
                'PropertyList',PropertyListOut);
            
            groups = Group;
            
            if nargout > 1
                PropertyList = PropertyListOut;
            end
        end
        
    end
end
