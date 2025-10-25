classdef LoggingPlugin < matlab.unittest.plugins.TestRunnerPlugin & ...
                         matlab.unittest.internal.plugins.HasOutputStreamMixin & ...
                         matlab.unittest.plugins.Parallelizable
    % LoggingPlugin - Report diagnostic messages created by the log method.
    %   The LoggingPlugin provides a means to report diagnostic messages that
    %   are created by calls to the matlab.unittest.TestCase log method.
    %   Through the withVerbosity static method, the plugin can be configured
    %   to respond to messages of a particular verbosity. The withVerbosity
    %   method also accepts a number of name/value pairs for configuring the
    %   format for reporting logged messages.
    %
    %   LoggingPlugin properties:
    %       Verbosity      - Levels supported by this plugin instance.
    %       Description    - Logged diagnostic message description.
    %       HideLevel      - Boolean that indicates whether the level is printed.
    %       HideTimestamp  - Boolean that indicates whether the timestamp is printed.
    %       NumStackFrames - Number of stack frames to print.
    %
    %   LoggingPlugin methods:
    %       withVerbosity - Construct a LoggingPlugin for messages of the specified verbosity.
    %
    %   See also: matlab.unittest.TestCase/log, matlab.unittest.fixtures.Fixture/log, matlab.unittest.Verbosity
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    properties (SetAccess=private)
        % Verbosity - Levels supported by this plugin instance.
        %   The Verbosity property is an array of matlab.unittest.Verbosity
        %   instances. The plugin only reacts to diagnostics that are logged at a
        %   level listed in this array.
        Verbosity (1,:) matlab.unittest.Verbosity;
        
        % Description - Logged diagnostic message description.
        %   The Description property is a string or character vector which is
        %   printed alongside each logged diagnostic message. By default, the
        %   Description "Diagnostic logged" is used.
        Description;
        
        % HideLevel - Boolean that indicates whether the level is printed.
        %   The HideLevel property is a logical value which determines whether or
        %   not the verbosity level of the message is printed alongside each logged
        %   diagnostic. By default, HideLevel is false meaning that the
        %   verbosity level is printed.
        HideLevel;
        
        % HideTimestamp - Boolean that indicates whether the timestamp is printed.
        %   The HideTimestamp property is a logical value which determines whether
        %   or not the time when the logged message was generated is printed
        %   alongside each logged diagnostic. By default, HideTimestamp is false
        %   meaning that the timestamp is printed.
        HideTimestamp;
        
        % NumStackFrames - Number of stack frames to print.
        %   The NumStackFrames property is an integer that dictates the number of
        %   stack frames to print after each logged diagnostic message. By default,
        %   NumStackFrames is zero, meaning that no stack information is printed.
        %   NumStackFrames can be set to Inf to print all available stack frames.
        NumStackFrames;
    end
    
    properties (Access=private)
        ExcludeLowerLevels;
        TimestampFormatter;
    end
    
    properties (Constant, Access=private)
        Parser = createParser;
    end
    
    properties(GetAccess=private,SetAccess=immutable)
        LinePrinter;
    end
    
    methods (Hidden, Sealed)
        function tf = supportsParallelThreadPool_(plugin)
            tf = plugin.OutputStream.supportsParallelThreadPool_;
        end
    end
    
    methods (Static)
        function plugin = withVerbosity(verbosity, varargin)
            % withVerbosity - Construct a LoggingPlugin for messages of the specified verbosity.
            %   PLUGIN = LoggingPlugin.withVerbosity(VERBOSITY) constructs a LoggingPlugin that
            %   reacts to messages logged at VERBOSITY or lower. VERBOSITY can be
            %   specified as a numeric value (1, 2, 3, or 4), a matlab.unittest.Verbosity 
            %   enumeration member, or a string or character vector corresponding to the name 
            %   of a matlab.unittest.Verbosity enumeration member.
            %
            %   PLUGIN = LoggingPlugin.withVerbosity(VERBOSITY, STREAM) creates a
            %   LoggingPlugin and redirects all the text output produced to the
            %   OutputStream STREAM. If this is not supplied, a ToStandardOutput stream
            %   is used.
            %
            %   PLUGIN = withVerbosity(VERBOSITY, NAME, VALUE, ...) constructs a
            %   LoggingPlugin with one or more Name/Value pairs. Specify any of the
            %   following Name/Value pairs:
            %
            %   * ExcludingLowerLevels - Boolean that indicates whether the plugin
            %                            reacts to messages logged at levels lower than
            %                            VERBOSITY. When false (default), the plugin
            %                            reacts to all messages logged at VERBOSITY or
            %                            lower. When true, the plugin only reacts to
            %                            messages logged at VERBOSITY.
            %   * Description          - String or character vector to print alongside each
            %                            logged diagnostic.
            %                            By default, the plugin uses "Diagnostic logged" as
            %                            the Description.
            %   * HideLevel            - Boolean that indicates whether the level is printed.
            %                            By default, the plugin displays the verbosity level.
            %   * HideTimestamp        - Boolean that indicates whether the timestamp is
            %                            printed. By default, the plugin displays the
            %                            timestamp.
            %   * NumStackFrames       - Number of stack frames to print. By default, the
            %                            plugin displays zero stack frames.
            %
            %   See also: OutputStream, ToStandardOutput
            
            import matlab.unittest.plugins.LoggingPlugin;
            
            verbosity = validateVerbosity(verbosity);
            
            streamArg = {};
            if mod(nargin,2)==0
                streamArg = varargin(1);
                varargin(1) = [];
            end
            plugin = LoggingPlugin(streamArg{:});
            
            parser = LoggingPlugin.Parser;
            parser.parse(varargin{:});
            plugin.ExcludeLowerLevels = parser.Results.ExcludingLowerLevels;
            plugin.Description = char(parser.Results.Description);
            plugin.NumStackFrames = parser.Results.NumStackFrames;
            plugin.HideLevel = parser.Results.HideLevel;
            plugin.HideTimestamp = parser.Results.HideTimestamp;
            plugin.TimestampFormatter = parser.Results.TimestampFormatter_;
            
            if plugin.ExcludeLowerLevels
                % The plugin reacts to only the specified level
                plugin.Verbosity = verbosity;
            else
                % The plugin reacts to the specified level and all lower levels
                plugin.Verbosity = 1:double(verbosity);
            end
        end
    end
        
    methods (Hidden, Access=protected)
        function fixture = createSharedTestFixture(plugin, pluginData)
            fixture = createSharedTestFixture@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            plugin.registerDiagnosticLoggedCallback(fixture);
        end
        
        function testCase = createTestClassInstance(plugin, pluginData)
            testCase = createTestClassInstance@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            plugin.registerDiagnosticLoggedCallback(testCase);
        end
        
        function testCase = createTestMethodInstance(plugin, pluginData)
            testCase = createTestMethodInstance@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            plugin.registerDiagnosticLoggedCallback(testCase);
        end

        function registerDiagnosticLoggedCallback(plugin, content)
            content.addlistener('DiagnosticLogged', @plugin.processDiagnosticLoggedEvent);
        end
    end
    
    methods (Access=private)
        function plugin = LoggingPlugin(varargin)
            % Private constructor. Must use static methods to create an instance.
            import matlab.unittest.internal.plugins.LinePrinter;
            plugin = plugin@matlab.unittest.internal.plugins.HasOutputStreamMixin(varargin{:});
            plugin.LinePrinter = LinePrinter(plugin.OutputStream);
        end
        
        function processDiagnosticLoggedEvent(plugin,~,eventData)
            import matlab.unittest.internal.eventrecords.LoggedDiagnosticEventRecord;
            % Print only those diagnostics that are logged at a level that the plugin reacts to.
            if any(plugin.Verbosity == eventData.Verbosity)
                plugin.printLoggedDiagnostic(eventData);
            end
        end
        
        function printLoggedDiagnostic(plugin, eventData)
            import matlab.unittest.internal.diagnostics.createStackInfo;
            
            description = plugin.Description;
            hideTimestamp = plugin.HideTimestamp;
            hideLevel = plugin.HideLevel;
            numStackFrames = plugin.NumStackFrames;
            timestamp = eventData.Timestamp;
            formattableDiagnosticResults = eventData.DiagnosticResultsStore.getFormattableResults();
            diagnosticStrings = formattableDiagnosticResults.toFormattableStrings();
            stack = eventData.Stack(1:min(end,numStackFrames));
            numDiags = numel(diagnosticStrings);
            
            reportTxt = description;
            if ~hideTimestamp
                reportTxt = sprintf('%s(%s)',...
                    addOptionalSuffix(reportTxt,' '),...
                    plugin.TimestampFormatter(timestamp));
            end
            if numDiags > 0
                reportTxt = addOptionalSuffix(reportTxt,':');
            end
            
            if ~hideLevel
                [~, strs] = enumeration('matlab.unittest.Verbosity');
                maxVerbosityNameLength = max(strlength(string(strs)));
                verbosityTxt = char(eventData.Verbosity);
                reportTxt = sprintf('%s[%s]%s',...
                    repmat(' ',1, maxVerbosityNameLength-numel(verbosityTxt)),...
                    verbosityTxt,...
                    addOptionalPrefix(reportTxt,' '));
            end
            
            printer = plugin.LinePrinter;
            
            if numDiags == 0
                printer.printLine(reportTxt);
            elseif numDiags == 1 && ~contains(char(diagnosticStrings), newline) %keep as single line
                printer.printLine(sprintf('%s%s',...
                    addOptionalSuffix(reportTxt,' '),...
                    diagnosticStrings));
            else
                printer.printLine(reportTxt);
                for k = 1:numDiags
                    printer.printLine(diagnosticStrings(k));
                end
                printer.printEmptyLine();
            end
            
            if ~isempty(stack)
                printer.printIndentedLine(getString(message('MATLAB:unittest:LoggingPlugin:StackInformation')));
                printer.printIndentedLine(createStackInfo(stack));
                printer.printEmptyLine();
            end
        end
    end
