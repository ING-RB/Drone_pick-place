% Contents for matlabshared.asyncio.buffer:
% 
% Buffer
% bf = matlabshared.asyncio.buffer.Buffer(); 
%
%   Properties:
%
%   bf.NumElementsAvailable - the number of elements available in the buffer
%   bf.TotalElementsWritten - the total number of elements written to the buffer
%
%   Standard Methods:
%
%   bf.write                - Write MDA-representable data elements to buffer
%   bf.read                 - Retrieves elements from the buffer
%   bf.flush                - Removes all elements from the buffer;
%                             sets the 'NumElementsAvailable' to 0
%
%   Debug Methods:
%
%   bf.enableTrace
%   bf.disableTrace
%
% Data Pump
% dp = matlabshared.asyncio.buffer.DataPump(buffer, dataSink, outputCount, outputPeriod); 
%
%   Properties:
%
%   dp.OutputPeriod - the maximum duration to wait before sending data to
%                     the sink
%   dp.OutputCount  - the number of elements to send to the sink per tick
%   dp.NumElementsInBuffer - the number of elements available in the buffer
%   dp.NumElementsInSink - the total number of elements written to the sink
%
%   Standard Methods:
%
%   dp.start               - Retrieves elements from the buffer
%   dp.stop                - Removes all elements from the buffer;
%                            sets the 'NumElementsAvailable' to 0
%
% Data Sink
% ds = matlabshared.asyncio.buffer.DataSink(); 
%
%   Properties:
%
%   ds.IsOpen               - indicates whether the sink is ready to accept
%                             data
%   ds.TotalElementsHandled - the total number of elements handled by the
%                             sink
%
%   Standard Methods:
%
%   ds.open                - Ready the sink to handle data
%   ds.close               - Tells the sink it will no longer receive data
%   ds.handleData          - Calls a user-defined method on the data
%
%  BufferChannel:
%
%  bc = matlabshared.asyncio.buffer.internal.BufferChannel([inf 0]); 
%
%   Properties:
%
%   bc.NumElementsAvailable - the number of elements available in the buffer
%   bc.TotalElementsWritten - the total number of elements written to the buffer
%
%   Standard Methods:
%
%   bc.open                 - Opens the channel for writing/reading
%   bc.write                - Write MDA-representable data elements to buffer
%   bc.read                 - Retrieves elements from the buffer
%   bc.flush                - Removes all elements from the buffer;
%                             sets the 'NumElementsAvailable' to 0
%   bc.close                - Closes the channel
%   bc.reset                - Set 'NumElementsAvailable' and 'TotalElementsWritten' to 0
%
%   Debug Methods:
%
%   bc.enableTrace
%   bc.disableTrace
%
%   BufferChannel is an undocumented class: it may be removed in a future
%   release. 

%   Copyright 2018 The MathWorks, Inc.