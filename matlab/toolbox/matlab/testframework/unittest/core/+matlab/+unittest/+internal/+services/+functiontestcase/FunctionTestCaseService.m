classdef FunctionTestCaseService < matlab.unittest.internal.services.Service
    %
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties(Abstract, Constant, Access = protected)
        Keyword(1,1) string
        FunctionTestClassName(1,1) string
    end
    
    methods (Sealed)
        function fulfill(services, liaison)
            %   fulfill(SERVICES, LIAISON)- fulfills a FunctionTestCase service
            %   by locating the appropriate service based on the user-specified keyword
            
            supportsKeyword = [services.Keyword] == liaison.FunctionTestCaseKeyword;
            
            if ~any(supportsKeyword)
                throw(MException(message(...
                    'MATLAB:unittest:functiontests:InvalidFunctionTestCaseKeyword', ...
                    liaison.FunctionTestCaseKeyword)));
                
            end
            
            supportedService = services(supportsKeyword);
            if ~isscalar(supportedService)
                throw(MException(message(...
                    'MATLAB:unittest:functiontests:DuplicateFunctionTestCaseKeyword', ...
                    liaison.FunctionTestCaseKeyword)));
            end
            
            functionTestCase = supportedService.FunctionTestClassName;
            liaison.FunctionTestCase = functionTestCase;
            
            if exist(liaison.FunctionTestCase,'class')~=8
                throw(MException(message(...
                    'MATLAB:unittest:functiontests:InvalidFunctionTestCase', ...
                    liaison.FunctionTestCase)));
            end
        end
    end
end