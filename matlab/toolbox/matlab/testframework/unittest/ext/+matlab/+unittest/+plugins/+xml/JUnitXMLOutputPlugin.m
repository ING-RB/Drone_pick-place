classdef JUnitXMLOutputPlugin < matlab.unittest.plugins.XMLPlugin & ...
                                matlab.unittest.plugins.Parallelizable
    % JUnitXMLOutputPlugin - Plugin that produces JUnit Style XML Output
    %
    %   A JUnitXMLOutputPlugin is constructed only with the
    %   XMLPlugin.producingJUnitFormat method.
    %
    %   JUnitXMLOutputPlugin Properties:
    %       OutputDetail - Verbosity level that defines amount of displayed information
    %
    %   See also:
    %       matlab.unittest.plugins.XMLPlugin
    %       matlab.unittest.plugins.XMLPlugin.producingJUnitFormat
    
    % Copyright 2015-2023 The MathWorks, Inc.
    
    properties(Access=private)
        EventRecordGatherer;
        EventRecordFormatter;
        LastClassBoundaryMarker  
        LastSuiteName 
        FinalDocumentNode                % Top Level DOM Node
        DocumentNode;               % Suite level DOM Node
        TestSuiteNode;              % <testsuite> node
        
        NumTests;                   % Total number of tests in the testsuite
        NumFailures;                % Total number of failures in the test results
        NumErrors;                  % Total number of uncaught exceptions
        NumSkipped;                 % Total number of assumption failures
        TestSuiteDuration;          % Total duration of the testsuite        
    end
    
    properties(SetAccess=private)
        % OutputDetail - Verbosity level that defines amount of displayed information
        %
        %   The OutputDetail property is a scalar matlab.unittest.Verbosity
        %   instance that defines the amount of detail displayed in the output for
        %   failing events.
        OutputDetail (1,1) matlab.unittest.Verbosity = matlab.unittest.Verbosity.Detailed;
    end
    
    properties(Hidden, SetAccess=private)
        Filename;
    end
    
    methods
        function set.Filename(plugin, filename)
            import matlab.unittest.internal.newFileResolver;
            plugin.Filename = newFileResolver(filename);
        end
    end
    
    methods (Hidden, Access=protected)
        
        function runSession(plugin,pluginData)
            plugin.beforeRun(pluginData);
            finishUp = onCleanup(@() plugin.afterRun(pluginData));
            runSession@matlab.unittest.plugins.TestRunnerPlugin(plugin,pluginData);
        end
        
        function runTestSuite(plugin, pluginData)
            plugin.DocumentNode = plugin.createFreshDOMNode;
            clean = onCleanup(@()plugin.setFinalAttributesAndStoreData(pluginData));            
             
            plugin.EventRecordGatherer = plugin.createEventRecordGatherer(pluginData);
            plugin.runTestSuite@matlab.unittest.plugins.XMLPlugin(pluginData);
        end
        
        function fixture = createSharedTestFixture(plugin, pluginData)
            fixture = createSharedTestFixture@matlab.unittest.plugins.XMLPlugin(plugin, pluginData);
            eventLocation = pluginData.Name;
            plugin.EventRecordGatherer.addListenersToSharedTestFixture(fixture, eventLocation,...
                pluginData.DetailsLocationProvider);
        end
        
        function testCase = createTestClassInstance(plugin, pluginData)
            testCase = createTestClassInstance@matlab.unittest.plugins.XMLPlugin(plugin, pluginData);
            eventLocation = pluginData.Name;
            plugin.EventRecordGatherer.addListenersToTestClassInstance(testCase, eventLocation,...
             pluginData.DetailsLocationProvider);
        end
        
        function testCase = createTestMethodInstance(plugin, pluginData)
            testCase = createTestMethodInstance@matlab.unittest.plugins.XMLPlugin(plugin, pluginData);
            eventLocation = pluginData.Name;
            plugin.EventRecordGatherer.addListenersToTestMethodInstance(testCase, eventLocation,...
             pluginData.DetailsLocationProvider);
        end
        
        function reportFinalizedResult(plugin, pluginData)
            
            % Update the SuiteName to be the class name
            currentSuiteName = plugin.getNames(pluginData.TestSuite.Name);
            
            if ~any(pluginData.TestSuite.ClassBoundaryMarker == plugin.LastClassBoundaryMarker)|| ...
                    ~strcmp(currentSuiteName,plugin.LastSuiteName)
                
                % Update attributes on previous testsuite node and create a
                % new testsuite node for the next class.
                plugin.finalizeLastTestSuiteAttributes();
                plugin.createAndInitializeTestSuiteNode();

                plugin.LastClassBoundaryMarker = pluginData.TestSuite.ClassBoundaryMarker;
                plugin.LastSuiteName = currentSuiteName;
            end
            
            plugin.NumTests = plugin.NumTests + 1;
            
            thisResult = pluginData.TestResult;
            testcaseElement = plugin.createTestCaseNode(thisResult);

            if thisResult.FatalAssertionFailed
                plugin.addFailureNode(testcaseElement, 'FatalAssertionFailure', pluginData.Index);
            elseif thisResult.Errored
                plugin.addErrorNode(testcaseElement, pluginData.Index);
            elseif thisResult.AssertionFailed
                plugin.addFailureNode(testcaseElement, 'AssertionFailure', pluginData.Index);
            elseif thisResult.VerificationFailed
                plugin.addFailureNode(testcaseElement, 'VerificationFailure', pluginData.Index);
            elseif thisResult.AssumptionFailed
                plugin.addSkippedNode(testcaseElement, pluginData.Index);
            else
                plugin.TestSuiteNode.appendChild(testcaseElement);
            end
            
            plugin.TestSuiteDuration = plugin.TestSuiteDuration + thisResult.Duration;
            
            reportFinalizedResult@...
                matlab.unittest.plugins.TestRunnerPlugin(plugin,pluginData);
        end

        function reportFinalizedSuite(plugin, pluginData)
            % Get the master document;
            localNode = plugin.FinalDocumentNode.getFirstChild();
            defaultWorkerData_xmlString = writeToString(matlab.io.xml.dom.DOMWriter, plugin.createFreshDOMNode);

            % get the top-level "testsuites" node; one per file/document from the worker nodes
            workerData_xmlString = plugin.retrieveFrom(pluginData.CommunicationBuffer, DefaultData = defaultWorkerData_xmlString);
            workerData_Doc = parseString(matlab.io.xml.dom.Parser,workerData_xmlString);
            workerNode = workerData_Doc.getFirstChild();

            % add each "testsuite" node run in the group to the master document
            testsuiteList = workerNode.getChildNodes();
            for k=1:testsuiteList.getLength()
                testsuiteNode = testsuiteList.item(k-1);
                node = plugin.FinalDocumentNode.importNode(testsuiteNode);
                localNode.appendChild(node);
            end
            reportFinalizedSuite@...
                matlab.unittest.plugins.TestRunnerPlugin(plugin,pluginData);
        end

    end
    
    methods(Hidden, Access=?matlab.unittest.plugins.XMLPlugin)
        function plugin = JUnitXMLOutputPlugin(filename,varargin)
            parser = createParser();
            parser.parse(varargin{:});
            
            plugin = plugin@matlab.unittest.plugins.XMLPlugin;
            plugin.Filename = filename;
            plugin.OutputDetail = parser.Results.OutputDetail;
        end
    end
    
    methods(Access=private)
        function testcaseElement = createTestCaseNode(plugin, thisResult)
            testcaseElement = plugin.DocumentNode.createElement('testcase');
            [className,methodName] = plugin.getNames(thisResult.Name);
           
            testcaseElement.setAttribute('classname',className);
            testcaseElement.setAttribute('name',methodName);
            testcaseElement.setAttribute('time',num2str(thisResult.Duration));
        end

        function addFailureNode(plugin, testcaseElement, failureType, idx)
            failureNode = plugin.appendNodeToTestCaseElement(testcaseElement, 'failure', idx);
            failureNode.setAttribute('type', failureType);
            
            plugin.TestSuiteNode.appendChild(testcaseElement);
            plugin.NumFailures = plugin.NumFailures + 1;
        end
        
        function addSkippedNode(plugin, testcaseElement, idx)
            plugin.appendNodeToTestCaseElement(testcaseElement, 'skipped', idx);
            
            plugin.TestSuiteNode.appendChild(testcaseElement);
            plugin.NumSkipped = plugin.NumSkipped + 1;
        end
        
        function addErrorNode(plugin, testcaseElement, idx)
            plugin.appendNodeToTestCaseElement(testcaseElement, 'error', idx);
            plugin.TestSuiteNode.appendChild(testcaseElement);
            plugin.NumErrors = plugin.NumErrors + 1;
        end
        
        function childNode = appendNodeToTestCaseElement(plugin, testcaseElement, typeOfNode, idx)
            childNode = plugin.DocumentNode.createElement(typeOfNode);
            
            childNode.appendChild(plugin.createDiagnosticNode(idx));
            
            testcaseElement.appendChild(childNode);
        end
        
        function diagnosticsNode = createDiagnosticNode(plugin, idx)
            eventRecords = plugin.EventRecordGatherer.EventRecordsCell{idx};
            formattedDiagnostics = arrayfun(@plugin.getFormattedDiagnosticText,...
                eventRecords,'UniformOutput',false);
            diagnostics = strjoin(formattedDiagnostics, '');
            diagnostics = sanitize(diagnostics);
            diagnosticsNode = plugin.DocumentNode.createTextNode(diagnostics);
        end
        
        function finalizeLastTestSuiteAttributes(plugin)
            if ~isempty(plugin.LastClassBoundaryMarker)
                plugin.TestSuiteNode.setAttribute('name', plugin.LastSuiteName);
                plugin.TestSuiteNode.setAttribute('tests',    num2str(plugin.NumTests));
                plugin.TestSuiteNode.setAttribute('failures', num2str(plugin.NumFailures));
                plugin.TestSuiteNode.setAttribute('errors',   num2str(plugin.NumErrors));
                plugin.TestSuiteNode.setAttribute('skipped',  num2str(plugin.NumSkipped));
                plugin.TestSuiteNode.setAttribute('time',     num2str(plugin.TestSuiteDuration));
            end
        end
        
        function eventRecordGatherer = createEventRecordGatherer(plugin, pluginData)
            import matlab.unittest.internal.plugins.EventRecordGatherer;
            eventRecordGatherer = EventRecordGatherer(numel(pluginData.TestSuite)); %#ok<CPROPLC>
                        
            % XMLPlugin does not currently support logged event diagnostics
            eventRecordGatherer.LoggingLevel = matlab.unittest.Verbosity.None;
            
            eventRecordGatherer.OutputDetail = plugin.OutputDetail;
        end
        
        function formatter = createEventRecordFormatter(plugin)
            import matlab.unittest.internal.plugins.StandardEventRecordFormatter;
            formatter = StandardEventRecordFormatter();
            formatter.ReportVerbosity = plugin.OutputDetail;
        end
        
        function txt = getFormattedDiagnosticText(plugin, eventRecord)
            formattedStr = eventRecord.getFormattedReport(plugin.EventRecordFormatter);
            txt = char(formattedStr.Text); %Always get unenriched version
        end
        
        function setFinalAttributesAndStoreData(plugin, pluginData)
            if isempty(plugin.LastClassBoundaryMarker)
                plugin.createAndInitializeTestSuiteNode();
                plugin.LastClassBoundaryMarker = matlab.unittest.internal.ClassBoundaryMarker;
            end
            plugin.finalizeLastTestSuiteAttributes();
           
            xmlString = writeToString(matlab.io.xml.dom.DOMWriter,plugin.DocumentNode);
            plugin.storeIn(pluginData.CommunicationBuffer,xmlString); % This is to ensure that store is called in case of errors/fatalAssertions during runTestSuite.
        end
        
        function print(plugin)
            matlab.unittest.internal.writeXML(plugin.Filename, plugin.FinalDocumentNode);
        end
        
        function createAndInitializeTestSuiteNode(plugin)
            docRootNode = plugin.DocumentNode.getDocumentElement;
            plugin.TestSuiteNode = plugin.DocumentNode.createElement('testsuite');
            docRootNode.appendChild(plugin.TestSuiteNode);
            
            plugin.NumTests    = 0;
            plugin.NumFailures = 0;
            plugin.NumErrors   = 0;
            plugin.NumSkipped  = 0;
            plugin.TestSuiteDuration = 0;
        end
        
        function [className,methodName] = getNames(~,testName)
            nameParts = strsplit(testName, '/');
            methodName = nameParts{2};
            className = nameParts{1};
        end
        
        function setDefaultPropertyValues(plugin)
            plugin.LastSuiteName = '';
            plugin.LastClassBoundaryMarker = matlab.unittest.internal.ClassBoundaryMarker.empty;
        end
        
        function beforeRun(plugin, ~)
            import matlab.unittest.internal.validateFileCanBeCreated;
            
            validateFileCanBeCreated(plugin.Filename);
            plugin.setDefaultPropertyValues;
            plugin.EventRecordFormatter = plugin.createEventRecordFormatter();
            
            % Create the testsuites and the first testsuite element
            plugin.FinalDocumentNode = plugin.createFreshDOMNode ;
        end   
        
        function domNode = createFreshDOMNode(~)
            domNode =  matlab.io.xml.dom.Document('testsuites');
        end
        
        function afterRun(plugin, ~)
            plugin.print();
        end
        
    end
