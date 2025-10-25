classdef Occurred < matlab.unittest.constraints.Constraint & ...
        matlab.unittest.internal.mixin.RespectingOrderMixin & ...
        matlab.unittest.internal.constraints.HybridDiagnosticMixin
    % Occurred - General purpose constraint for qualifying mock object interactions.
    %
    %   The Occurred constraint qualifies that one or more mock object
    %   interactions occurred. It produces a qualification failure for any
    %   actual-value InteractionBehavior array that specifies at least one
    %   interaction that did not occur. The actual value must be an array of
    %   InteractionBehavior objects that all refer to the same mock object.
    %
    %   Use the Occurred constraint to qualify any combination of method calls,
    %   property accesses, or property modifications.
    %
    %   By default, the constraint qualifies that all interactions occurred at
    %   least once and in any order. The RespectingOrder name-value pair
    %   enables qualification that the interactions occurred in the specified
    %   order.
    %
    %   Occurred methods:
    %       Occurred - Class constructor
    %
    %   Occurred properties:
    %       RespectOrder - Specifies whether this instance respects the order of interactions
    %
    %   Examples:
    %       import matlab.mock.constraints.Occurred;
    %       testCase = matlab.mock.TestCase.forInteractiveUse;
    %
    %       % Create a mock person
    %       [fakePerson, behavior] = testCase.createMock("AddedProperties",["Name","Age"], ...
    %           "AddedMethods","speak");
    %
    %       % Use the person object
    %       fakePerson.speak("hello");
    %       age = fakePerson.Age;
    %       fakePerson.Name = "Andy";
    %
    %       % Passing Cases:
    %       testCase.verifyThat(behavior.speak("hello"), Occurred);
    %       testCase.verifyThat([get(behavior.Age), behavior.speak("hello"), ...
    %           behavior.Name.setToValue("Andy")], Occurred);
    %       testCase.verifyThat([behavior.speak("hello"), behavior.Name.setToValue("Andy")], ...
    %           Occurred('RespectingOrder',true));
    %
    %       % Failing Cases:
    %       testCase.verifyThat([behavior.speak("hello"), set(behavior.Age)], Occurred);
    %       testCase.verifyThat([behavior.speak("goodbye"), behavior.speak("hello")], Occurred);
    %       testCase.verifyThat([behavior.Name.setToValue("Andy"), behavior.speak("hello")], ...
    %           Occurred('RespectingOrder',true));
    %
    %   See also:
    %       matlab.mock.constraints.WasAccessed
    %       matlab.mock.constraints.WasCalled
    %       matlab.mock.constraints.WasSet
    %
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties (Constant, Access=private)
        Catalog (1,1) matlab.internal.Catalog = matlab.internal.Catalog('MATLAB:mock:Occurred');
    end
    
    methods
        function constraint = Occurred(varargin)
            % Occurred - Class constructor
            %
            %   constraint = matlab.mock.constraints.Occurred constructs an Occurred
            %   instance to determine if all specified interactions occurred.
            %
            %   constraint = matlab.mock.constraints.Occurred('RespectingOrder',true)
            %   constructs an Occurred instance to determine if all specified
            %   interactions occurred in the specified order.
            %
            
            constraint = constraint.parse(varargin{:});
        end
        
        function bool = satisfiedBy(constraint, actual)
            import matlab.mock.internal.constraints.CompositeInteractionCheck;
            import matlab.mock.internal.constraints.RequiredInteractionCheck;
            import matlab.mock.internal.constraints.OrderedInteractionCheck;
            
            validateattributes(actual, "matlab.mock.InteractionBehavior", {});
            
            check = CompositeInteractionCheck;
            check.addInteractionCheck(RequiredInteractionCheck(actual));
            
            if constraint.RespectOrder
                check.addInteractionCheck(OrderedInteractionCheck.forMinimalQualification(actual));
            end
            
            actual.applyInteractionCheck(check);
            bool = check.isSatisfied;
        end
    end
    
    methods (Hidden, Sealed)
        function diag = getConstraintDiagnosticFor(constraint, actual)
            import matlab.mock.internal.constraints.CompositeInteractionCheck;
            import matlab.mock.internal.constraints.RequiredInteractionCheck;
            import matlab.mock.internal.constraints.OrderedInteractionCheck;
            
            validateattributes(actual, "matlab.mock.InteractionBehavior", {});
            
            compositeCheck = CompositeInteractionCheck;
            missingCheck = RequiredInteractionCheck(actual);
            compositeCheck.addInteractionCheck(missingCheck);
            
            if constraint.RespectOrder
                orderCheck = OrderedInteractionCheck.forExhaustiveAnalysis(actual);
                compositeCheck.addInteractionCheck(orderCheck);
            end
            
            actual.applyInteractionCheck(compositeCheck);
            
            diag = constraint.createCoreDiagnostic(compositeCheck, actual);
            constraint.addMissingInteractionCondition(diag, missingCheck);
            
            if constraint.RespectOrder
                constraint.addOrderCondition(diag, orderCheck);
            end
        end
    end
    
    methods (Access=private)
        function diag = createCoreDiagnostic(constraint, overallCheck, actual)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.internal.diagnostics.DiagnosticSense;
            
            if overallCheck.isSatisfied
                diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, DiagnosticSense.Positive, actual);
            else
                diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, DiagnosticSense.Positive, actual);
            end
            
            diag.ActValHeader = constraint.Catalog.getString('SpecifiedInteractions');
        end
        
        function addMissingInteractionCondition(constraint, diag, missingCheck)
            if missingCheck.isSatisfied
                diag.addCondition(constraint.Catalog.getString('AllInteractionsOccurred'));
            else
                header = getString(message("MATLAB:mock:Occurred:InteractionsDidNotOccur"));
                summary = getDisplaySummaryString(missingCheck.InteractionsThatDidNotOccur);
                diag.addCondition(string + header + newline + summary);
            end
        end
        
        function addOrderCondition(constraint, diag, orderCheck)
            if orderCheck.isSatisfied
                diag.addCondition(constraint.Catalog.getString('InteractionsOccurredInOrder'));
            else
                str = string(getString(message("MATLAB:mock:Occurred:InteractionsDidNotOccurInOrder")));
                if ~isempty(orderCheck.ActualInteractionOrder)
                    label = getString(message("MATLAB:mock:Occurred:ActualOrder"));
                    summary = getDisplaySummaryString(orderCheck.ActualInteractionOrder);
                    str = str + newline + label + newline + summary;
                end
                diag.addCondition(str);
            end
        end
    end
    
    methods (Hidden, Access=protected)
        function args = getInputArguments(constraint)
            args = {};
            if constraint.RespectOrder
                args = [args, {'RespectingOrder', true}];
            end
        end
    end
end

function str = getDisplaySummaryString(interactions)
import matlab.unittest.internal.diagnostics.indent;
str = string(indent(join(interactions.getDisplaySummary, newline)));
end

% LocalWords:  unittest
