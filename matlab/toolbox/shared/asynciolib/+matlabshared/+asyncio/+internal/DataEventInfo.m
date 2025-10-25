classdef DataEventInfo < event.EventData
% Information associated with the DataWritten and DataRead events of the streams.

% Copyright 2007-2021 The MathWorks, Inc.
% $Revision: 1.1.6.2 $

    properties
        CurrentCount % A scalar double from 0 to the stream's buffer limit.
    end

    methods
        function obj = DataEventInfo(count)
        % Constructor
            obj.CurrentCount = count;
        end
    end
end
