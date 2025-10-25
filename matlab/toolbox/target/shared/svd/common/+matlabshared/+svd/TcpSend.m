classdef (StrictDefaults)TcpSend < matlabshared.svd.TCPBlock
      
     % Send data via tcp
    
    % Copyright 2016-2021 The MathWorks, Inc.
    
    %#codegen    
    properties (Hidden, Nontunable)
        Logo = 'Generic'
    end
    
    methods
        % Constructor
        function obj = TcpSend(varargin)
            obj = obj@matlabshared.svd.TCPBlock(varargin{:});
            obj.Direction = 'Send';
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});
        end
    end
    
     
    methods (Access=protected)
        
        % getInputNamesImpl
        function inputname = getInputNamesImpl(~)
            inputname = 'data';
        end
              
        function flag = isInactivePropertyImpl(obj,prop)
            flag = isInactivePropertyImpl@matlabshared.svd.TCP(obj, prop);
            % Don't show direction since it is fixed to 'Receive'
            if isequal(prop,'Direction')
                flag = true;
            end
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
                ['text(50,10, '' TCP SEND '',''horizontalAlignment'',''center'');' newline]...
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
    end

    
    
    methods(Static, Access=protected)
        function header = getHeaderImpl(~)
            header = matlab.system.display.Header(mfilename('class'), ...
                'ShowSourceLink', false, ...
                'Title', 'TCP Send', 'Text', ...
                sprintf('Send TCP packets to another TCP host on TCP/IP network. \n\nThe block accepts a 1-D array of type uint8, int8, uint16, int16, uint32, int32, boolean, single or double. \n\nSet the Local IP Port to be used as TCP Server port. \n\nIn Client connection mode, set the Server IP address and Server IP port parameters to the IP address and port number of the receiving TCP/IP server respectively.'));
        end
        
        function [groups, PropertyList] = getPropertyGroupsImpl
            [~, PropertyListOut] = matlabshared.svd.TCPBlock.getPropertyGroupsImpl;
            
            for propIdx=1:numel(PropertyListOut)
                if isequal(PropertyListOut{propIdx}.Name, 'BlockingMode')
                    BlockingModeProp = matlab.system.display.internal.Property('BlockingMode', 'Description', 'svd:svd:TCPUDPSendBlockingModePrompt');
                    PropertyListOut{propIdx} = BlockingModeProp;
                end
            end
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