classdef (Sealed) Channel < matlabshared.asyncio.internal.Channel
    % A sub-class of an matlabshared.asyncio.internal.Channel used for udp client and servers.
    %
    
    %   Copyright 2015-2021 The MathWorks, Inc.
    
    %% Lifetime
    methods
        function obj = Channel(devicePluginBaseName, varargin)
            
            pluginDir = fullfile(codertarget.asyncioplugins.internal.getRootDir,'bin', computer('arch'));
            
            obj@matlabshared.asyncio.internal.Channel(fullfile(pluginDir, devicePluginBaseName),...
                                fullfile(pluginDir, 'udpmlconverter'),...
                                varargin{:});
                                      
            % To allow for non-block I/O.
            obj.InputStream.Timeout = Inf;
            obj.OutputStream.Timeout = Inf;                                      
        end
    end
    
   %% Overrides of base class
   % Override connection/disconnection of data flow callbacks because we 
   % aren't going to use the DataWritten/DataRead events and the callbacks
   % degrade performance of the IntervalTimer (g631475).
   methods (Access='protected')
       function preOpen(obj) %#ok<MANU>
        end
        
        function postClose(obj) %#ok<MANU>
        end
   end
end

