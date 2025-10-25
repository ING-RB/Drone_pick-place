classdef ValueConverterType
    %VALUECONVERTERTYPE An enumeration class to define the value converter
    %type, for example,
    % PV pairs to Java Map
    % PV pairs to JSON compatible
    % PV pairs to JSON compatible struct
    
    % Copyright 2017 The MathWorks, Inc.
    
   enumeration
      JSON_COMPATIBLE   % Convert the data to be JSON compatible
      JSON_COMPATIBLE_STRUCT % Convert the data to a JSON compatible struct
      JAVA  % Convert the data to Java data
   end
end