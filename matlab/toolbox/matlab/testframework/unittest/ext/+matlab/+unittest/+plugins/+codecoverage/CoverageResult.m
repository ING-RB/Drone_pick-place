classdef CoverageResult < matlab.unittest.plugins.codecoverage.CoverageFormat & handle
    % CoverageResult - Format to access code coverage results
    %
    %   To access code coverage results in MATLAB programmatically, use an
    %   instance of the CoverageResult class with CodeCoveragePlugin.
    %
    %   CoverageResult properties:
    %       Result      - Code coverage results collected during test run
    %
    %   CoverageResult methods:
    %       CoverageResult - Class constructor
    %
    %   Example:
    %
    %       import matlab.unittest.plugins.CodeCoveragePlugin
    %       import matlab.unittest.plugins.codecoverage.CoverageResult
    %
    %       % Create an instance of the CoverageResult format
    %       format = CoverageResult();
    %
    %       % Create a CodeCoveragePlugin instance using the CoverageResult format
    %       plugin = CodeCoveragePlugin.forFile("C:\projects\myproj\foo.m",...
    %            Producing=format);
    %
    %       % Create a test runner, configure it with the plugin, and run the tests
    %       runner = testrunner;
    %       runner.addPlugin(plugin)
    %       runner.run(testsuite("C:\projects\myproj\tests\tfoo.m"));
    %
    %       % Access coverage results programmatically
    %       results = format.Result;
    %
    %
    %   See also: matlab.unittest.plugins.CodeCoveragePlugin,
    %             matlab.coverage.Result
    
    % Copyright 2022-2023 The MathWorks, Inc.

    properties (SetAccess = private)
        % Result - Code coverage results collected during test run
        %   The Result property stores the code coverage results collected
        %   during a test run as a matlab.coverage.Result array.
        Result = matlab.coverage.Result.empty;
    end

    methods
        function coverageResult = CoverageResult()
            % CoverageResult - Create a CoverageResult format
            %
            %   FORMAT = matlab.unittest.plugins.codecoverage.CoverageResult
            %   creates a CoverageResult format. When used with
            %   CodeCoveragePlugin, it provides programmatic access to code
            %   coverage results collected during a test run as a
            %   matlab.coverage.Result array.
        end        
    end
    
    methods (Hidden, Access = {?matlab.unittest.internal.mixin.CoverageFormatMixin,...
            ?matlab.unittest.plugins.codecoverage.CoverageFormat})
        function generateCoverageReport(format,~,coverageResult,~,~)
           format.Result = coverageResult;
        end
    end
end