end

function parser = createParser()
import matlab.unittest.Verbosity;
parser = matlab.unittest.internal.strictInputParser();
parser.addParameter('OutputDetail', Verbosity.Detailed, @validateVerbosity);
end

function validateVerbosity(verbosity)
validateattributes(verbosity,{'numeric','string','char','matlab.unittest.Verbosity'},{'nonempty','row'});
if ~ischar(verbosity)
    validateattributes(verbosity, {'numeric','string','matlab.unittest.Verbosity'}, {'scalar'});
end
matlab.unittest.Verbosity(verbosity); % Validate that a value is valid
end

function text = sanitize(text)
arguments
    text (1,:) char;
end
text(~isAcceptableXMLCharacter(text)) = []; % remove invalid characters
end

function tf = isAcceptableXMLCharacter(c)
% Determine whether a character is an acceptable XML character. Reference:
% https://www.w3.org/TR/xml/#charsets

tf = ...
    c == 0x9 | ...
    c == 0xA | ...
    c == 0xD | ...
    (c >= 0x20 & c <= 0xD7FF) | ...
    (c >= 0xE000 & c <= 0xFFFD);
% 0x10000 through 0x10FFFF is also valid but out of range for char
end

% LocalWords:  testsuite testsuites CPROPLC unenriched Parallelizable formatter dom FFFD
