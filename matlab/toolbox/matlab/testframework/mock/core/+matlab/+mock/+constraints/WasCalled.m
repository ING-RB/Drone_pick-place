classdef WasCalled < matlab.unittest.constraints.BooleanConstraint & ...
                     matlab.unittest.internal.constraints.HybridDiagnosticMixin & ...
                     matlab.unittest.internal.constraints.HybridNegativeDiagnosticMixin & ...
                     matlab.unittest.internal.constraints.HybridCasualDiagnosticMixin & ...
                     matlab.unittest.internal.constraints.HybridCasualNegativeDiagnosticMixin
    % WasCalled - Constraint specifying that a method was called.
    %
    %   The WasCalled constraint produces a qualification failure for a
    %   MethodCallBehavior corresponding to a method that was not called the
    %   specified number of times. The actual value must be a scalar
    %   MethodCallBehavior instance.
    %
    %   By default, the constraint qualifies that the method was called at
    %   least once. However, any specific method call count can be specified
    %   using the WithCount name/value pair.
    %
    %   Negate the WasCalled constraint with the "~" operator to qualify that a
    %   method was not called the specified number of times.
    %
    %   WasCalled methods:
    %       WasCalled - Class constructor
    %
    %   WasCalled properties:
    %       Count - Numeric value specifying the method call count
    %
    %   Examples:
    %       import matlab.mock.constraints.WasCalled;
    %       import matlab.unittest.constraints.IsGreaterThan;
    %       testCase = matlab.mock.TestCase.forInteractiveUse;
    %
    %       % Create a mock for a bank account class
    %       [fakeAccount, behavior] = testCase.createMock("AddedMethods","deposit");
    %
    %       % Use the mock account
    %       fakeAccount.deposit(10);
    %       fakeAccount.deposit(20);
    %       fakeAccount.deposit(10);
    %
    %       % Passing Cases:
    %       testCase.verifyThat(behavior.deposit(10), WasCalled);
    %       testCase.verifyThat(behavior.deposit(10), WasCalled('WithCount',2));
    %       testCase.verifyThat(behavior.deposit(IsGreaterThan(100)), ~WasCalled);
    %
    %       % Failing Cases:
    %       testCase.verifyThat(behavior.deposit(100), WasCalled);
    %       testCase.verifyThat(behavior.deposit(20), WasCalled('WithCount',2));
    %       testCase.verifyThat(behavior.deposit(IsGreaterThan(50)), WasCalled);
    %
    %   See also:
    %       matlab.mock.TestCase
    %
    
    % Copyright 2015-2024 The MathWorks, Inc.
    
    properties (SetAccess=immutable)
        % Count - Numeric value specifying the method call count
        %
        %   The Count property is a scalar numeric value specifying the exact
        %   number of times the method must be called.
        %
        %   The Count property is set through the class constructor using the
        %   WithCount name/value pair.
        %
        Count double;
    end
    
    properties (SetAccess=immutable, GetAccess=private)
        HasCount logical = false;
    end
    
    properties (Constant, Access=private)
        Catalog matlab.internal.Catalog = matlab.internal.Catalog('MATLAB:mock:WasCalled');
    end
    
    methods
        function constraint = WasCalled(options)
            % WasCalled - Class constructor
            %
            %   constraint = WasCalled constructs a WasCalled instance to determine if
            %   a method was called at least once.
            %
            %   constraint = WasCalled('WithCount',count) constructs a WasCalled
            %   instance to determine if a method was called exactly the specified
            %   number of times. The count must be a scalar numeric value.
            %
            arguments
                options.WithCount (1,1) {mustBeNumeric,mustBeFinite,mustBePositive,mustBeInteger}
            end
            
            if isfield(options, "WithCount")
                constraint.HasCount = true;
                constraint.Count = options.WithCount;
            end
        end
        
        function bool = satisfiedBy(constraint, actual)
            validateMethodCallBehavior(actual);
            bool = constraint.methodWasCalledTheCorrectNumberOfTimes(actual);
        end
    end
    
    methods(Hidden,Sealed)
        function diag = getConstraintDiagnosticFor(constraint,actual)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.internal.diagnostics.DiagnosticSense;
            
            validateMethodCallBehavior(actual);
            
            sense = DiagnosticSense.Positive;
            callsAnySignature = actual.CallsWithAnySignature;
            
            if ~constraint.methodWasCalledTheCorrectNumberOfTimes(actual)
                diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, sense, actual);
                diag.ActValHeader = constraint.Catalog.getString('SpecifiedMethodCall');
                
                if numel(callsAnySignature) == 0
                    diag.addCondition(constraint.Catalog.getString('MethodNeverCalled', actual.Name));
                else
                    diag.addCondition(constraint.getCountDiagnostic(actual, sense, "fail"));
                    diag.addCondition(getInteractionLogCondition(callsAnySignature));
                end
            else % passing
                diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, sense, actual);
                diag.ActValHeader = constraint.Catalog.getString('SpecifiedMethodCall');
                diag.addCondition(constraint.getCountDiagnostic(actual, sense, "pass"));
                diag.addCondition(getInteractionLogCondition(callsAnySignature));
            end
        end
        
        function diag = getNegativeConstraintDiagnosticFor(constraint, actual)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.internal.diagnostics.DiagnosticSense;
            
            validateMethodCallBehavior(actual);
            
            sense = DiagnosticSense.Negative;
            callsAnySignature = actual.CallsWithAnySignature;
            
            if ~constraint.methodWasCalledTheCorrectNumberOfTimes(actual)
                diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, sense, actual);
                diag.ActValHeader = constraint.Catalog.getString('SpecifiedMethodCall');
                
                if numel(callsAnySignature) == 0
                    diag.addCondition(constraint.Catalog.getString('MethodNeverCalled', actual.Name));
                else
                    diag.addCondition(constraint.getCountDiagnostic(actual, sense, "pass"));
                    diag.addCondition(getInteractionLogCondition(callsAnySignature));
                end
            else % failing
                diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, sense, actual);
                diag.ActValHeader = constraint.Catalog.getString('SpecifiedMethodCall');
                diag.addCondition(constraint.getCountDiagnostic(actual, sense, "fail"));
                diag.addCondition(getInteractionLogCondition(callsAnySignature));
            end
        end
    end
    
    methods(Hidden,Sealed,Access=protected)
        function args = getInputArguments(constraint)
            args = {};
            if constraint.HasCount
                args = [args,{'WithCount',constraint.Count}];
            end
        end
    end
    
    methods (Access=private)
        function bool = methodWasCalledTheCorrectNumberOfTimes(constraint, actual)
            if constraint.HasCount
                bool = actual.Count == constraint.Count;
            else
                bool = actual.Count > 0;
            end
        end
        
        function cond = getCountDiagnostic(constraint, actual, sense, passOrFail)
            if constraint.HasCount
                cond = getFullCountCondition(actual, constraint.Count, sense, passOrFail);
            else
                cond = getBasicCountCondition(actual, sense, passOrFail);
            end
        end
    end
    
    methods
        function count = get.Count(constraint)
            if ~constraint.HasCount
                error(message('MATLAB:mock:WasCalled:NoCount'));
            end
            count = constraint.Count;
        end
    end
