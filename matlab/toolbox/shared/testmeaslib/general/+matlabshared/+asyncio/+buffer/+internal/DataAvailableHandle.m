classdef (ConstructOnLoad) DataAvailableHandle < matlabshared.asyncio.buffer.internal.EventHandle
    %DATAAVAILABLEHANDLE Represents a DataAvailable event.
    % Classes containing the handle may use it to notify listeners that
    % data is available.
    %Allows a contained class to notify listeners on a containing class
    
    % Copyright 2018 The MathWorks, Inc.    

    methods
        function obj = DataAvailableHandle()
            obj@matlabshared.asyncio.buffer.internal.EventHandle("DataAvailable");
        end
    end
end

