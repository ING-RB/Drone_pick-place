classdef LinePrinter < matlab.buildtool.internal.plugins.Printer
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2021-2023 The MathWorks, Inc.
    
    methods
        function printer = LinePrinter(varargin)
            printer = printer@matlab.buildtool.internal.plugins.Printer(varargin{:});
        end
    end
    
    methods (Sealed)
        function printEmptyLine(printer)
            printer.printLine("");
        end
        
        function printLine(printer, str)
            arguments
                printer (1,1) matlab.buildtool.internal.plugins.LinePrinter
                str
            end
            if ischar(str) || isstring(str)
                printer.print("%s\n", str);
            else
                printer.printFormatted(str + newline());
            end
        end

        function printPrefixedLine(printer, prefix, str)
            arguments
                printer (1,1) matlab.buildtool.internal.plugins.LinePrinter
                prefix (1,1) string
                str (1,1) string
            end
            str = join(prefix + splitlines(str), newline());
            printer.printLine(str);
        end
    end
end

