classdef(Sealed) TAPVersion13Plugin < matlab.unittest.internal.plugins.tap.InternalTAPPlugin
    % TAPVersion13Plugin - Plugin that produces the Version 13 TAP format
    %
    %   A TAPVersion13Plugin is constructed only with the
    %   TAPPlugin.producingVersion13 method.
    %
    %   TAPVersion13Plugin Properties:
    %       IncludePassingDiagnostics - Indicator if diagnostics are included for passing events
    %       LoggingLevel              - Maximum verbosity level at which logged diagnostics are included
    %       OutputDetail              - Verbosity level that defines amount of displayed information
    %
    %   See also:
    %       matlab.unittest.plugins.TAPPlugin
    %       matlab.unittest.plugins.TAPPlugin.producingVersion13
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    methods(Hidden, Access={?matlab.unittest.plugins.TAPPlugin})
        function plugin = TAPVersion13Plugin(parser)
            plugin@matlab.unittest.internal.plugins.tap.InternalTAPPlugin(parser);
        end
    end
    
    properties(Access=private, Constant)
        HeaderCatalog = matlab.internal.Catalog('MATLAB:unittest:TAPVersion13YAMLDiagnostic');
    end
    
    methods (Hidden, Access=protected)
        
        function runTestSuite(plugin, pluginData)
            import matlab.unittest.internal.plugins.LinePrinter;
            plugin.Printer = LinePrinter(plugin.OutputStream);
            
            plugin.Printer.printLine('TAP version 13');
            runTestSuite@matlab.unittest.internal.plugins.tap.InternalTAPPlugin(plugin, pluginData);
        end

        function printFormattedDiagnostics(plugin, eventRecords)
            if isempty(eventRecords)
                return;
            end
            
            plugin.printIndentedLine('---');
            if numel(eventRecords) == 1
                plugin.printSingleEventRecord(eventRecords);
            else
                plugin.printMultipleEventRecords(eventRecords);
            end
            plugin.printIndentedLine('...');
        end
    end
    
    methods(Access=private)
        function printSingleEventRecord(plugin, eventRecord)
            eventHeader = plugin.HeaderCatalog.getString('EventHeader');
            plugin.printIndentedLine(eventHeader);
            plugin.printDetailsOfEventRecord(eventRecord);
        end
        
        function printMultipleEventRecords(plugin, eventRecords)
            for k = 1:numel(eventRecords)
                eventHeader = plugin.HeaderCatalog.getString('NumberedEventHeader', k);
                plugin.printIndentedLine(sprintf('%s', eventHeader));
                plugin.printDetailsOfEventRecord(eventRecords(k));
            end
        end
        
        function printDetailsOfEventRecord(plugin, eventRecord)
            formatter = matlab.unittest.internal.plugins.tap.TAPVersion13Formatter;
            str = eventRecord.getFormattedReport(formatter);
            str = str.indent("        ");
            plugin.Printer.printFormatted(str + newline);
        end
        
        function printIndentedLine(plugin, varargin)
            plugin.Printer.printIndentedLine(varargin{:});
        end
    end
end

% LocalWords:  YAML formatter unittest plugins
