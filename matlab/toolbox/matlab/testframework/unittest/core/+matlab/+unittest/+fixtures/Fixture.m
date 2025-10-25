classdef Fixture < matlab.unittest.internal.TestContent & matlab.mixin.Heterogeneous
    % Fixture - Interface for test fixtures.
    %
    %   Fixtures provide a means for configuring environment state required for
    %   tests. Classes which derive from the Fixture interface must provide a
    %   setup method which performs the changes to the environment. A fixture
    %   should restore the environment to its initial state when it is torn
    %   down. This can be done using addTeardown in the setup method or by
    %   overriding the teardown method which, by default, does nothing.
    %
    %   Subclasses can set the SetupDescription and TeardownDescription
    %   properties in their constructors to provide descriptions for the
    %   actions performed by the setup and teardown methods, respectively.
    %
    %   A class which derives from Fixture must override isCompatible if its
    %   constructor accepts any input arguments. Fixture subclasses use this
    %   method to define a notion of interchangeability. Two fixture instances
    %   of the same class are considered to be interchangeable if the
    %   isCompatible method returns true. When running multiple TestCase
    %   classes as a single suite, the Test Runner will tear down and set up
    %   shared test fixtures of the same class if isCompatible returns false
    %   (that is, the fixture will not be shared).
    %
    %   A Fixture subclass can override needsReset to report on the 
    %   validity of its instances when used as shared test fixtures. A shared 
    %   test fixture is valid if the needsReset method returns false. When 
    %   running multiple TestCase classes as a single suite, the Test Runner 
    %   will tear down a shared test fixture and set it up for the subsequent 
    %   classes if needsReset returns true (that is, the shared fixture is no 
    %   longer valid).
    %
    %   Fixture events:
    %       AssertionFailed      - Event triggered upon a failing assertion
    %       AssertionPassed      - Event triggered upon a passing assertion
    %       FatalAssertionFailed - Event triggered upon a failing fatal assertion
    %       FatalAssertionPassed - Event triggered upon a passing fatal assertion
    %       AssumptionFailed     - Event triggered upon a failing assumption
    %       AssumptionPassed     - Event triggered upon a passing assumption
    %       ExceptionThrown      - Event triggered when an exception is thrown
    %       DiagnosticLogged     - Event triggered by calls to the log method
    %
    %   Fixture properties:
    %       SetupDescription    - Description of fixture setup actions
    %       TeardownDescription - Description of fixture teardown actions
    %
    %   Fixture methods:
    %       Fixture - Class constructor
    %       addTeardown - Dynamically add a teardown routine
    %       applyFixture - Use another fixture within a fixture
    %       log - Record diagnostic information
    %       setup - Set up fixture
    %       teardown - Tear down fixture
    %       onFailure - Dynamically add diagnostics for test failures
    %       isCompatible - Determine whether two fixtures are interchangeable
    %       needsReset - Determine whether environment state is maintained
    %       assertFail - Produce an unconditional assertion failure
    %       assertThat - Assert that a value meets a given constraint
    %       assertTrue - Assert that a value is true
    %       assertFalse - Assert that a value is false
    %       assertEqual - Assert the equality of a value to an expected
    %       assertNotEqual - Assert a value is not equal to an expected
    %       assertSameHandle - Assert two values are handles to the same instance
    %       assertNotSameHandle - Assert a value isn't a handle to some instance
    %       assertError - Assert a function throws a specific exception
    %       assertWarning - Assert a function issues a specific warning
    %       assertWarningFree - Assert a function issues no warnings
    %       assertEmpty - Assert a value is empty
    %       assertNotEmpty - Assert a value is not empty
    %       assertSize - Assert a value has an expected size
    %       assertLength - Assert a value has an expected length
    %       assertNumElements - Assert a value has an expected element count
    %       assertGreaterThan - Assert a value is larger than some floor
    %       assertGreaterThanOrEqual - Assert a value is equal or larger than some floor
    %       assertLessThan - Assert a value is less than some ceiling
    %       assertLessThanOrEqual - Assert a value is equal or smaller than some ceiling
    %       assertReturnsTrue - Assert a function returns true when evaluated
    %       assertInstanceOf - Assert a value "isa" expected type
    %       assertClass - Assert the exact class of some value
    %       assertSubstring - Assert a string contains an expected string
    %       assertMatches - Assert a string matches a regular expression
    %       assumeFail - Produce an unconditional assumption failure
    %       assumeThat - Assume that a value meets a given constraint
    %       assumeTrue - Assume that a value is true
    %       assumeFalse - Assume that a value is false
    %       assumeEqual - Assume the equality of a value to an expected
    %       assumeNotEqual - Assume a value is not equal to an expected
    %       assumeSameHandle - Assume two values are handles to the same instance
    %       assumeNotSameHandle - Assume a value isn't a handle to some instance
    %       assumeError - Assume a function throws a specific exception
    %       assumeWarning - Assume a function issues a specific warning
    %       assumeWarningFree - Assume a function issues no warnings
    %       assumeEmpty - Assume a value is empty
    %       assumeNotEmpty - Assume a value is not empty
    %       assumeSize - Assume a value has an expected size
    %       assumeLength - Assume a value has an expected length
    %       assumeNumElements - Assume a value has an expected element count
    %       assumeGreaterThan - Assume a value is larger than some floor
    %       assumeGreaterThanOrEqual - Assume a value is equal or larger than some floor
    %       assumeLessThan - Assume a value is less than some ceiling
    %       assumeLessThanOrEqual - Assume a value is equal or smaller than some ceiling
    %       assumeReturnsTrue - Assume a function returns true when evaluated
    %       assumeInstanceOf - Assume a value "isa" expected type
    %       assumeClass - Assume the exact class of some value
    %       assumeSubstring - Assume a string contains an expected string
    %       assumeMatches - Assume a string matches a regular expression
    %       fatalAssertFail - Produce an unconditional fatal assertion failure
    %       fatalAssertThat - Fatally assert that a value meets a given constraint
    %       fatalAssertTrue - Fatally assert that a value is true
    %       fatalAssertFalse - Fatally assert that a value is false
    %       fatalAssertEqual - Fatally assert the equality of a value to an expected
    %       fatalAssertNotEqual - Fatally assert a value is not equal to an expected
    %       fatalAssertSameHandle - Fatally assert two values are handles to the same instance
    %       fatalAssertNotSameHandle - Fatally assert a value isn't a handle to some instance
    %       fatalAssertError - Fatally assert a function throws a specific exception
    %       fatalAssertWarning - Fatally assert a function issues a specific warning
    %       fatalAssertWarningFree - Fatally assert a function issues no warnings
    %       fatalAssertEmpty - Fatally assert a value is empty
    %       fatalAssertNotEmpty - Fatally assert a value is not empty
    %       fatalAssertSize - Fatally assert a value has an expected size
    %       fatalAssertLength - Fatally assert a value has an expected length
    %       fatalAssertNumElements - Fatally assert a value has an expected element count
    %       fatalAssertGreaterThan - Fatally assert a value is larger than some floor
    %       fatalAssertGreaterThanOrEqual - Fatally assert a value is equal or larger than some floor
    %       fatalAssertLessThan - Fatally assert a value is less than some ceiling
    %       fatalAssertLessThanOrEqual - Fatally assert a value is equal or smaller than some ceiling
    %       fatalAssertReturnsTrue - Fatally assert a function returns true when evaluated
    %       fatalAssertInstanceOf - Fatally assert a value "isa" expected type
    %       fatalAssertClass - Fatally assert the exact class of some value
    %       fatalAssertSubstring - Fatally assert a string contains an expected string
    %       fatalAssertMatches - Fatally assert a string matches a regular expression
    %
    %   See also
    %       matlab.unittest.TestCase/applyFixture
    %       matlab.unittest.TestCase/getSharedTestFixtures
    
    % Copyright 2013-2024 The MathWorks, Inc.
    
    properties (SetAccess=protected)
        % SetupDescription - Description of fixture setup actions
        %   The SetupDescription property is a string which describes the
        %   actions the fixture performs when its setup method is invoked.
        SetupDescription = '';
        
        % TeardownDescription - Description of fixture teardown actions
        %   The TeardownDescription property is a string which describes the
        %   actions the fixture performs when its teardown method is invoked.
        TeardownDescription = '';
    end
    
    properties (SetAccess=immutable, GetAccess=private)
        FixtureClassName
    end
    
    properties(SetAccess=private,GetAccess={?matlab.unittest.TestRunner},Dependent)
        Qualifiable
    end

    properties(Transient, Access=private)
        AppliedFixtures = matlab.unittest.fixtures.Fixture.empty;
    end

    properties (Access=private)
        QualifiableReference
        ValidQualifiable
        OnFailureDelegationFcn = [];
    end
    
    properties (Hidden, Transient, SetAccess=private, GetAccess=?matlab.unittest.internal.FixtureRole)
        OnFailureTasks = matlab.unittest.internal.Task.empty;
    end
    
    events (NotifyAccess=private)
        % DiagnosticLogged - Event triggered by calls to the log method.
        %   The DiagnosticLogged event provides a means to observe and react to
        %   calls to the log method. Callback functions listening to the event
        %   receive information about the time and function call stack leading up
        %   to the log method call as well as the user-supplied diagnostic message
        %   and the verbosity level.
        %
        %   See also: matlab.unittest.fixtures.Fixture/log
        DiagnosticLogged
    end
    
    % Qualification events
    events (NotifyAccess=private)
        % AssertionPassed - Event triggered upon a passing assertion.
        %   The AssertionPassed event provides a means to observe and react
        %   to passing assertions on fixture. Callback functions listening
        %   to the event receive information about the passing
        %   qualification including the actual value, constraint applied,
        %   diagnostic result and stack information in the form of
        %   QualificationEventData
        %
        %   See also: matlab.unittest.qualifications.QualificationEventData
        AssertionPassed;
        
        % AssertionFailed - Event triggered upon a failing assertion.
        %   The AssertionFailed event provides a means to observe and react
        %   to failing assertions on fixture. Callback functions listening
        %   to the event receive information about the failing
        %   qualification including the actual value, constraint applied,
        %   diagnostic result and stack information in the form of
        %   QualificationEventData
        %
        %   See also: matlab.unittest.qualifications.QualificationEventData
        AssertionFailed;
        
        % AssumptionPassed - Event triggered upon a passing assumption.
        %   The AssumptionPassed event provides a means to observe and
        %   react to passing assumptions on fixture. Callback functions
        %   listening to the event receive information about the passing
        %   qualification including the actual value, constraint applied,
        %   diagnostic result and stack information in the form of
        %   QualificationEventData
        %
        %   See also: matlab.unittest.qualifications.QualificationEventData
        AssumptionPassed;
        
        % AssumptionFailed - Event triggered upon a failing assumption.
        %   The AssumptionFailed event provides a means to observe and
        %   react to failing assumptions on fixture. Callback functions
        %   listening to the event receive information about the failing
        %   qualification including the actual value, constraint applied,
        %   diagnostic result and stack information in the form of
        %   QualificationEventData
        %
        %   See also: matlab.unittest.qualifications.QualificationEventData
        AssumptionFailed;
        
        % FatalAssertionPassed - Event triggered upon a passing fatal assertion.
        %   The FatalAssertionPassed event provides a means to observe and
        %   react to passing fatal assertions on fixture. Callback
        %   functions listening to the event receive information about the
        %   passing qualification including the actual value, constraint
        %   applied, diagnostic result and stack information in the form of
        %   QualificationEventData
        %
        %   See also: matlab.unittest.qualifications.QualificationEventData
        FatalAssertionPassed;
        
        % FatalAssertionFailed - Event triggered upon a failing fatal assertion.
        %   The FatalAssertionFailed event provides a means to observe and
        %   react to failing fatal assertions on fixture. Callback
        %   functions listening to the event receive information about the
        %   failing qualification including the actual value, constraint
        %   applied, diagnostic result and stack information in the form of
        %   QualificationEventData
        %
        %   See also: matlab.unittest.qualifications.QualificationEventData
        FatalAssertionFailed;
    end
    
    properties (Hidden, SetAccess=protected)
        FolderScope matlab.unittest.internal.fixtures.FolderScope = ...
            matlab.unittest.internal.fixtures.FolderScope.Across;
    end
    
    methods(Sealed, Access=?matlab.unittest.TestRunner)
        function disableQualifications_(fixture)
            fixture.ValidQualifiable = fixture.QualifiableReference;
            fixture.Qualifiable = matlab.unittest.internal.qualifications.InvalidQualifiable();
        end
        
        function enableQualifications_(fixture)
            fixture.QualifiableReference = fixture.ValidQualifiable;
        end
    end
        
    methods (Abstract)
        % setup - Set up fixture.
        %
        %   setup(FIXTURE) is called to set up the test fixture and perform
        %   the necessary environment modifications.
        setup(fixture)
    end
    
    methods(Hidden, Sealed, Access=?matlab.unittest.internal.FixtureRole)
        function resetState = needsReset_(fixture)
            resetState = fixture.needsReset;
        end
    end
    
    methods
        function fixture = Fixture
            % Fixture - Class constructor.
            %
            %   FIXTURE = Fixture constructs a fixture instance and returns it as FIXTURE.
            
            import matlab.unittest.internal.qualifications.ThrowingQualifiable;
            import matlab.unittest.internal.getSimpleParentName;
            
            fixture.FixtureClassName = class(fixture);
            fixtureMetaclass = metaclass(fixture);
            derivedClassConstructor = fixtureMetaclass.MethodList.findobj( ...
                'Name',getSimpleParentName(fixture.FixtureClassName));
            
            if ~isempty(derivedClassConstructor.InputNames)
                % If the derived class's constructor accepts any inputs,
                % the derived class must override isCompatible.
                
                isCompatibleMethod = fixtureMetaclass.MethodList.findobj( ...
                    'Name','isCompatible');
                
                if strcmp(isCompatibleMethod.DefiningClass.Name, 'matlab.unittest.fixtures.Fixture')
                    error(message('MATLAB:unittest:Fixture:MustOverrideIsCompatible', ...
                        fixture.FixtureClassName));
                end
            end
            
            fixture.Qualifiable = ThrowingQualifiable;
        end

        function teardown(~)
            % teardown - Tear down fixture.
            %
            %   teardown(FIXTURE) is called to tear down the test fixture
            %   and restore the environment to its original state.
        end

        function delete(fixture)
            fixture.AppliedFixtures(:) = [];
        end

        function set.SetupDescription(fixture, str)
            import matlab.unittest.internal.mustBeTextScalar;
            mustBeTextScalar(str,'SetupDescription');
            fixture.SetupDescription = char(str);
        end
        
        function set.TeardownDescription(fixture, str)
            import matlab.unittest.internal.mustBeTextScalar;
            mustBeTextScalar(str,'TeardownDescription');
            fixture.TeardownDescription = char(str);
        end

        function val = get.Qualifiable(fixture)
            val = fixture.QualifiableReference.Handle;
        end

        function set.Qualifiable(fixture, value)
            fixture.QualifiableReference = matlab.unittest.internal.qualifications.StrongQualifiableReference(value);
        end
    end
    
    methods(Sealed)
        function varargout = applyAndRun(suppliedFixture, functionHandle)
            % applyAndRun - Execute a function within the context of a fixture
            %
            %   applyAndRun(fixture, @functionHandle) runs the function specified by
            %   functionHandle within the context provided by the fixture object. This
            %   allows for the function to be executed with certain preconditions and
            %   environment settings that are established by the fixture.
            %
            %   The fixture object must be an instance of a class that sets up the
            %   desired environment and provides a teardown method to clean up
            %   after the function execution.
            %
            %   The functionHandle argument must be a handle to a function.
            %
            %   Example usage:
            %   --------------
            %   % Assume a fixture class named MyFixture exists, and it has methods
            %   % for setting up a test environment and tearing it down after tests.
            %
            %   % Define a function that performs operations
            %   function myTestFunction()
            %       disp('Function code executed within the fixture context.');
            %   end
            %
            %   % Create an instance of MyTestFixture
            %   myFixture = MyFixture();
            %
            %   % Run the function within the context of myFixture
            %   myFixture.applyAndRun(@myTestFunction);
            %   % OR
            %   applyAndRun(myFixture, @myTestFunction);
            %
            %   % Output:
            %   % Outputs from Function code executed within the fixture context.
            %
            %
            %   See also:
            %   ---------
            %   function_handle

            arguments
                suppliedFixture (1,:) matlab.unittest.fixtures.Fixture
                functionHandle (1,1) function_handle
            end
            argout = nargout;
            function evaluateFunctionHandle(~)
                [varargout{1:argout}] = functionHandle();
            end
            runner = matlab.unittest.TestRunner.withNoPlugins;
            runner.addPlugin(matlab.unittest.plugins.DiagnosticsRecordingPlugin('LoggingLevel',matlab.unittest.Verbosity.None));

            resultPlugin = matlab.unittest.internal.plugins.TestResultPlugin;
            runner.addPlugin(resultPlugin);
            
            fixture = matlab.unittest.internal.fixtures.ApplyAndRunFixture(suppliedFixture);

            suite = matlab.unittest.Test.fromFunctions({@evaluateFunctionHandle}, 'matlab');
            suite = suite.addExternalFixtures(fixture);
            
            runnerException = matlab.unittest.internal.NullException;
            try
                runner.run(suite);
            catch runnerException
            end

            incompleteRecords = resultPlugin.Results.Details.DiagnosticRecord.selectIncomplete;
            if isempty(incompleteRecords)
                runnerException.rethrow;
            else
                exception = fixture.getFormattedException(incompleteRecords);
                exception.throw;
            end
        end
    end

    methods (Access=protected)
        function bool = isCompatible(~,~)
            % isCompatible - Determine whether two fixtures are interchangeable.
            %
            %   isCompatible(FIXTURE, OTHERFIXTURE) returns true if FIXTURE and
            %   OTHERFIXTURE perform the same changes to the environment. Otherwise,
            %   the method returns false. Subclasses should override this method if it
            %   is possible to configure the fixture in different ways that perform
            %   different environment changes. isCompatible should only be called with
            %   two instances that are of the same class.
            
            bool = true;
        end
        
        % Override copyElement method:
        function newCopy = copyElement(original)
            newCopy = copyElement@matlab.unittest.internal.TestContent(original);
            newCopy.Qualifiable = copy(newCopy.Qualifiable);
        end
        
        function resetStatus = needsReset(~)
            % needsReset - Determine whether environment state is maintained.
            %
            %   needsReset(SHAREDTESTFIXTURE) returns false if the test environment 
            %   state, configured by SHAREDTESTFIXTURE, is maintained throughout 
            %   the test session. If the environment state is not maintained, the 
            %   method returns true. Fixture subclasses can override the needsReset method 
            %   to check the validity of shared test fixtures. needsReset implementations 
            %   must not reset the SHAREDTESTFIXTURE or perform qualifications. 
            %   The method accepts a single fixture instance and returns a logical scalar.
            resetStatus = false;
        end
    end

    methods(Hidden)
        function bool = supportsParallel_(~)
            bool = true;
        end
    end
    
    methods (Hidden, Sealed, Static, Access=protected)
        function instance = getDefaultScalarElement
            instance = matlab.unittest.fixtures.EmptyFixture;
        end
    end

    methods (Hidden, Sealed)
        function setupAppliedFixture_(appliedFixture, contentAppliedTo)
            import matlab.unittest.internal.TestContentDelegateSubstitutor;
            
            if appliedFixture.hasBeenApplied
                error(message("MATLAB:unittest:Fixture:UnableToApplyFixture"));
            end
            
            contentAppliedToWeakRef = matlab.lang.WeakReference(contentAppliedTo);
            % Forward onFailure calls to the applied fixture to the content
            % it is applied to.
            appliedFixture.OnFailureDelegationFcn = @(~, varargin)contentAppliedToWeakRef.Handle.onFailure(varargin{:});
            
            % Provide the content the fixture is applied to as the Fixture's
            % qualifiable so that qualification failures in the applied fixture are
            % reported on the content it's applied to. Transfer the teardown
            % delegate and the OnFailureTasks so that teardown content and
            % the onFailure diagnostics added to the applied fixture are
            % registered on the content it's applied to.
            appliedFixture.QualifiableReference = contentAppliedToWeakRef;
            appliedFixture.Qualifiable.onFailure(appliedFixture.OnFailureTasks);
            TestContentDelegateSubstitutor.transferTeardownDelegate(contentAppliedTo, appliedFixture);
            
            % Teardown should be registered after setup is invoked, and
            % even if setup throws an exception and does not complete.
            registerTeardown = onCleanup(@()contentAppliedTo.addTeardown(@teardownAppliedFixture, appliedFixture));
            appliedFixture.setup;
        end

        function [fixtures, I, J] = getUniqueFixtureInstances(fixtures)
            compareFcn = @matlab.unittest.internal.StrictHandleComparer.eq;
            [fixtures, I, J] = uniqueFixtures(fixtures, compareFcn);
        end
        
        function [fixtures, I, J] = getUniqueTestFixtures(fixtures)
            compareFcn = @(fA,others)arrayfun(@(fB)areFixturesEquivalent(fA,fB), others);
            [fixtures, I, J] = uniqueFixtures(fixtures, compareFcn);
        end
        
        function bool = containsEquivalentFixture(fixtureArray, otherFixture)
            bool = false;
            for fixture = fixtureArray
                if areFixturesEquivalent(fixture, otherFixture)
                    bool = true;
                    break;
                end
            end
        end
        
        function mask = isOnPath(fixtures)
            import matlab.unittest.internal.whichFile;
            mask = cellfun(@(name) ~isempty(whichFile(name)), {fixtures.FixtureClassName});
        end

        function addPostFailureEventCallback_(fixture, fcn)
            fixture.Qualifiable.addPostFailureEventCallback_(fcn);
        end

        function matchingFixtures = getFixturesByClassName(fixtures, desiredClassName)
            matchingFixtures = fixtures(strcmp({fixtures.FixtureClassName}, desiredClassName));
        end
    end
    
    methods (Access=private)
        function el = getForwardingAssertionListeners(fixture)
            el = [fixture.getForwardingListener('AssertionPassed'), fixture.getForwardingListener('AssertionFailed')];
        end
        
        function el = getForwardingAssumptionListeners(fixture)
            el = [fixture.getForwardingListener('AssumptionPassed'), fixture.getForwardingListener('AssumptionFailed')];
        end
        
        function el = getForwardingFatalAssertionListeners(fixture)
            el = [fixture.getForwardingListener('FatalAssertionPassed'), fixture.getForwardingListener('FatalAssertionFailed')];
        end
        
        function el = getForwardingLogListener(fixture)
            el = fixture.getForwardingListener('DiagnosticLogged');
        end
        
        function el = getForwardingListener(fixture, eventName)
            el = event.listener.empty;
            if event.hasListener(fixture, eventName)
                el = event.listener(fixture.Qualifiable, eventName, @(~,evd)fixture.notify(eventName,copy(evd)));
            end
        end
        
        function bool = hasBeenApplied(fixture)
            bool = class(fixture.Qualifiable) ~= "matlab.unittest.internal.qualifications.ThrowingQualifiable";
        end
    end

    methods(Access=private, Sealed)
        function exception = getFormattedException(~, diagnosticRecords)
            exception = MException(message("MATLAB:unittest:Fixture:ApplyAndRunFailed"));
            totalRecords = numel(diagnosticRecords);
            multipleRecords = totalRecords > 1;
            for currentIndex = 1:totalRecords
                eventRecord = diagnosticRecords(currentIndex).toEventRecord;
                if multipleRecords
                    exception_ = eventRecord.getFormattedException(currentIndex);
                else
                    exception_ = eventRecord.getFormattedException;
                end
                exception = exception.addCause(exception_);
            end
        end
    end

    methods (Hidden, Sealed, Access=?matlab.unittest.internal.plugins.plugindata.FixtureQualificationAdapter)
        function assumeThatQualificationAdapter_(varargin)
            assumeThat(varargin{:});
        end

        function assertThatQualificationAdapter_(varargin)
            assertThat(varargin{:});
        end

        function fatalAssertThatQualificationAdapter_(varargin)
            fatalAssertThat(varargin{:});
        end
    end
    
    methods (Sealed, Access=protected)
        function appliedFixture = applyFixture(fixture, otherFixture)
            % applyFixture - Use another fixture within a fixture.
            %
            %   applyFixture(FIXTURE, OTHERFIXTURE) sets up OTHERFIXTURE for use with
            %   FIXTURE. This method can be called inside the setup method of one
            %   fixture in order to delegate work to a second fixture.
            %
            %   By using applyFixture, the life-cycle of OTHERFIXTURE is tied to that
            %   of FIXTURE such that when the framework tears down FIXTURE, it also
            %   tears down OTHERFIXTURE.
            %
            %   Example:
            %
            %       classdef TemporaryTextFileFixture < matlab.unittest.fixtures.Fixture
            %           % TemporaryTextFileFixture - Fixture to create a temporary text file
            %
            %           properties (SetAccess=private)
            %               File
            %           end
            %
            %           methods
            %               function setup(fixture)
            %                   import matlab.unittest.fixtures.TemporaryFolderFixture;
            %
            %                   % Delegate to TemporaryFolderFixture to create a temporary folder
            %                   tempFolder = fixture.applyFixture(TemporaryFolderFixture);
            %
            %                   fixture.File = fullfile(tempFolder.Folder, 'file.txt');
            %                   fid = fopen(fixture.File, 'wt');
            %                   fclose(fid);
            %               end
            %           end
            %       end
            %
            %
            %   See also: matlab.unittest.TestCase/applyFixture
            
            validateattributes(otherFixture, {'matlab.unittest.fixtures.Fixture'}, {'scalar'}, '', 'otherFixture');
            fixture.AppliedFixtures(end+1) = otherFixture;
            otherFixture.setupAppliedFixture_(fixture);
            if nargout > 0
                appliedFixture = otherFixture;
            end
        end
        
        function log(fixture, varargin)
            % log - Record diagnostic information.
            %   The log method provides a means for fixtures to log information during
            %   the execution of a setup and teardown routines. Logged messages are
            %   displayed only if the framework is configured to do so, for example,
            %   through the use of a matlab.unittest.plugins.LoggingPlugin instance.
            %
            %   FIXTURE.log(DIAG) logs the supplied diagnostic DIAG which can be
            %   specified as a string, a function handle that displays a string, or an
            %   instance of a matlab.unittest.diagnostics.Diagnostic.
            %
            %   FIXTURE.log(LEVEL, DIAG) logs the diagnostic at the specified LEVEL.
            %   LEVEL can be either a numeric value (1, 2, 3, or 4) or a value from the
            %   matlab.unittest.Verbosity enumeration. When level is unspecified, the
            %   log method uses level Concise (2).
            %
            %   See also: matlab.unittest.plugins.LoggingPlugin, matlab.unittest.Verbosity
            
            el = fixture.getForwardingLogListener; %#ok<NASGU>
            fixture.Qualifiable.log(varargin{:});
        end
        
        function assertMatches(fixture, varargin)
            % assertMatches - Assert a string matches a regular expression
            %
            %   Use assertMatches inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertMatches
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertMatches(varargin{:});
        end
        
        function assertSubstring(fixture, varargin)
            % assertSubstring - Assert a string contains an expected string
            %
            %   Use assertSubstring inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertSubstring
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertSubstring(varargin{:});
        end
        
        function assertClass(fixture, varargin)
            % assertClass - Assert the exact class of some value
            %
            %   Use assertClass inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertClass
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertClass(varargin{:});
        end
        
        function assertInstanceOf(fixture, varargin)
            % assertInstanceOf - Assert a value "isa" expected type
            %
            %   Use assertInstanceOf inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertInstanceOf
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertInstanceOf(varargin{:});
        end
        
        function assertReturnsTrue(fixture, varargin)
            % assertReturnsTrue - Assert a function returns true when evaluated
            %
            %   Use assertReturnsTrue inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertReturnsTrue
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertReturnsTrue(varargin{:});
        end
        
        function assertLessThanOrEqual(fixture, varargin)
            % assertLessThanOrEqual - Assert a value is equal or smaller than some ceiling
            %
            %   Use assertLessThanOrEqual inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertLessThanOrEqual
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertLessThanOrEqual(varargin{:});
        end
        
        function assertLessThan(fixture, varargin)
            % assertLessThan - Assert a value is less than some ceiling
            %
            %   Use assertLessThan inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertLessThan
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertLessThan(varargin{:});
        end
        
        function assertGreaterThanOrEqual(fixture, varargin)
            % assertGreaterThanOrEqual - Assert a value is equal or larger than some floor
            %
            %   Use assertGreaterThanOrEqual inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertGreaterThanOrEqual
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertGreaterThanOrEqual(varargin{:});
        end
        
        function assertGreaterThan(fixture, varargin)
            % assertGreaterThan - Assert a value is larger than some floor
            %
            %   Use assertGreaterThan inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertGreaterThan
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertGreaterThan(varargin{:});
        end
        
        function assertNumElements(fixture, varargin)
            % assertNumElements - Assert a value has an expected element count
            %
            %   Use assertNumElements inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertNumElements
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertNumElements(varargin{:});
        end
        
        function assertLength(fixture, varargin)
            % assertLength - Assert a value has an expected length
            %
            %   Use assertLength inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertLength
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertLength(varargin{:});
        end
        
        function assertSize(fixture, varargin)
            % assertSize - Assert a value has an expected size
            %
            %   Use assertSize inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertSize
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertSize(varargin{:});
        end
        
        function assertNotEmpty(fixture, varargin)
            % assertNotEmpty - Assert a value is not empty
            %
            %   Use assertNotEmpty inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertNotEmpty
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertNotEmpty(varargin{:});
        end
        
        function assertEmpty(fixture, varargin)
            % assertEmpty - Assert a value is empty
            %
            %   Use assertEmpty inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertEmpty
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertEmpty(varargin{:});
        end
        
        function assertWarningFree(fixture, varargin)
            % assertWarningFree - Assert a function issues no warnings
            %
            %   Use assertWarningFree inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertWarningFree
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertWarningFree(varargin{:});
        end
        
        function assertWarning(fixture, varargin)
            % assertWarning - Assert a function issues a specific warning
            %
            %   Use assertWarning inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertWarning
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertWarning(varargin{:});
        end
        
        function assertError(fixture, varargin)
            % assertError - Assert a function throws a specific exception
            %
            %   Use assertError inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertError
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertError(varargin{:});
        end
        
        function assertNotSameHandle(fixture, varargin)
            % assertNotSameHandle - Assert a value isn't a handle to some instance
            %
            %   Use assertNotSameHandle inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertNotSameHandle
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertNotSameHandle(varargin{:});
        end
        
        function assertSameHandle(fixture, varargin)
            % assertSameHandle - Assert two values are handles to the same instance
            %
            %   Use assertSameHandle inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertSameHandle
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertSameHandle(varargin{:});
        end
        
        function assertNotEqual(fixture, varargin)
            % assertNotEqual - Assert a value is not equal to an expected
            %
            %   Use assertNotEqual inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertNotEqual
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertNotEqual(varargin{:});
        end
        
        function assertEqual(fixture, varargin)
            % assertEqual - Assert the equality of a value to an expected
            %
            %   Use assertEqual inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertEqual
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertEqual(varargin{:});
        end
        
        function assertFalse(fixture, varargin)
            % assertFalse - Assert that a value is false
            %
            %   Use assertFalse inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertFalse
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertFalse(varargin{:});
        end

        function assertThat(fixture, varargin)
            % assertThat - Assert that a value meets a given constraint
            %
            %   Use assertThat inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertThat

            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertThat(varargin{:});
        end

        function assertTrue(fixture, varargin)
            % assertTrue - Assert that a value is true
            %
            %   Use assertTrue inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertTrue
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertTrue(varargin{:});
        end
        
        function assertFail(fixture, varargin)
            % assertFail - Produce an unconditional assertion failure
            %
            %   Use assertFail inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assertable/assertFail
            
            el = fixture.getForwardingAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.assertFail(varargin{:});
        end
        
        function assumeMatches(fixture, varargin)
            % assumeMatches - Assume a string matches a regular expression
            %
            %   Use assumeMatches inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeMatches
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeMatches(varargin{:});
        end
        
        function assumeSubstring(fixture, varargin)
            % assumeSubstring - Assume a string contains an expected string
            %
            %   Use assumeSubstring inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeSubstring
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeSubstring(varargin{:});
        end
        
        function assumeClass(fixture, varargin)
            % assumeClass - Assume the exact class of some value
            %
            %   Use assumeClass inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeClass
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeClass(varargin{:});
        end
        
        function assumeInstanceOf(fixture, varargin)
            % assumeInstanceOf - Assume a value "isa" expected type
            %
            %   Use assumeInstanceOf inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeInstanceOf
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeInstanceOf(varargin{:});
        end
        
        function assumeReturnsTrue(fixture, varargin)
            % assumeReturnsTrue - Assume a function returns true when evaluated
            %
            %   Use assumeReturnsTrue inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeReturnsTrue
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeReturnsTrue(varargin{:});
        end
        
        function assumeLessThanOrEqual(fixture, varargin)
            % assumeLessThanOrEqual - Assume a value is equal or smaller than some ceiling
            %
            %   Use assumeLessThanOrEqual inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeLessThanOrEqual
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeLessThanOrEqual(varargin{:});
        end
        
        function assumeLessThan(fixture, varargin)
            % assumeLessThan - Assume a value is less than some ceiling
            %
            %   Use assumeLessThan inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeLessThan
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeLessThan(varargin{:});
        end
        
        function assumeGreaterThanOrEqual(fixture, varargin)
            % assumeGreaterThanOrEqual - Assume a value is equal or larger than some floor
            %
            %   Use assumeGreaterThanOrEqual inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeGreaterThanOrEqual
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeGreaterThanOrEqual(varargin{:});
        end
        
        function assumeGreaterThan(fixture, varargin)
            % assumeGreaterThan - Assume a value is larger than some floor
            %
            %   Use assumeGreaterThan inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeGreaterThan
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeGreaterThan(varargin{:});
        end
        
        function assumeNumElements(fixture, varargin)
            % assumeNumElements - Assume a value has an expected element count
            %
            %   Use assumeNumElements inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeNumElements
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeNumElements(varargin{:});
        end
        
        function assumeLength(fixture, varargin)
            % assumeLength - Assume a value has an expected length
            %
            %   Use assumeLength inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeLength
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeLength(varargin{:});
        end
        
        function assumeSize(fixture, varargin)
            % assumeSize - Assume a value has an expected size
            %
            %   Use assumeSize inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeSize
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeSize(varargin{:});
        end
        
        function assumeNotEmpty(fixture, varargin)
            % assumeNotEmpty - Assume a value is not empty
            %
            %   Use assumeNotEmpty inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeNotEmpty
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeNotEmpty(varargin{:});
        end
        
        function assumeEmpty(fixture, varargin)
            % assumeEmpty - Assume a value is empty
            %
            %   Use assumeEmpty inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeEmpty
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeEmpty(varargin{:});
        end
        
        function assumeWarningFree(fixture, varargin)
            % assumeWarningFree - Assume a function issues no warnings
            %
            %   Use assumeWarningFree inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeWarningFree
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeWarningFree(varargin{:});
        end
        
        function assumeWarning(fixture, varargin)
            % assumeWarning - Assume a function issues a specific warning
            %
            %   Use assumeWarning inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeWarning
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeWarning(varargin{:});
        end
        
        function assumeError(fixture, varargin)
            % assumeError - Assume a function throws a specific exception
            %
            %   Use assumeError inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeError
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeError(varargin{:});
        end
        
        function assumeNotSameHandle(fixture, varargin)
            % assumeNotSameHandle - Assume a value isn't a handle to some instance
            %
            %   Use assumeNotSameHandle inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeNotSameHandle
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeNotSameHandle(varargin{:});
        end
        
        function assumeSameHandle(fixture, varargin)
            % assumeSameHandle - Assume two values are handles to the same instance
            %
            %   Use assumeSameHandle inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeSameHandle
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeSameHandle(varargin{:});
        end
        
        function assumeNotEqual(fixture, varargin)
            % assumeNotEqual - Assume a value is not equal to an expected
            %
            %   Use assumeNotEqual inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeNotEqual
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeNotEqual(varargin{:});
        end
        
        function assumeEqual(fixture, varargin)
            % assumeEqual - Assume the equality of a value to an expected
            %
            %   Use assumeEqual inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeEqual
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeEqual(varargin{:});
        end
        
        function assumeFalse(fixture, varargin)
            % assumeFalse - Assume that a value is false
            %
            %   Use assumeFalse inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeFalse
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeFalse(varargin{:});
        end

        function assumeThat(fixture, varargin)
            % assumeThat - Assume that a value meets a given constraint
            %
            %   Use assumeThat inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeThat

            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeThat(varargin{:});
        end

        function assumeTrue(fixture, varargin)
            % assumeTrue - Assume that a value is true
            %
            %   Use assumeTrue inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeTrue
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeTrue(varargin{:});
        end
        
        function assumeFail(fixture, varargin)
            % assumeFail - Produce an unconditional assumption failure
            %
            %   Use assumeFail inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.Assumable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.Assumable/assumeFail
            
            el = fixture.getForwardingAssumptionListeners; %#ok<NASGU>
            fixture.Qualifiable.assumeFail(varargin{:});
        end
        
        function fatalAssertMatches(fixture, varargin)
            % fatalAssertMatches - Fatally assert a string matches a regular expression
            %
            %   Use fatalAssertMatches inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertMatches
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertMatches(varargin{:});
        end
        
        function fatalAssertSubstring(fixture, varargin)
            % fatalAssertSubstring - Fatally assert a string contains an expected string
            %
            %   Use fatalAssertSubstring inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertSubstring
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertSubstring(varargin{:});
        end
        
        function fatalAssertClass(fixture, varargin)
            % fatalAssertClass - Fatally assert the exact class of some value
            %
            %   Use fatalAssertClass inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertClass
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertClass(varargin{:});
        end
        
        function fatalAssertInstanceOf(fixture, varargin)
            % fatalAssertInstanceOf - Fatally assert a value "isa" expected type
            %
            %   Use fatalAssertInstanceOf inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertInstanceOf
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertInstanceOf(varargin{:});
        end
        
        function fatalAssertReturnsTrue(fixture, varargin)
            % fatalAssertReturnsTrue - Fatally assert a function returns true when evaluated
            %
            %   Use fatalAssertReturnsTrue inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertReturnsTrue
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertReturnsTrue(varargin{:});
        end
        
        function fatalAssertLessThanOrEqual(fixture, varargin)
            % fatalAssertLessThanOrEqual - Fatally assert a value is equal or smaller than some ceiling
            %
            %   Use fatalAssertLessThanOrEqual inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertLessThanOrEqual
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertLessThanOrEqual(varargin{:});
        end
        
        function fatalAssertLessThan(fixture, varargin)
            % fatalAssertLessThan - Fatally assert a value is less than some ceiling
            %
            %   Use fatalAssertLessThan inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertLessThan
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertLessThan(varargin{:});
        end
        
        function fatalAssertGreaterThanOrEqual(fixture, varargin)
            % fatalAssertGreaterThanOrEqual - Fatally assert a value is equal or larger than some floor
            %
            %   Use fatalAssertGreaterThanOrEqual inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertGreaterThanOrEqual
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertGreaterThanOrEqual(varargin{:});
        end
        
        function fatalAssertGreaterThan(fixture, varargin)
            % fatalAssertGreaterThan - Fatally assert a value is larger than some floor
            %
            %   Use fatalAssertGreaterThan inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertGreaterThan
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertGreaterThan(varargin{:});
        end
        
        function fatalAssertNumElements(fixture, varargin)
            % fatalAssertNumElements - Fatally assert a value has an expected element count
            %
            %   Use fatalAssertNumElements inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertNumElements
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertNumElements(varargin{:});
        end
        
        function fatalAssertLength(fixture, varargin)
            % fatalAssertLength - Fatally assert a value has an expected length
            %
            %   Use fatalAssertLength inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertLength
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertLength(varargin{:});
        end
        
        function fatalAssertSize(fixture, varargin)
            % fatalAssertSize - Fatally assert a value has an expected size
            %
            %   Use fatalAssertSize inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertSize
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertSize(varargin{:});
        end
        
        function fatalAssertNotEmpty(fixture, varargin)
            % fatalAssertNotEmpty - Fatally assert a value is not empty
            %
            %   Use fatalAssertNotEmpty inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertNotEmpty
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertNotEmpty(varargin{:});
        end
        
        function fatalAssertEmpty(fixture, varargin)
            % fatalAssertEmpty - Fatally assert a value is empty
            %
            %   Use fatalAssertEmpty inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertEmpty
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertEmpty(varargin{:});
        end
        
        function fatalAssertWarningFree(fixture, varargin)
            % fatalAssertWarningFree - Fatally assert a function issues no warnings
            %
            %   Use fatalAssertWarningFree inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertWarningFree
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertWarningFree(varargin{:});
        end
        
        function fatalAssertWarning(fixture, varargin)
            % fatalAssertWarning - Fatally assert a function issues a specific warning
            %
            %   Use fatalAssertWarning inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertWarning
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertWarning(varargin{:});
        end
        
        function fatalAssertError(fixture, varargin)
            % fatalAssertError - Fatally assert a function throws a specific exception
            %
            %   Use fatalAssertError inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertError
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertError(varargin{:});
        end
        
        function fatalAssertNotSameHandle(fixture, varargin)
            % fatalAssertNotSameHandle - Fatally assert a value isn't a handle to some instance
            %
            %   Use fatalAssertNotSameHandle inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertNotSameHandle
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertNotSameHandle(varargin{:});
        end
        
        function fatalAssertSameHandle(fixture, varargin)
            % fatalAssertSameHandle - Fatally assert two values are handles to the same instance
            %
            %   Use fatalAssertSameHandle inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertSameHandle
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertSameHandle(varargin{:});
        end
        
        function fatalAssertNotEqual(fixture, varargin)
            % fatalAssertNotEqual - Fatally assert a value is not equal to an expected
            %
            %   Use fatalAssertNotEqual inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertNotEqual
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertNotEqual(varargin{:});
        end
        
        function fatalAssertEqual(fixture, varargin)
            % fatalAssertEqual - Fatally assert the equality of a value to an expected
            %
            %   Use fatalAssertEqual inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertEqual
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertEqual(varargin{:});
        end
        
        function fatalAssertFalse(fixture, varargin)
            % fatalAssertFalse - Fatally assert that a value is false
            %
            %   Use fatalAssertFalse inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertFalse
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertFalse(varargin{:});
        end

        function fatalAssertThat(fixture, varargin)
            % fatalAssertThat - Fatally assert that a value meets a given constraint
            %
            %   Use fatalAssertThat inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertThat

            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertThat(varargin{:});
        end

        function fatalAssertTrue(fixture, varargin)
            % fatalAssertTrue - Fatally assert that a value is true
            %
            %   Use fatalAssertTrue inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertTrue
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertTrue(varargin{:});
        end
        
        function fatalAssertFail(fixture, varargin)
            % fatalAssertFail - Produce an unconditional fatal assertion failure
            %
            %   Use fatalAssertFail inside the fixture setup and teardown methods. Refer
            %   to matlab.unittest.qualifications.FatalAssertable for more information and
            %   examples on using this method.
            %
            % See also: matlab.unittest.qualifications.FatalAssertable/fatalAssertFail
            
            el = fixture.getForwardingFatalAssertionListeners; %#ok<NASGU>
            fixture.Qualifiable.fatalAssertFail(varargin{:});
        end
    end
    
    methods (Sealed, Access = protected)
        function onFailure(fixture, failureTask, varargin)
            % onFailure - Dynamically add diagnostics for test failures.
            %
            %  onFailure(FIXTURE,ONFAILUREDIAGNOSTICS) adds diagnostics to FIXTURE and
            %  the associated TestCase object. If a test fails, then the test
            %  framework executes the diagnostics. Specify ONFAILUREDIAGNOSTICS as a
            %  function handle, array of matlab.unittest.diagnostics.Diagnostic
            %  objects, character vector, or string array. By default, onFailure adds
            %  diagnostics that are executed for assertion failures, fatal assertion
            %  failures, and uncaught exceptions on FIXTURE.
            %
            %  onFailure(FIXTURE,ONFAILUREDIAGNOSTICS,'IncludingAssumptionFailures',true)
            %  adds diagnostics that are also executed for assumption failures.
            %
            %    Example:
            %
            %       classdef SimpleFixture < matlab.unittest.fixtures.Fixture
            %           methods
            %               function setup(fixture)
            %                   fixture.onFailure(@() disp('Failure Detected'));
            %               end
            %           end
            %       end           
            import matlab.unittest.internal.AddAssumptionEventDecorator;
            import matlab.unittest.internal.FailureTask;
            
            if ~isempty(fixture.OnFailureDelegationFcn)
                fixture.OnFailureDelegationFcn(fixture, failureTask, varargin{:});
            else
                if ~isa(failureTask,'matlab.unittest.internal.Task')
                    validateattributes(failureTask, {'function_handle','matlab.unittest.diagnostics.Diagnostic',...
                        'char', 'string'},{'row'},'','OnFailureDiagnostics');
                    
                    defaultIncludeAssumption = false;
                    validationFcn = @(x)(islogical(x)&&isscalar(x));
                    
                    onFailureParser = matlab.unittest.internal.strictInputParser;
                    onFailureParser.addParameter('IncludingAssumptionFailures',...
                        defaultIncludeAssumption,validationFcn);
                    onFailureParser.parse(varargin{:});
                    parserResults = onFailureParser.Results;
                    
                    failureTask = FailureTask(failureTask);
                    
                    if parserResults.IncludingAssumptionFailures
                        failureTask = AddAssumptionEventDecorator(failureTask);
                    end
                end
                
                fixture.Qualifiable.onFailure(failureTask);
                fixture.setOnFailureTasksForExceptions_(failureTask);
                fixture.OnFailureTasks = [fixture.OnFailureTasks, failureTask];
            end
        end
    end
    
    methods(Sealed, Hidden, Access = {?matlab.unittest.TestRunner})
        function transferOnFailureTasks_(fixture, varargin)
            fixture.onFailure(varargin{:});
        end
    end
