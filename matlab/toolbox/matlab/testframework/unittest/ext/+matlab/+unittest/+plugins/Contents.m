% matlab.unittest.plugins
%
%   Plugins are used to customize or extend the TestRunner.
%
%
% Fundamental Plugin Related Interfaces
% -----------------------------------------
%   TestRunnerPlugin - Interface for extending the TestRunner.
%   QualifyingPlugin - Interface for plugins that perform qualification.
%   Parallelizable   - Interface for plugins that support running tests in parallel.
%
%
% Plugin Implementations
% --------------------------
%
%   Diagnostic & Progress Information:
%       DiagnosticsOutputPlugin    - Report diagnostics to an output stream.
%       DiagnosticsRecordingPlugin - Record diagnostics on test results.
%       LoggingPlugin              - Report diagnostic messages created by the log method.
%       TestRunProgressPlugin      - Report the progress of the test run.
%
%   Debugging & Qualification:
%       DiagnosticsValidationPlugin - Help validate diagnostic code.
%       FailOnWarningsPlugin        - Report warnings issued by tests.
%       StopOnFailuresPlugin        - Debug test failures.
%
%   Output Formats & Continuous Integration:
%       TAPPlugin - Produce a TAP Stream.
%       XMLPlugin - Produce test results in XML format.
%
%   Reporting:
%       CodeCoveragePlugin - Produce a code coverage report.
%       TestReportPlugin   - Produce a report of the test results in '.docx', '.html', or '.pdf' format.
%__________________________________________________________________________

%   Copyright 2015-2018 The MathWorks, Inc.

