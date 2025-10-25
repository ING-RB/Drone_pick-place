classdef DecodingStates < uint8
    % enum class for decoder. 

    %Copyright 2021 The MathWorks, Inc.
   enumeration
      WaitForHeader (0)
      WaitForMinimumData (1) 
      WaitForTerminator (2)
   end
end