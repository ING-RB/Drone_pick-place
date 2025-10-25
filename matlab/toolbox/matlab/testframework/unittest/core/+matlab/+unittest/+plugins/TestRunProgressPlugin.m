classdef TestRunProgressPlugin < matlab.unittest.plugins.TestRunnerPlugin & ...
                                 matlab.unittest.internal.plugins.HasOutputStreamMixin &...
                                 matlab.unittest.plugins.Parallelizable
    % TestRunProgressPlugin - Factory for creating test run progress plugin.
    % 
    %   The TestRunProgressPlugin factory can be used to construct a plugin to
    %   show the progress of the test run to the Command Window.
    %
    %   TestRunProgressPlugin Methods:
    %       withVerbosity - Construct a TestRunProgressPlugin with a specified verbosity.
    
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties (Constant, Access=protected)
        Catalog = matlab.internal.Catalog('MATLAB:unittest:TestRunProgressPlugin');
    end
    
    properties(Constant, Hidden)
        ContentDelimiter = repmat('_', 1, 10);
    end
    
    properties(Dependent, Hidden, GetAccess=protected, SetAccess=immutable)
        Printer
    end
    
    properties(Access=private)
        InternalPrinter = [];
    end
    
    methods (Hidden, Sealed)
        function tf = supportsParallelThreadPool_(plugin)
            tf = plugin.OutputStream.supportsParallelThreadPool_;
        end
    end
    
    methods
        function printer = get.Printer(plugin)
            import matlab.unittest.internal.plugins.LinePrinter;
            printer = plugin.InternalPrinter;
            if isempty(printer)
                printer = LinePrinter(plugin.OutputStream);
                plugin.InternalPrinter = printer;
            end
        end
    end
    
    methods (Static)
        function plugin = withVerbosity(verbosity, stream)
            % withVerbosity - Construct a TestRunProgressPlugin with a specified verbosity
            %
            %   PLUGIN = TestRunProgressPlugin.withVerbosity(VERBOSITY) returns a
            %   plugin that prints test run progress at the specified verbosity level.
            %   VERBOSITY can be specified as a numeric value (0, 1, 2, 3, or 4),
            %   a matlab.unittest.Verbosity enumeration member, or a string or character 
            %   vector corresponding to the name of a matlab.unittest.Verbosity 
            %   enumeration member.
            %
            %   PLUGIN = TestRunProgressPlugin.withVerbosity(VERBOSITY, STREAM) creates
            %   a TestRunProgressPlugin and redirects all the text output produced to
            %   the OutputStream STREAM. If this is not supplied, a ToStandardOutput
            %   stream is used.
            %
            %   See also:
            %       matlab.unittest.Verbosity
            %       matlab.unittest.plugins.OutputStream
            
            arguments
                verbosity (1,1) matlab.unittest.Verbosity;
                stream = {};
            end
            
            import matlab.unittest.Verbosity;
            import matlab.unittest.plugins.TestRunProgressPlugin;
            import matlab.unittest.plugins.testrunprogress.TerseProgressPlugin;
            import matlab.unittest.plugins.testrunprogress.ConciseProgressPlugin;
            import matlab.unittest.plugins.testrunprogress.DetailedProgressPlugin;
            import matlab.unittest.plugins.testrunprogress.VerboseProgressPlugin;            
            import matlab.unittest.internal.validateVerbosityInput
            
            if nargin > 1
                stream = {stream};
            end
            
            if verbosity == Verbosity.None
                plugin = TestRunProgressPlugin(stream{:}); % acts as a no-op plugin
            elseif verbosity == Verbosity.Terse
                plugin = TerseProgressPlugin(stream{:});
            elseif verbosity == Verbosity.Concise
                plugin = ConciseProgressPlugin(stream{:});
            elseif verbosity == Verbosity.Detailed
                plugin = DetailedProgressPlugin(stream{:});
            elseif verbosity == Verbosity.Verbose
                plugin = VerboseProgressPlugin(stream{:});
            end
        end
    end
    
    methods (Access=protected)
        function plugin = TestRunProgressPlugin(varargin)
            plugin@matlab.unittest.internal.plugins.HasOutputStreamMixin(varargin{:});
        end
    end
end

% LocalWords:  testrunprogress
