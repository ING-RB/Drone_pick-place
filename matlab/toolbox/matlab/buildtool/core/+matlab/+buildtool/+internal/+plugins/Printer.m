classdef Printer
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2021-2023 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
        OutputStream matlab.automation.streams.OutputStream {mustBeScalarOrEmpty}
    end
    
    methods
        function printer = Printer(outputStream)
            arguments
                outputStream (1,1) matlab.automation.streams.OutputStream = matlab.automation.streams.ToStandardOutput()
            end
            printer.OutputStream = outputStream;
        end
    end
    
    methods (Sealed)
        function print(printer, arg)
            arguments
                printer (1,1) matlab.buildtool.internal.plugins.Printer
            end
            arguments (Repeating)
                arg
            end
            printer.OutputStream.print(arg{:});
        end

        function printFormatted(printer, formattableString)
            arguments
                printer (1,1) matlab.buildtool.internal.plugins.Printer
                formattableString (1,1) matlab.automation.internal.diagnostics.FormattableString
            end
            printer.OutputStream.printFormatted(formattableString);
        end
    end
end

