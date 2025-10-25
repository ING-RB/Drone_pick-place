classdef (Hidden) TimeScopeImplementation < matlabshared.scopes.WebWindow & ...
        matlabshared.scopes.WebDynamicStreamingSource
    
    %TIMESCOPEIMPLEMENTATION This class provides implementations specific
    %for the TimeScope
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties (Access = private)
        %Name This is the name to dispay for the webwindow
        Name = "Scope"
    end
    
    methods
        function obj = TimeScopeImplementation(url)
            obj@matlabshared.scopes.WebDynamicStreamingSource();
            
            % Need to take the html url as input and give to MessageHandler
            obj.MessageHandler.url = url;
        end
        
        function show(obj)
            show@matlabshared.scopes.WebWindow(obj);
            obj.waitForOpen();
            obj.MessageHandler.onStart();
        end
        
        function release(obj)
            % Release resources
            obj.StreamingSourceImpl.release();
            obj.releaseStreamingSource();
        end
        
        function delete(obj)
            obj.release();
            delete@matlabshared.scopes.WebWindow(obj);
            delete@matlabshared.scopes.WebDynamicStreamingSource(obj);
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
        
        function name = getName(obj)
            name = obj.Name;
        end
        
        % Following methods must be implemented to resolve conflict
        % definitions in superclass
        function str = getQueryString(this)
            str = getQueryString@matlabshared.scopes.WebDynamicStreamingSource(this);
        end
        
        function setDebugLevel(obj, level)
            setDebugLevel@matlabshared.scopes.WebDynamicStreamingSource(obj, level);
            obj.MessageHandler.DebugLevel = level;
        end
        
        function level = getDebugLevel(obj)
            level = getDebugLevel@matlabshared.scopes.WebDynamicStreamingSource(obj);
        end
        
        function clearDataOnBackend(obj)
            clientId = obj.ClientId;
            matlabshared.scopes.WebScope.clearDataBuffer(clientId);
        end
    end
    
    methods(Access = protected)
        function h = getMessageHandler(~)
            h = matlab.hwmgr.scopes.TimeScopeMessageHandler();
        end
        
        function value = getDataProcessingStrategy(~)
            % return the data strategy used by the scope
            value = 'webscope_timedata_proc_strategy';
        end
        
        function value = getFilterImpls(~)           
            % return the back-end dynamic repository used by the scope
            value = {'webscope_datastorage_filter', ...
                    'dynamicdata_extraction_filter'};
        end
        
    end
end