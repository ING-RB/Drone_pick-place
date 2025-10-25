classdef (Hidden) SPISensorUtilities < handle
    % This class provides internal API to be used by sensor infrastructure
    % for code generation.
    
    % Copyright 2023 The MathWorks, Inc.
    
    %#codegen
    
    methods(Abstract, Access = public)
        % Implement the following methods in the hardware class
         SPIDriverObj = getSPIDriverObj(obj, busNum);
    end
end