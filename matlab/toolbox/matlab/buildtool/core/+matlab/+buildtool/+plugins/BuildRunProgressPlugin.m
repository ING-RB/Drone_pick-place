classdef (Hidden) BuildRunProgressPlugin < ...
        matlab.buildtool.plugins.BuildRunnerPlugin & ...
        matlab.buildtool.internal.plugins.HasOutputStreamMixin
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % BuildRunProgressPlugin - Plugin that reports build run progress
    %
    %   The matlab.buildtool.plugins.BuildRunProgressPlugin class creates a
    %   plugin that reports on build run progress.
    %
    %   BuildRunProgressPlugin methods:
    %      withVerbosity - Create plugin for specified verbosity
    
    %   Copyright 2021-2024 The MathWorks, Inc.
    
    properties (Constant, Access = protected)
        Catalog (1,1) matlab.internal.Catalog = matlab.internal.Catalog("MATLAB:buildtool:BuildRunProgressPlugin")
    end

    properties (Constant, Hidden)
        LinePrefix (1,1) string = "** "
    end
    
    properties (Dependent, Access = private)
        Printer (1,1) matlab.buildtool.internal.plugins.LinePrinter
    end
    
    properties (Access = private)
        InternalPrinter matlab.buildtool.internal.plugins.LinePrinter {mustBeScalarOrEmpty}
    end
    
    methods
        function printer = get.Printer(plugin)
            import matlab.buildtool.internal.plugins.LinePrinter;
            printer = plugin.InternalPrinter;
            if isempty(printer)
                printer = LinePrinter(plugin.OutputStream);
                plugin.InternalPrinter = printer;
            end
        end
    end
    
    methods (Static)
        function plugin = withVerbosity(verbosity, stream)
            % withVerbosity - Create plugin for specified verbosity
            %
            %    P = matlab.buildtool.plugins.withVerbosity(VERBOSITY) creates a
            %    plugin for the specified verbosity. You can specify VERBOSITY as an
            %    integer value, matlab.automation.Verbosity enumeration object, or
            %    string scalar or character vector corresponding to one of the
            %    predefined enumeration member names.
            %
            %    P = matlab.buildtool.plugins.withVerbosity(VERBOSITY,STREAM) redirects
            %    the text output to the output stream. STREAM must be a
            %    matlab.automation.streams.OutputStream scalar or empty.
            
            arguments
                verbosity (1,1) matlab.automation.Verbosity
                stream matlab.automation.streams.OutputStream {mustBeScalarOrEmpty} = matlab.automation.streams.OutputStream.empty()
            end
            
            import matlab.automation.Verbosity;
            import matlab.buildtool.plugins.BuildRunProgressPlugin;
            import matlab.buildtool.plugins.runprogress.TerseProgressPlugin;
            import matlab.buildtool.plugins.runprogress.ConciseProgressPlugin;
            import matlab.buildtool.plugins.runprogress.DetailedProgressPlugin;
            import matlab.buildtool.plugins.runprogress.VerboseProgressPlugin;
            
            if verbosity == Verbosity.None
                plugin = BuildRunProgressPlugin(stream);
            elseif verbosity == Verbosity.Terse
                plugin = TerseProgressPlugin(stream);
            elseif verbosity == Verbosity.Concise
                plugin = ConciseProgressPlugin(stream);
            elseif verbosity == Verbosity.Detailed
                plugin = DetailedProgressPlugin(stream);
            elseif verbosity == Verbosity.Verbose
                plugin = VerboseProgressPlugin(stream);
            end
        end
    end
    
    methods (Access = protected)
        function plugin = BuildRunProgressPlugin(varargin)
            plugin@matlab.buildtool.internal.plugins.HasOutputStreamMixin(varargin{:});
        end
    end

    methods (Sealed, Access = protected)
        function printEmptyLine(plugin)
            plugin.Printer.printEmptyLine();
        end
        
        function printLine(plugin, str)
            plugin.Printer.printPrefixedLine(plugin.LinePrefix, str);
        end

        function printIndentedLine(plugin, str, indentation)
            import matlab.automation.internal.diagnostics.indent;
            str = indent(str, indentation);
            plugin.Printer.printPrefixedLine(plugin.LinePrefix, str);
        end
    end
end