end

function validateMethodCallBehavior(actual)
validateattributes(actual, "matlab.mock.MethodCallBehavior", {'scalar'});
end

function cond = getFullCountCondition(actual, expCount, sense, passOrFail)
import matlab.unittest.diagnostics.ConstraintDiagnostic;
import matlab.mock.constraints.WasCalled;

if sense == "Positive" && passOrFail == "pass"
    descKey = 'MethodCalledExpectedNumberOfTimes';
    expValKey = 'ExpectedMethodCallCount';
elseif passOrFail == "pass"
    descKey = 'MethodNotCalledProhibitedNumberOfTimes';
    expValKey = 'ProhibitedMethodCallCount';
elseif sense == "Positive"
    descKey = 'MethodNotCalledExpectedNumberOfTimes';
    expValKey = 'ExpectedMethodCallCount';
else
    descKey = 'MethodCalledProhibitedNumberOfTimes';
    expValKey = 'ProhibitedMethodCallCount';
end

cond = ConstraintDiagnostic;
cond.DisplayDescription = true;
cond.Description = WasCalled.Catalog.getString(descKey, actual.Name);
cond.DisplayActVal = true;
cond.ActValHeader = WasCalled.Catalog.getString('ActualMethodCallCount');
cond.ActVal = actual.Count;
cond.DisplayExpVal = true;
cond.ExpValHeader = WasCalled.Catalog.getString(expValKey);
cond.ExpVal = expCount;
end

function cond = getBasicCountCondition(actual, sense, passOrFail)
import matlab.mock.constraints.WasCalled;

if sense == "Positive" && passOrFail == "pass"
    cond = WasCalled.Catalog.getString('MethodCalledAtLeastOnce', actual.Name, actual.Count);
elseif passOrFail == "pass"
    cond = WasCalled.Catalog.getString('MethodNotCalledAtLeastOnce', actual.Name);
elseif sense == "Positive"
    cond = WasCalled.Catalog.getString('MethodNotCalledAtLeastOnce', actual.Name);
else
    cond = WasCalled.Catalog.getString('MethodUnexpectedlyCalledAtLeastOnce', actual.Name, actual.Count);
end
end

function cond = getInteractionLogCondition(callsAnySignature)
import matlab.unittest.internal.diagnostics.indent;
import matlab.mock.constraints.WasCalled;

MAX_CALLS_DISPLAYED = 10;
numAllCalls = numel(callsAnySignature);
calls = indent(join(callsAnySignature(1:min(MAX_CALLS_DISPLAYED,numAllCalls)), newline));

if numAllCalls <= MAX_CALLS_DISPLAYED
    header = WasCalled.Catalog.getString('ObservedMethodCalls');
else
    header = WasCalled.Catalog.getString('ObservedMethodCallsFirstN', MAX_CALLS_DISPLAYED, numAllCalls);
end

cond = sprintf('%s\n%s', header, calls);
end

% LocalWords:  unittest
