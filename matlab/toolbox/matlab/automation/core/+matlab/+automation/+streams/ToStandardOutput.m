classdef ToStandardOutput < matlab.automation.streams.OutputStream
    %ToStandardOutput  Display text information to the screen
    %   STREAM = ToStandardOutput creates an OutputStream instance that
    %   prints to the screen.  
    %   
    %   When used with the unit testing framework, for example, it can be
    %   specified in a variety of plugins that can be added to a test runner.
    %
    %   Note: Many plugins that accept OutputStreams use a ToStandardOutput stream
    %   as their default stream. Because of this, if a stream is not supplied
    %   to these plugins, their text is sent to the screen.
    %
    %   Examples:
    %       import matlab.unittest.TestRunner
    %       import matlab.unittest.TestSuite
    %       import matlab.unittest.plugins.DiagnosticsOutputPlugin
    %       import matlab.automation.streams.ToStandardOutput
    %
    %       % Create a TestSuite array
    %       suite   = TestSuite.fromClass(?mypackage.MyTestClass);
    %       % Create a test runner with no plugins
    %       runner = TestRunner.withNoPlugins;
    %
    %       % Create a DiagnosticsOutputPlugin, explicitly specifying that
    %       % its output should go to the screen.
    %       plugin = DiagnosticsOutputPlugin(ToStandardOutput);
    %
    %       % Add the plugin to the test runner and run the suite. Observe
    %       % that only failures produce any screen output.
    %       runner.addPlugin(plugin);
    %       result = runner.run(suite);
    %
    %   See also: fprintf, OutputStream, matlab.unittest.plugins, 
    %             matlab.automation.streams
    
    % Copyright 2012-2022 The MathWorks, Inc.
    
    methods
        function print(~, formatSpec, args)
            arguments
                ~
                formatSpec (1,1) string
            end
            arguments (Repeating)
                args
            end

            fprintf(1, formatSpec, args{:});
        end
    end
    
    methods (Hidden)
        function printFormatted(stream, formattableStr)
            import matlab.internal.display.commandWindowWidth;
            stream.print('%s', char(wrap(formattableStr, commandWindowWidth)));
        end
        
        function tf = supportsParallelThreadPool_(~)
            tf = true;
        end
    end
end

% LocalWords:  mypackage formattable
