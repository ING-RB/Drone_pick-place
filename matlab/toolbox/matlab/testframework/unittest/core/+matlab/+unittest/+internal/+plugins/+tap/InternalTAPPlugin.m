classdef(Hidden) InternalTAPPlugin < matlab.unittest.plugins.TAPPlugin
    % This class is undocumented and may change in a future release.
    
    % Copyright 2016-2020 The MathWorks, Inc.
    properties(SetAccess=immutable)
        % IncludePassingDiagnostics - Indicator if diagnostics are included for passing events
        %
        %   The IncludePassingDiagnostics property is a scalar logical (true or
        %   false) that indicates if diagnostics from passing events are included
        %   in the TAP stream.
        IncludePassingDiagnostics (1,1) logical = false;
    end
    
    properties(SetAccess=private)
        % LoggingLevel - Maximum verbosity level at which logged diagnostics are included
        %
        %   The LoggingLevel property is a scalar matlab.unittest.Verbosity
        %   instance. The plugin includes logged diagnostics in the TAP stream that
        %   are logged at or below the specified level.
        LoggingLevel (1,1) matlab.unittest.Verbosity = matlab.unittest.Verbosity.Terse;
        
        % OutputDetail - Verbosity level that controls amount of displayed information
        %
        %   The OutputDetail property is a scalar matlab.unittest.Verbosity
        %   instance that controls the amount of detail displayed in the TAP stream
        %   for passing, failing, and logged events.
        OutputDetail (1,1) matlab.unittest.Verbosity = matlab.unittest.Verbosity.Detailed;
    end
    
    properties(Hidden,Dependent,SetAccess=immutable)
        % Verbosity - Verbosity is not recommended. Use LoggingLevel instead.
        %
        %   The Verbosity property is an array of matlab.unittest.Verbosity
        %   instances. The plugin only displays diagnostics that are logged at a
        %   level listed in this array.
        Verbosity;
        
        % ExcludeLoggedDiagnostics - ExcludeLoggedDiagnostics is not recommended. Use LoggingLevel instead.
        %
        %   The ExcludeLoggedDiagnostics property is a scalar logical (true or
        %   false) that indicates if logged diagnostics are excluded from the TAP
        %   stream.
        ExcludeLoggedDiagnostics;
    end
    
    properties(Access=protected)
        EventRecordGatherer;
    end
    
    methods
        function levels = get.Verbosity(plugin)
            levels = matlab.unittest.Verbosity(1:double(plugin.LoggingLevel));
        end
        
        function bool = get.ExcludeLoggedDiagnostics(plugin)
            bool = plugin.LoggingLevel == matlab.unittest.Verbosity.None;
        end
    end
    
    methods(Access=protected)
        function plugin = InternalTAPPlugin(parser)
            plugin = plugin@matlab.unittest.plugins.TAPPlugin(parser.Results.OutputStream);
            
            plugin.IncludePassingDiagnostics = parser.Results.IncludingPassingDiagnostics;
            plugin.LoggingLevel = parser.Results.LoggingLevel;
            plugin.OutputDetail = parser.Results.OutputDetail;
            
            if ~ismember('Verbosity',parser.UsingDefaults) && ismember('LoggingLevel',parser.UsingDefaults)
                % Support old 'Verbosity' n/v pair if supplied, but only
                % apply it if 'LoggingLevel' n/v pair was not also supplied.
                plugin.LoggingLevel = parser.Results.Verbosity;
            end
            if parser.Results.ExcludingLoggedDiagnostics && ismember('LoggingLevel',parser.UsingDefaults)
                % Support old 'ExcludingLoggedDiagnostics' n/v pair if
                % supplied, but only apply it if 'LoggingLevel' n/v pair
                % was not also supplied.
                plugin.LoggingLevel = matlab.unittest.Verbosity.None;
            end
        end
    end
    
    methods(Access=protected, Abstract)
        printFormattedDiagnostics(plugin, eventRecords);
    end
    
    methods (Access=protected)
        function runTestSuite(plugin, pluginData)
            import matlab.unittest.internal.plugins.LinePrinter;
            plugin.Printer = LinePrinter(plugin.OutputStream);
            
            plugin.Printer.printLine(...
                sprintf('1..%d', numel(pluginData.TestSuite)));
            plugin.EventRecordGatherer = plugin.createEventRecordGatherer(pluginData);
            runTestSuite@matlab.unittest.plugins.TAPPlugin(plugin, pluginData);
        end
        
        function fixture = createSharedTestFixture(plugin, pluginData)
            fixture = createSharedTestFixture@matlab.unittest.plugins.TAPPlugin(plugin, pluginData);
            eventLocation = pluginData.Name;
            plugin.EventRecordGatherer.addListenersToSharedTestFixture(fixture, eventLocation,...
                pluginData.DetailsLocationProvider);
        end
        
        function testCase = createTestClassInstance(plugin, pluginData)
            testCase = createTestClassInstance@matlab.unittest.plugins.TAPPlugin(plugin, pluginData);
            eventLocation = pluginData.Name;
            plugin.EventRecordGatherer.addListenersToTestClassInstance(testCase, eventLocation,...
                pluginData.DetailsLocationProvider);
        end
        
        function testCase = createTestMethodInstance(plugin, pluginData)
            testCase = createTestMethodInstance@matlab.unittest.plugins.TAPPlugin(plugin, pluginData);
            eventLocation = pluginData.Name;
            plugin.EventRecordGatherer.addListenersToTestMethodInstance(testCase, eventLocation,...
                pluginData.DetailsLocationProvider);
        end
        
        function reportFinalizedResult(plugin, pluginData)
            result = pluginData.TestResult;
            plugin.printTAPResult(result, pluginData.Index, result.Name);
            
            eventRecords = plugin.EventRecordGatherer.EventRecordsCell{pluginData.Index};
            plugin.printFormattedDiagnostics(eventRecords);
            
            reportFinalizedResult@matlab.unittest.plugins.TAPPlugin(plugin, pluginData);
        end
    end
    
    methods(Access=private)
        function eventRecordGatherer = createEventRecordGatherer(plugin, pluginData)
            import matlab.unittest.Verbosity;
            import matlab.unittest.internal.plugins.EventRecordGatherer;
            eventRecordGatherer = EventRecordGatherer(numel(pluginData.TestSuite)); %#ok<CPROPLC>
            if plugin.IncludePassingDiagnostics
                eventRecordGatherer.addPassingEvents();
            end
            eventRecordGatherer.LoggingLevel = plugin.LoggingLevel;
            eventRecordGatherer.OutputDetail = plugin.OutputDetail;
        end
    end
end

% LocalWords:  YAML CPROPLC