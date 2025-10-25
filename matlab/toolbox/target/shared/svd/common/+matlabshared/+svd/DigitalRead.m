classdef (StrictDefaults)DigitalRead < matlabshared.svd.DigitalIO ...
        & matlabshared.svd.BlockSampleTime
    %DigitalRead Get the logical state of a digital input pin.
    %
    %Do not assign the same Pin number to multiple blocks within a model.
    
    % Copyright 2015-2023 The MathWorks, Inc.
    %#codegen
    properties (Hidden, Nontunable)
        Logo = 'Generic'
    end

    properties (Nontunable)
        %SampleTime Sample time
        SampleTime = -1;
    end

    
    methods
        function obj = DigitalRead(varargin)
            coder.allowpcode('plain');
            obj.Direction = 'input';
            setProperties(obj,nargin,varargin{:});  
        end

        function set.SampleTime(obj,newTime)
            coder.extrinsic('error');
            coder.extrinsic('message');

            newTime = matlabshared.svd.internal.validateSampleTime(newTime);
            obj.SampleTime = newTime;
        end
    end
    
    methods (Access=protected)
        function flag = isInactivePropertyImpl(~,prop)
            % Don't show direction since it is fixed to 'input'
            flag = false;
            if isequal(prop,'Direction')
                flag = true;
            end
        end
        
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            x = 1:22;
            y = double(abs(0:1/10:1)>=0.5);
            y = [y flip(y)];
            x = [x(1:5) 5.999 x(6:17) 17.001 x(18:end)]+28;
            y = [y(1:5) 0 y(6:17) 0 y(18:end)]*45+30;
            x = [x x+21];
            y = [y y];
            maskDisplayCmds = [ ...
                ['color(''white'');', char(10)]...                                     % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([100,100,100,100],[100,100,100,100]);', char(10)]...
                ['plot([0,0,0,0],[0,0,0,0]);', char(10)]...
                ['color(''blue'');', char(10)] ...                                     % Drawing mask layout of the block
                ['text(99, 92, ''' obj.Logo ''', ''horizontalAlignment'', ''right'');', char(10)] ...
                ['color(''black'');', char(10)] ...
                ['plot([' num2str(x) '],[' num2str(y) ']);', char(10)], ...
                ['text(50, 15, ''Pin: ' num2str(obj.Pin) ''' ,''horizontalAlignment'', ''center'');', char(10)], ...
                ];
        end
        
        function sts = getSampleTimeImpl(obj)
          sts = getSampleTimeImpl@matlabshared.svd.BlockSampleTime(obj);
        end
    end
    
    methods(Static, Access=protected)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','Digital Read', ...
                'Text', [['Read the logical state of a digital input pin.' char(10) char(10)] ...
                'Do not assign the same Pin number to multiple blocks within a model.']);
        end
        
        function [groups, PropertyList] = getPropertyGroupsImpl
            [~, PropertyListOut] = matlabshared.svd.DigitalIO.getPropertyGroupsImpl;
            
            % Sample time
            SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'svd:svd:SampleTimePrompt');
            % Add sample time Property
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

