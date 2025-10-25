function runner = testrunner(runnerOption, namedargs) 
% testrunner - Create a test runner
%
%   The testrunner function provides a simple way to create a test runner, 
%   used to run a suite of tests.
%
%   RUNNER = testrunner() creates a default runner, 
%   which is the same as the runner configured by default for runtests().
%
%   RUNNER = testrunner("minimal") creates a minimal runner with no plugins.
%   
%   RUNNER = testrunner("textoutput") creates a runner configured for text output.
% 
%   RUNNER = testrunner(..., LoggingLevel=LOGGINGLEVEL) creates 
%   a test runner that is configured to report logged diagnostics at or below 
%   the specified verbosity level LOGGINGLEVEL. Specify LOGGINGLEVEL as a numeric 
%   value (0, 1, 2, 3, or 4), a matlab.automation.Verbosity enumeration member, 
%   or a string or character vector corresponding to the name of a 
%   matlab.automation.Verbosity enumeration member.
% 
%   RUNNER = testrunner(..., OutputDetail=OUTPUTDETAIL) creates 
%   a test runner that is configured to display test run progress and event 
%   information with the amount of output detail specified by OUTPUTDETAIL. 
%   Specify OUTPUTDETAIL as a numeric value (0, 1, 2, 3, or 4), a 
%   matlab.automation.Verbosity enumeration member, or a string or character 
%   vector corresponding to the name of a matlab.automation.Verbosity enumeration 
%   member.
% 
%   Examples:
%
%       % Create a runner and run tests
%       runner = testrunner();
%       suite = testsuite("tMyTest");
%       runner.run(suite)
% 
%       % Create a runner with output detail "Verbose" and logging level "Verbose"
%       runner = testrunner(OutputDetail="Verbose", LoggingLevel="Verbose");
%       suite = testsuite("tMyTest");
%       runner.run(suite)
% 
%   See also:
%   runtests,
%   matlab.unittest.TestRunner.withNoPlugins,
%   matlab.unittest.TestRunner.withTextOutput

% Copyright 2020-2024 The MathWorks, Inc.    

    arguments
        runnerOption (1,1) string {mustBeMember(runnerOption,["minimal","textoutput"])} = "minimal";
        namedargs.OutputDetail (1,1) matlab.automation.Verbosity;
        namedargs.LoggingLevel (1,1) matlab.automation.Verbosity;
    end

    import matlab.unittest.TestRunner;

    args = namedargs2cell(namedargs);

    % TestRunner with default plugins is created by default
    if nargin == 0
        runner = TestRunner.withDefaultPlugins(args{:});
    else
        if runnerOption == "minimal"
            runner = TestRunner.withNoPlugins;
        elseif runnerOption == "textoutput"
            runner = TestRunner.withTextOutput(args{:});
        end
    end
end