end

function parser = createParser()
parser = matlab.unittest.internal.strictInputParser;
parser.addParameter('Description', getString(message('MATLAB:unittest:LoggingPlugin:DefaultDescription')), ...
    @matlab.unittest.internal.mustBeTextScalar);
parser.addParameter('ExcludingLowerLevels', false, ...
    @(x) validateattributes(x, {'logical'}, {'scalar'}));
parser.addParameter('NumStackFrames', 0, ...
    @(x) validateNumStackFrames(x));
parser.addParameter('HideLevel', false, ...
    @(x) validateattributes(x, {'logical'}, {'scalar'}));
parser.addParameter('HideTimestamp', false, ...
    @(x) validateattributes(x, {'logical'}, {'scalar'}));
parser.addParameter("TimestampFormatter_", @(ts)datestr(ts, "yyyy-mm-ddTHH:MM:SS"));
end

function validVerbosity = validateVerbosity(verbosity)
import matlab.unittest.internal.validateVerbosityInput
validVerbosity = validateVerbosityInput(verbosity,'Verbosity');
end

function bool = validateNumStackFrames(num)
validateattributes(num, {'numeric'}, {'scalar', 'real', 'nonnan', 'nonnegative'});
% NumStackFrames must also be integer-valued or Inf
bool = isequal(num, round(num));
end

function txt = addOptionalPrefix(txt,prefix)
if ~isempty(txt)
    txt = sprintf('%s%s',prefix,txt);
end
end

function txt = addOptionalSuffix(txt,suffix)
if ~isempty(txt)
    txt = sprintf('%s%s',txt,suffix);
end
end

% LocalWords:  yyyy THH Parallelizable eventrecords Diags strs strlength