end

function bool = areFixturesEquivalent(fixture1, fixture2)
bool = strcmp(fixture1.FixtureClassName, fixture2.FixtureClassName) && ...
    isCompatible(fixture1, fixture2);
end

function [fixtures, I, J] = uniqueFixtures(fixtures, compareFcn)
% Uses a custom compareFcn to compare one fixture against others.
% Outputs match with those of the standard UNIQUE function.

N = numel(fixtures);
I = [true(1,min(N,1)) false(1,N-1)];
J = 1:N;
idx1 = 1;
while idx1<N
    tail = idx1+1:N;
    
    % only inspect those that haven't been marked as equivalent
    % to another fixture already
    subtail = tail(J(tail) >= tail);
    mask = compareFcn(fixtures(idx1), fixtures(subtail));
    
    % mark matches and jump to the next unvisited node
    J(subtail(mask)) = idx1;
    idx1 = idx1 + find(J(tail) >= tail, 1);
    I(idx1) = true;
end

fixtures = fixtures(I);
I = find(I); % logical to linear index
end

function teardownAppliedFixture(appliedFixture)
appliedFixture.teardown;
end

% LocalWords:  Qualifiable Substitutor OTHERFIXTURE evd fid el ONFAILUREFCN SHAREDTESTFIXTURE argout
% LocalWords:  INCLUDINGASSUMPTIONFAILURES ONFAILUREDIAGNOSTICS unittest plugindata lang
% LocalWords:  Teardown teardown qualifiable Comparer plugins Assertable
% LocalWords:  subtail
