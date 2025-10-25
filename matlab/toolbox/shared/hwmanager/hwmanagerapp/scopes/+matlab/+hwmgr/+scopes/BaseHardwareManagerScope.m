classdef (Hidden) BaseHardwareManagerScope < matlabshared.scopes.WebWindow & ...
        matlabshared.scopes.WebStreamingSource
    %BASEHARDWAREMANAGERSCOPE Base handle class interface of Hardware
    %Manager scopes
    
    % Copyright 2019 The MathWorks, Inc.
    
    properties (Access = private)
        %NumInputPorts This is the number of input ports to streaming
        %source, there can be multiple channels in each port.
        NumInputPorts = 1
        
        %Name This is the name to dispay for the webwindow
        Name = "Scope"
    end
    
    methods
        function obj = BaseHardwareManagerScope(url)
            obj@matlabshared.scopes.WebStreamingSource();
            obj.TimeBased = false;
            % Need to take the html url as input and give to MessageHandler
            obj.MessageHandler.url = url;
        end
        
        function show(obj)
            show@matlabshared.scopes.WebWindow(obj);
            obj.waitForOpen();
        end
        
        function write(obj, data)
            write@matlabshared.scopes.WebStreamingSource(obj, data);
        end
        
        function release(obj)
            % Release resources
            obj.StreamingSourceImpl.release();
            obj.releaseStreamingSource();
        end
        
        function delete(obj)
            obj.release();
            delete@matlabshared.scopes.WebWindow(obj);
            delete@matlabshared.scopes.WebStreamingSource(obj);
            delete(obj.MessageHandler);
        end
        
        function waitForOpen(obj)
            % Wait for the scope window to open.
            waitfor(obj.MessageHandler, 'OpenComplete', true);
        end
    end
    
    methods(Access = public, Hidden)
        % Following are abstract methods from superclass that must be
        % implemented
        
        function numInputs = getNumInputs(obj)
            numInputs = obj.NumInputPorts;
        end
        
        function name = getName(obj)
            name = obj.Name;
        end
        
        % Following methods must be implemented to resolve conflict
        % definitions in superclass
        function str = getQueryString(this)
            str = getQueryString@matlabshared.scopes.WebStreamingSource(this);
        end
        
        function setDebugLevel(obj, level)
            setDebugLevel@matlabshared.scopes.WebStreamingSource(obj, level);
            obj.MessageHandler.DebugLevel = level;
        end
        
        function level = getDebugLevel(obj)
            level = getDebugLevel@matlabshared.scopes.WebStreamingSource(obj);
        end
    end
end

