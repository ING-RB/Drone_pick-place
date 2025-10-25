classdef TAPPlugin < matlab.unittest.plugins.TestRunnerPlugin & ...
                     matlab.unittest.internal.plugins.HasOutputStreamMixin & ...
                     matlab.unittest.plugins.Parallelizable
    % TAPPlugin - Plugin that produces a TAP Stream
    %
    %   The TAPPlugin allows one to configure a TestRunner to produce output
    %   conforming to the Test Anything Protocol (TAP). When the test output is
    %   produced using this format, MATLAB Unit Test results can be integrated
    %   into other third party systems that recognize the TAP protocol. For
    %   example, using this plugin MATLAB tests can be integrated into
    %   continuous integration systems like <a href="http://jenkins-ci.org/">Jenkins</a>TM or <a href="http://www.jetbrains.com/teamcity">TeamCity</a>(R).
    %
    %   TAPPlugin Methods:
    %       producingOriginalFormat - Construct a plugin that produces the original TAP format.
    %       producingVersion13      - Construct a plugin that produces the Version 13 TAP format.
    %
    %   Examples:
    %       import matlab.unittest.TestRunner;
    %       import matlab.unittest.TestSuite;
    %       import matlab.unittest.plugins.TAPPlugin;
    %       import matlab.unittest.plugins.ToFile;
    %
    %       % Create a TestSuite array
    %       suite   = TestSuite.fromClass(?mynamespace.MyTestClass);
    %       % Create a test runner
    %       runner = TestRunner.withTextOutput;
    %
    %       % Add a TAPPlugin to the TestRunner
    %       tapFile = 'MyTAPOutput.tap';
    %       plugin = TAPPlugin.producingOriginalFormat(ToFile(tapFile));
    %       runner.addPlugin(plugin);
    %
    %       result = runner.run(suite);
    %
    %       disp(fileread(tapFile));
    %
    %   See also:
    %       matlab.unittest.plugins.TestRunnerPlugin
    %       matlab.unittest.plugins.ToFile
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    properties (Hidden, SetAccess=private, GetAccess=protected)
        BailOutMessage (1,1) matlab.unittest.internal.diagnostics.FormattableString = "";
        BailedOut (1,1) logical = false;
    end
    
    properties(Hidden, Access=protected)
        Printer %set inside of runTestSuite method of each subclass
    end
    
    methods (Hidden, Sealed)
        function tf = supportsParallelThreadPool_(plugin)
            tf = plugin.OutputStream.supportsParallelThreadPool_;
        end
    end
    
    methods(Static)
        function plugin = producingOriginalFormat(varargin)
            % producingOriginalFormat - Construct a plugin that produces the original TAP format
            %
            %   PLUGIN = TAPPlugin.producingOriginalFormat() returns a plugin that
            %   produces text output in the form of the original Test Anything Protocol
            %   format (version 12). This output is printed to the MATLAB Command
            %   Window. Any other output also produced to the Command Window can
            %   invalidate the TAP stream. This can be avoided by sending the TAP
            %   output to another OutputStream as shown below.
            %
            %   PLUGIN = TAPPlugin.producingOriginalFormat(STREAM) creates a plugin
            %   and redirects all the text output produced to the OutputStream STREAM.
            %   If this is not supplied, a ToStandardOutput stream is used.
            %
            %   PLUGIN = TAPPlugin.producingOriginalFormat(...,'IncludingPassingDiagnostics',true)
            %   creates a TAPPlugin that includes diagnostics from passing events.
            %
            %   PLUGIN = TAPPlugin.producingOriginalFormat(...,'LoggingLevel',LOGGINGLEVEL)
            %   creates a TAPPlugin that includes logged diagnostics that are logged at
            %   or below LOGGINGLEVEL. LOGGINGLEVEL is specified as a
            %   matlab.unittest.Verbosity enumeration object. To exclude logged
            %   diagnostics, specify LOGGINGLEVEL as Verbosity.None. By default,
            %   LOGGINGLEVEL is Verbosity.Terse.
            %
            %   PLUGIN = TAPPlugin.producingOriginalFormat(...,'OutputDetail',OUTPUTDETAIL)
            %   creates a TAPPlugin that displays events with the amount of output
            %   detail specified by OUTPUTDETAIL. OUTPUTDETAIL is specified as a
            %   matlab.unittest.Verbosity enumeration object. By default, events are
            %   displayed at the Verbosity.Detailed level.
            %
            %   Examples:
            %       import matlab.unittest.plugins.TAPPlugin;
            %       import matlab.unittest.plugins.ToFile;
            %
            %       % Create a TAP plugin that sends TAP Version 12 Output
            %       % to the MATLAB Command Window
            %       plugin = TAPPlugin.producingOriginalFormat;
            %
            %       % Create a TAP plugin that sends TAP Version 12 Output to a file
            %       plugin = TAPPlugin.producingOriginalFormat(ToFile('MyTAPStream.tap'));
            %
            %       % Create a TAP plugin that includes passing diagnostics
            %       % in TAP Version 12 Output
            %       plugin = TAPPlugin.producingOriginalFormat('IncludingPassingDiagnostics', true);
            %
            %       % Create a TAP plugin that includes diagnostics logged
            %       % at and below Concise level in TAP Version 12 Output
            %       import matlab.unittest.Verbosity;
            %       plugin = TAPPlugin.producingOriginalFormat('LoggingLevel', Verbosity.Concise);
            %
            %   See also:
            %       matlab.unittest.Verbosity
            %       matlab.unittest.plugins.OutputStream
            %       matlab.unittest.plugins.ToFile
            %       matlab.unittest.plugins.TAPPlugin.producingVersion13
            
            parser = createParser();
            parser.parse(varargin{:});
            plugin = matlab.unittest.plugins.tap.TAPOriginalFormatPlugin(parser);
        end
        
        function plugin = producingVersion13(varargin)
            % producingVersion13 - Construct a plugin that produces the Version 13 TAP format
            %
            %   PLUGIN = TAPPlugin.producingVersion13() returns a plugin that
            %   produces text output in the form of the Test Anything Protocol
            %   format (version 13) and includes diagnostics in a YAML block.
            %   This output is displayed in the MATLAB Command Window. Other
            %   output sent to the Command Window can invalidate the TAP stream.
            %   To avoid this, redirect the TAP output to another OutputStream.
            %
            %   PLUGIN = TAPPlugin.producingVersion13(STREAM) creates a plugin
            %   and redirects all the text output produced to the OutputStream STREAM.
            %   If STREAM is not supplied, a ToStandardOutput stream is used.
            %
            %   PLUGIN = TAPPlugin.producingVersion13(...,'IncludingPassingDiagnostics',true)
            %   creates a TAPPlugin that includes diagnostics from passing events.
            %
            %   PLUGIN = TAPPlugin.producingVersion13(...,'LoggingLevel',LOGGINGLEVEL)
            %   creates a TAPPlugin that includes logged diagnostics that are logged at
            %   or below LOGGINGLEVEL. LOGGINGLEVEL is specified as a
            %   matlab.unittest.Verbosity enumeration object. To exclude logged
            %   diagnostics, specify LOGGINGLEVEL as Verbosity.None. By default,
            %   LOGGINGLEVEL is Verbosity.Terse.
            %
            %   PLUGIN = TAPPlugin.producingVersion13(...,'OutputDetail',OUTPUTDETAIL)
            %   creates a TAPPlugin that displays events with the amount of output
            %   detail specified by OUTPUTDETAIL. OUTPUTDETAIL is specified as a
            %   matlab.unittest.Verbosity enumeration object. By default, events are
            %   displayed at the Verbosity.Detailed level.
            %
            %   Examples:
            %       import matlab.unittest.plugins.TAPPlugin;
            %       import matlab.unittest.plugins.ToFile;
            %
            %       % Create a TAP plugin that sends TAP Version 13 Output
            %       % to the MATLAB Command Window
            %       plugin = TAPPlugin.producingVersion13;
            %
            %       % Create a TAP plugin that sends TAP Version 13 Output to a file
            %       plugin = TAPPlugin.producingVersion13(ToFile('MyTAPStream.tap'));
            %
            %       % Create a TAP plugin that includes passing diagnostics
            %       % in TAP Version 13 Output
            %       plugin = TAPPlugin.producingVersion13('IncludingPassingDiagnostics', true);
            %
            %       % Create a TAP plugin that includes diagnostics logged
            %       % at and below Concise level in TAP Version 13 Output
            %       import matlab.unittest.Verbosity;
            %       plugin = TAPPlugin.producingVersion13('LoggingLevel', Verbosity.Concise);
            %
            %   See also:
            %       matlab.unittest.Verbosity
            %       matlab.unittest.plugins.OutputStream
            %       matlab.unittest.plugins.ToFile
            %       matlab.unittest.plugins.TAPPlugin.producingOriginalFormat
            
            parser = createParser();
            parser.addParameter('GroupedByFile', false, @(v) validateattributes(v, {'logical'}, {'scalar'}));
            parser.addParameter('StallFile', '', @ischar);
            parser.addParameter("Clock_", @datetime);
            parser.parse(varargin{:});
            
            if ~parser.Results.GroupedByFile
                plugin = matlab.unittest.plugins.tap.TAPVersion13Plugin(parser);
            else
                plugin = matlab.unittest.internal.plugins.tap.TAPTestFilePlugin( ...
                    parser.Results.StallFile, parser.Results.Clock_, parser.Results.OutputStream);
            end
        end
    end
    
    methods(Access=protected)
        function plugin = TAPPlugin(outputStream)
            plugin = plugin@matlab.unittest.internal.plugins.HasOutputStreamMixin(outputStream);
        end
    end
    
    
    methods (Hidden, Access=protected)
        function runTestSuite(plugin, pluginData)
            plugin.BailOutMessage = "";
            plugin.BailedOut = false;
            printBailOut = matlab.unittest.internal.Teardownable;
            printBailOut.addTeardown(@()plugin.Printer.printFormatted(appendNewlineIfNonempty(plugin.BailOutMessage)));
            plugin.runTestSuite@matlab.unittest.plugins.TestRunnerPlugin(pluginData);
        end
        
        function fixture = createSharedTestFixture(plugin, pluginData)
            fixture = createSharedTestFixture@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            eventLocation = pluginData.Name;
            fixture.addlistener('FatalAssertionFailed', @(obj, evd) plugin.bailOut(obj, evd, eventLocation));
        end
        
        function testCase = createTestClassInstance(plugin, pluginData)
            testCase = createTestClassInstance@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            eventLocation = pluginData.Name;
            testCase.addlistener('FatalAssertionFailed', @(obj, evd) plugin.bailOut(obj, evd, eventLocation));
        end
        
        function testCase = createTestMethodInstance(plugin, pluginData)
            testCase = createTestMethodInstance@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            eventLocation = pluginData.Name;
            testCase.addlistener('FatalAssertionFailed', @(obj, evd) plugin.bailOut(obj, evd, eventLocation));
        end

        function tapLine = printTAPResult(plugin, result, count, name)
            not = '';
            skip = '';
            if any([result.Failed])
                % Handle failures
                not = 'not ';
            elseif all([result.Incomplete])
                % Handle filtered tests
                skip = ' # SKIP ';
            end
            tapLine = sprintf('%sok %d - %s%s', ...
                not, count, name, skip);
            plugin.Printer.printLine(tapLine);
        end
    end
    
    methods(Access=private)
        function bailOut(plugin, ~, evd, eventLocation)
            if plugin.BailedOut
                % Only report on the first fatal assertion.
                return;
            end
            
            % "Bail out!" is a part of the TAP specification and should not be translated.
            bailOutStr = "Bail out! " + eventLocation;
            
            formattableResults = evd.TestDiagnosticResultsStore.getFormattableResults();
            formattableStrings = formattableResults.toFormattableStrings();
            
            plugin.BailOutMessage = formattableStrings.applyToFirstNonempty( ...
                @(str)bailOutStr + ": " + regexprep(str, "\n.*", ""), bailOutStr);
            
            plugin.BailedOut = true;
        end
    end
