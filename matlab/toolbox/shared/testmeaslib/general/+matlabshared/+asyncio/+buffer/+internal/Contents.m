% Contents for  matlabshared.asyncio.buffer.internal:
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