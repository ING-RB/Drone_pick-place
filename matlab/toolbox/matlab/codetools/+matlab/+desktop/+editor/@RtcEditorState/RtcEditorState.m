classdef (Hidden) RtcEditorState < int8
    %RtcEditorState enumerates the states of RTC editor
    
    % Copyright 2019 The MathWorks, Inc.
   enumeration
       CREATED (1)
       DESTROYED (-1)
       UNKNOWN (0)
   end
end