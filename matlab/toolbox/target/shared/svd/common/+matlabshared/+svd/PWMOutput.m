classdef (StrictDefaults)PWMOutput <  matlabshared.svd.PWM
    %PWMOUT PWM Output block base class
    %   
    
    % Copyright 2015 The MathWorks, Inc.
    
    %#codegen
    properties (Hidden, Nontunable)
        Logo = 'Generic'
    end
    
    methods
        function obj = PWMOutput(varargin)
            coder.allowpcode('plain');
            setProperties(obj, nargin, varargin{:});
        end
    end
       
    methods (Access=protected)
        function flag = isInactivePropertyImpl(~,prop)
            % Don't show direction since it is fixed to 'input'
            if ismember(prop,{'Pin','EnableInputFrequency','InitialFrequency','InitialDutyCycle'})
                flag = false;
            else
                flag = true;
            end
        end
        
        % Name to display as block icon
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            x = 1:12;
            y = double(abs(0:1/5:1)>=0.5);
            y = [y flip(y)];
            x = [x(1:3) 3.999 x(4:9) 9.001 x(10:end)];
            y = [y(1:3) 0 y(4:9) 0 y(10:end)]*45+30;
            x = [x x+11];
            y = [y y];
            
            x1 = 1:32;
            y1 = double(abs(0:1/15:1)>=0.5);
            y1 = [y1 flip(y1)];
            x1 = [x1(1:8) 8.999 x1(9:24) 24.001 x1(25:end)];
            y1 = [y1(1:8) 0 y1(9:24) 0 y1(25:end)]*45+30;
            
            x = [x x1+x(end)]+22;
            y = [y y1];
            maskDisplayCmds = [ ...
                ['color(''white'');' char(10)], ...                                     % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([100,100,100,100]*1,[100,100,100,100]*1);' char(10)],...
                ['plot([100,100,100,100]*0,[100,100,100,100]*0);' char(10)],...
                ['color(''blue'');' char(10)], ...                                     % Drawing mask layout of the block
                ['text(99, 92, ''' obj.Logo ''', ''horizontalAlignment'', ''right'');' char(10)],   ...
                ['color(''black'');' char(10)],...
                ['plot([' num2str(x) '],[' num2str(y) '])' char(10)], ...
                ['text(50, 15, ''Pin: ' num2str(obj.Pin) ''' ,''horizontalAlignment'', ''center'');' char(10)], ...
                ];
        end
    end
    
    methods (Static, Access = protected)
        % Header for System object display
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','PWM Output', ...
                'Text', ['Generate square waveform on the specified output pin.' ...
                'The block input controls the duty cycle of the square waveform. An' ...
                ' input value of 0 produces a 0 percent duty cycle and an input value' ...
                [' of 100 produces a 100 percent duty cycle.' char(10) char(10)], ...
                'Enter the number of the PWM output pin. Do not assign the same pin' ...
                ' number to multiple blocks within a model.']);
        end
        
        function [groups, PropertyList] = getPropertyGroupsImpl
            [groups,PropertyListOut] = matlabshared.svd.PWM.getPropertyGroupsImpl;
            
            if nargout > 1
                PropertyList = PropertyListOut;
            end
        end
    end
end

