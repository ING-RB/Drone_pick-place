classdef (Sealed) FunctionTestCaseLiaison < handle
    % FunctionTestCaseLiaison - Liaison to be used by a FunctionTestCaseService.
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties
        FunctionTestCase(1,1) string
        FunctionTestCaseKeyword(1,1) string
    end
    
    methods
        function liaison = FunctionTestCaseLiaison(fcnTestCaseKeyword)
            liaison.FunctionTestCaseKeyword = fcnTestCaseKeyword;
        end
    end
    
end