end

function parser = createParser()
import matlab.unittest.Verbosity;
import matlab.unittest.plugins.ToStandardOutput;
parser = matlab.unittest.internal.strictInputParser();
parser.addOptional('OutputStream', ToStandardOutput, @(stream)validateattributes(...
    stream, {'matlab.unittest.plugins.OutputStream'}, ...
    {'scalar'}, '', 'stream'));
parser.addParameter('IncludingPassingDiagnostics', false, ...
    @(x)validateattributes(x,{'logical'},{'scalar'}));
parser.addParameter('LoggingLevel', Verbosity.Terse, @validateVerbosity);
parser.addParameter('OutputDetail', Verbosity.Detailed, @validateVerbosity);
parser.addParameter('Verbosity', Verbosity.Terse, @validateVerbosity);
parser.addParameter('ExcludingLoggedDiagnostics',false, ...
    @(x)validateattributes(x,{'logical'},{'scalar'}));
end

function validateVerbosity(verbosity)
validateattributes(verbosity,{'numeric','string','char','matlab.unittest.Verbosity'},{'nonempty','row'});
if ~ischar(verbosity)
    validateattributes(verbosity, {'numeric','string','matlab.unittest.Verbosity'}, {'scalar'});
end
matlab.unittest.Verbosity(verbosity); % Validate that a value is valid
end

% LocalWords:  mynamespace jenkins ci jetbrains teamcity evd sok YAML Formattable Parallelizable
% LocalWords:  strlength unittest plugins LOGGINGLEVEL OUTPUTDETAIL formattable Teardownable
