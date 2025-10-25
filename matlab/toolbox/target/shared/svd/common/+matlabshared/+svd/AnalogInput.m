classdef AnalogInput < matlabshared.svd.AnalogInSingle ...
    & matlabshared.svd.BlockSampleTime
    %ANALOGINPUT Measure the voltage of an analog input pin.
    %
    %Do not assign the same Pin number to multiple blocks within a model.
    %

    % Copyright 2015-2023 The MathWorks, Inc.
    
    %#codegen
    %#ok<*EMCA>
    properties (Hidden, Nontunable)
        Logo = 'Generic'
    end

    properties (Nontunable)
        %SampleTime Sample time
        SampleTime = -1;
    end

    
    methods
        function obj = AnalogInput(varargin)
            coder.allowpcode('plain');
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
        function flag = isInactivePropertyImpl(obj,prop)
            flag = isInactivePropertyImpl@matlabshared.svd.AnalogInSingle(obj,prop);
            % Don't show direction since it is fixed to 'output'
            if isequal(prop, 'SampleTime')
                flag = false;
            end
        end
        
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            maskDisplayCmds = { ...
                'color(''white'');',...                                     % Fix min and max x,y co-ordinates for autoscale mask units
                'plot([100,100,100,100]*1,[100,100,100,100]*1);',...
                'plot([100,100,100,100]*0,[100,100,100,100]*0);',...
                'color(''blue'');', ...                                     % Drawing mask layout of the block
                ['text(99, 92, ''' obj.Logo ''', ''horizontalAlignment'', ''right'');'],   ...
                'color(''black'');',...
                'plot([30:70],(sin(2*pi*[0.25:0.01:0.65]*(-5))+1)*15+35)', ...
                ['text(50, 15, ''Pin: ' num2str(obj.Pin) ''' ,''horizontalAlignment'', ''center'');'], ...
                };
        end
        
        function sts = getSampleTimeImpl(obj)
          sts = getSampleTimeImpl@matlabshared.svd.BlockSampleTime(obj);
        end
    end
    
    methods(Static, Access=protected)
        function [groups, PropertyList] = getPropertyGroupsImpl
            % Get the property list
            [~,PropertyListOut] = matlabshared.svd.AnalogInSingle.getPropertyGroupsImpl;

            % Sample time
            SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'svd:svd:SampleTimePrompt');

            % Add Sample time property to property list
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
