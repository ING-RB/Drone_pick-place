classdef (Hidden) Loggable < handle & matlab.unittest.internal.DiagnosticDataMixin
    % This class is undocumented.
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    events (NotifyAccess=private)
        % DiagnosticLogged - Event triggered by calls to the log method.
        %   The DiagnosticLogged event provides a means to observe and react to
        %   calls to the log method. Callback functions listening to the event
        %   receive information about the time and function call stack leading up
        %   to the log method call as well as the user-supplied diagnostic message
        %   and the verbosity level.
        %
        %   See also: matlab.unittest.TestCase/log
        DiagnosticLogged
    end
    
    methods (Sealed)
        function log(loggable, varargin)
            % log - Record diagnostic information.
            %   The log method provides a means for tests to log information during the
            %   execution of a test. Logged messages are displayed only if the
            %   framework is configured to do so, for example, through the use of a
            %   matlab.unittest.plugins.LoggingPlugin instance.
            %
            %   log(TESTCASE, DIAG) logs the supplied diagnostic DIAG which can be
            %   specified as a string, a function handle that displays a string, or an
            %   instance of a matlab.unittest.diagnostics.Diagnostic.
            %
            %   log(TESTCASE, LEVEL, DIAG) logs the diagnostic at the specified LEVEL.
            %   LEVEL can be a numeric value (1, 2, 3, or 4), a
            %   matlab.unittest.Verbosity enumeration member, or a string or character
            %   vector corresponding to the name of a matlab.unittest.Verbosity
            %   enumeration member. When level is unspecified, the log method uses
            %   level Concise (2).
            %
            %   Examples:
            %
            %         % sampleLogTest.m
            %         function tests = sampleLogTest
            %         tests = functiontests(localfunctions);
            %
            %         function svdTest(testCase)
            %         log(testCase, 'Generating matrix.');
            %         m = rand(2000);
            %         % SVD may take some time to return
            %         log(testCase, 1, 'About to call SVD.');
            %         [U,S,V] = svd(m);
            %         log(testCase, 1, 'SVD finished.');
            %         verifyEqual(testCase, U*S*V', m, 'AbsTol',1e-6);
            %
            %       % Run the test. The default runner reports the
            %       % diagnostics at level 1.
            %       results = run(sampleLogTest);
            %
            %       % Construct a runner to report the diagnostics at levels 1 and 2.
            %       import matlab.unittest.TestRunner;
            %       import matlab.unittest.plugins.LoggingPlugin;
            %       runner = TestRunner.withNoPlugins;
            %       runner.addPlugin(LoggingPlugin.withVerbosity(2));
            %       results = runner.run(sampleLogTest);
            %
            %   See also: matlab.unittest.plugins.LoggingPlugin, matlab.unittest.Verbosity
            
            import matlab.unittest.Verbosity;
            import matlab.unittest.diagnostics.LoggedDiagnosticEventData;
            import matlab.unittest.internal.validateVerbosityInput

            % Before doing anything else, capture the current time to get
            % the best estimate of the time the log method was invoked.
            timestamp = datetime('now');
            
            narginchk(2,3);
            
            if nargin > 2
                level = varargin{1};
                level = validateVerbosityInput(level,'Verbosity');                
                validateattributes(level, {'matlab.unittest.Verbosity'}, {'>',0}, '', 'Verbosity');
            else
                % Default verbosity level is Concise
                level = Verbosity.Concise;
            end
            
            diag = varargin{end};
            stack = dbstack('-completenames');
            diagData = loggable.DiagnosticData;
            
            evd = LoggedDiagnosticEventData(level, diag, stack, timestamp, diagData);
            loggable.notify('DiagnosticLogged', evd);
        end
    end
end

% LocalWords:  completenames evd loggable
