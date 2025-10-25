classdef IsSameHandleAs < matlab.unittest.constraints.BooleanConstraint & ...
                          matlab.unittest.internal.constraints.HybridDiagnosticMixin & ...
                          matlab.unittest.internal.constraints.HybridNegativeDiagnosticMixin & ...
                          matlab.unittest.internal.constraints.HybridCasualDiagnosticMixin & ...
                          matlab.unittest.internal.constraints.HybridCasualNegativeDiagnosticMixin
    % IsSameHandleAs - Constraint specifying the same handle instance(s) to another
    %
    %   The IsSameHandleAs constraint produces a qualification failure for any
    %   actual value that is not the same size or does not contain the same
    %   instances as a specified handle array.
    %
    %   IsSameHandleAs methods:
    %       IsSameHandleAs - Class constructor
    %
    %   IsSameHandleAs properties:
    %       ExpectedHandle - The expected handle array
    %
    %   Examples:
    %       % Define a handle class for use in examples
    %       classdef ExampleHandle < handle
    %       end
    %
    %
    %       import matlab.unittest.constraints.IsSameHandleAs;
    %       import matlab.unittest.TestCase;
    %
    %       % Create a TestCase for interactive use
    %       testCase = TestCase.forInteractiveUse;
    %
    %       % Passing scenarios
    %       %%%%%%%%%%%%%%%%%%%%
    %       h1 = ExampleHandle;
    %       h2 = ExampleHandle;
    %       testCase.fatalAssertThat(h1, IsSameHandleAs(h1));
    %       testCase.assertThat([h1 h1], IsSameHandleAs([h1 h1]));
    %       testCase.verifyThat([h1 h2 h1], IsSameHandleAs([h1 h2 h1]));
    %
    %
    %       % Failing scenarios
    %       %%%%%%%%%%%%%%%%%%%%
    %       testCase.fatalAssertThat(h1, IsSameHandleAs(h2));
    %       testCase.verifyThat([h1 h1], IsSameHandleAs(h1));
    %       testCase.assertThat(h2, IsSameHandleAs([h2 h2]));
    %       testCase.assumeThat([h1 h2], IsSameHandleAs([h2 h1]));
    %
    %   See also:
    %       handle/eq
    
    %  Copyright 2010-2024 The MathWorks, Inc.
    
    properties(SetAccess=private)
        % ExpectedHandle - The expected handle array
        ExpectedHandle
    end
    
    methods
        function constraint = IsSameHandleAs(expectedValue)
            % IsSameHandleAs - Class constructor
            %
            %   IsSameHandleAs(HANDLE) creates a constraint that is able to determine
            %   whether an actual value is an array which contains the same instances
            %   as HANDLE. The actual value array must be the same size as the HANDLE
            %   array, and each element of the actual value must be the same instance
            %   as each corresponding element of the HANDLE array (element-by-element),
            %   or a qualification failure is produced.
            
            validateattributes(expectedValue, {'handle'}, {'nonempty'}, '', 'expectedValue');
            constraint.ExpectedHandle = expectedValue;
        end
        
        function tf = satisfiedBy(constraint, actual)
            % Since the ExpectedHandle was validated as a handle in the
            % constructor, we don't need explicit validation here.
            
            import matlab.unittest.internal.StrictHandleComparer;
            
            tf = false;
            if isequal(size(actual), size(constraint.ExpectedHandle)) && ...
                    (classID(actual) == classID(constraint.ExpectedHandle))
                sameHandleMask = StrictHandleComparer.eq(constraint.ExpectedHandle, actual);
                tf = all(sameHandleMask(:));
            end
        end
    end
    
    methods(Hidden,Sealed)
        function diag = getConstraintDiagnosticFor(constraint, actual)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.internal.diagnostics.DiagnosticSense;
            import matlab.unittest.internal.StrictHandleComparer;
            
            expected = constraint.ExpectedHandle;
            
            if constraint.satisfiedBy(actual)
                diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, ...
                    DiagnosticSense.Positive, actual, expected);
                diag.ExpValHeader = getString(message('MATLAB:unittest:IsSameHandleAs:ExpectedHandle'));
            else
                diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                    DiagnosticSense.Positive, actual, expected);
                diag.ExpValHeader = getString(message('MATLAB:unittest:IsSameHandleAs:ExpectedHandle'));
                
                actSize = size(actual);
                expSize = size(expected);
                areSameSize = isequal(actSize, expSize);
                actIsScalar = isscalar(actual);
                expIsScalar = isscalar(expected);
                canCallEq = areSameSize || actIsScalar || expIsScalar;
                actClass = class(actual);
                expClass = class(expected);
                
                % size mismatch diagnostic
                if ~areSameSize
                    diag.addCondition(message('MATLAB:unittest:IsSameHandleAs:MustBeSameSize', ...
                        int2str(actSize), int2str(expSize)));
                end
                
                % handle mismatch diagnostic
                if canCallEq && ~all(StrictHandleComparer.eq(expected, actual))
                    if actIsScalar && expIsScalar
                        condition = message('MATLAB:unittest:IsSameHandleAs:MustBeSameHandle');
                    else
                        condition = message('MATLAB:unittest:IsSameHandleAs:MustBeSameHandleArray');
                    end
                    diag.addCondition(condition);
                end
                
                % "not a handle" diagnostic
                if ~isa(actual, 'handle')
                    diag.addCondition(message('MATLAB:unittest:IsSameHandleAs:MustBeHandle', actClass));
                end
                
                % class mismatch diagnostic
                if ~strcmp(actClass, expClass)
                    diag.addCondition(message('MATLAB:unittest:IsSameHandleAs:MustBeSameClass', ...
                        actClass, expClass));
                end
            end
        end
        
        function diag = getNegativeConstraintDiagnosticFor(constraint, actual)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.internal.diagnostics.DiagnosticSense;
            
            if constraint.satisfiedBy(actual)
                diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                    DiagnosticSense.Negative, actual, constraint.ExpectedHandle);
                diag.addCondition(message('MATLAB:unittest:IsSameHandleAs:MustNotBeSameHandle'));
                diag.ExpValHeader = getString(message('MATLAB:unittest:IsSameHandleAs:UnexpectedHandle'));
            else
                diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, ...
                    DiagnosticSense.Negative, actual, constraint.ExpectedHandle);
                diag.ExpValHeader = getString(message('MATLAB:unittest:IsSameHandleAs:UnexpectedHandle'));
            end
        end
    end
    
    methods(Hidden,Sealed,Access=protected)
        function args = getInputArguments(constraint)
            args = {constraint.ExpectedHandle};
        end
    end
end

% LocalWords:  unittest Comparer
