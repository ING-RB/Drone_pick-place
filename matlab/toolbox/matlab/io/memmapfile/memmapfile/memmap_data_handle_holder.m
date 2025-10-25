classdef memmap_data_handle_holder < handle
   properties
       dataHandle = 0;
   end
   
   methods
       function h = memmap_data_handle_holder(dh)
           h.dataHandle = dh;
       end
       
       function delete(h)
           memmapfile.DeleteDataHandle(h.dataHandle);
       end
   end
end

% Copyright 2006-2024 The MathWorks, Inc.