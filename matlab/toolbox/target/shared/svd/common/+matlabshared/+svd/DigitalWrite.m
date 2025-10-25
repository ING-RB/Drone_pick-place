classdef (StrictDefaults)DigitalWrite < matlabshared.svd.DigitalIO 
    %DigitalWrite Base class for Digital Write System object
    %
    
    % Copyright 2015 The MathWorks, Inc.
    %#codegen
    properties (Hidden, Nontunable)
        Logo = 'Generic'
    end
    
    methods
        function obj = DigitalWrite(varargin)
            coder.allowpcode('plain');
            obj.Direction = 'output';
            setProperties(obj,nargin,varargin{:});
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
    end
    
    methods(Static, Access=protected)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','Digital Write', ...
                'Text', [['Set the logical state of a digital output pin.' char(10) char(10)] ...
                'Do not assign the same Pin number to multiple blocks within a model.']);
        end
        
        function [groups, PropertyList] = getPropertyGroupsImpl
            [groups, PropertyListOut] = matlabshared.svd.DigitalIO.getPropertyGroupsImpl;

            if nargout > 1
                PropertyList = PropertyListOut;
            end
        end
    end
end
