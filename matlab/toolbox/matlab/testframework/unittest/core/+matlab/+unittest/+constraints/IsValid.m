classdef IsValid < matlab.unittest.constraints.BooleanConstraint & ...
                    matlab.unittest.internal.constraints.HybridDiagnosticMixin & ...
                    matlab.unittest.internal.constraints.HybridNegativeDiagnosticMixin
    % IsValid - Test if array elements are valid handles
    %
    %   The matlab.unittest.constraints.IsValid class provides a constraint
    %   to test if all elements of a handle array are valid. A handle becomes
    %   invalid if its corresponding object has been deleted.
    %
    %   IsValid methods:
    %       IsValid - Class constructor
    %
    %   Examples:
    %       import matlab.unittest.constraints.IsValid
    %       import matlab.unittest.TestCase
    %
    %       % Create a test case for interactive use
    %       testCase = TestCase.forInteractiveUse;
    %
    %       % Passing scenarios
    %       %%%%%%%%%%%%%%%%%%%%
    %       handleObj = figure;
    %       testCase.verifyThat(handleObj,IsValid)
    %       delete(obj)
    %       testCase.verifyThat(obj,~IsValid)
    %       handleObjArray = [figure figure figure];
    %       testCase.verifyThat(handleObjArray,IsValid)
    %       testCase.verifyThat(Inf,~IsValid)
    %       testCase.asserThat([1 2 3 4 5],~IsValid)
    %       testCase.fatalAssertThat(3.14,~IsValid)
    %
    %       % Failing scenarios
    %       %%%%%%%%%%%%%%%%%%%%
    %       obj = figure;
    %       testCase.verifyThat(obj,~IsValid)
    %       delete(obj)
    %       testCase.verifyThat(obj,IsValid)
    %       handleObjArray = [figure figure figure];
    %       testCase.verifyThat(handleObjArray,~IsValid)
    %       testCase.fatalAssertThat(3.14,IsValid)
    %       testCase.assertThat([5 6 7 8],IsValid)
    %       testCase.verifyThat(NaN,IsValid)
    %       testCase.fatalAssertThat(Inf,IsValid)
    %
    %   See also:
    %       handle
    %       handle/isvalid
    %       IsSameHandleAs

    %  Copyright 2022 The MathWorks, Inc.

    methods
        function constraint = IsValid
            % IsValid - Class constructor
            %
            %   c = matlab.unittest.constraints.IsValid creates a constraint
            %   to test if a handle array is valid. The constraint
            %   is satisfied if all the elements in the array are valid handles.
        end

        function tf = satisfiedBy(~, actual)
            tf = isa(actual, 'handle') && all(isvalid(actual),'all');
        end
    end

    methods(Hidden,Sealed)
        function diag = getConstraintDiagnosticFor(constraint, actual)
            if ~isa(actual,'handle')
                diag = getFailingPositiveConstraintDiagnostic(constraint, actual);
                diag.addCondition(message('MATLAB:unittest:IsValid:ValueMustBeHandle'));
            elseif ~all(isvalid(actual),'all')
                diag = getFailingPositiveConstraintDiagnostic(constraint, actual);
                if isscalar(actual)
                    diag.addCondition(message('MATLAB:unittest:IsValid:ScalarInputMustBeValid'));
                else
                    failingIndices = indicesOfNonValidElementsString(actual);
                    diag.addCondition(message('MATLAB:unittest:IsValid:VectorInputMustBeValid',failingIndices));
                end
            else % passing
                diag = getPassingPositiveConstraintDiagnostic(constraint, actual);
                if isscalar(actual)
                    diag.addCondition(message('MATLAB:unittest:IsValid:ScalarInputValid'));
                else
                    diag.addCondition(message('MATLAB:unittest:IsValid:VectorInputValid'));
                end
            end
        end

        function diag = getNegativeConstraintDiagnosticFor(constraint, actual)
            if ~isa(actual,'handle')
                diag = getPassingNegativeConstraintDiagnostic(constraint,actual);
                diag.addCondition(message('MATLAB:unittest:IsValid:ValueIsNotHandle'));
            elseif ~all(isvalid(actual),'all')
                diag = getPassingNegativeConstraintDiagnostic(constraint,actual);
                if isscalar(actual)
                    diag.addCondition(message('MATLAB:unittest:IsValid:ScalarInputNotValidHandle'));
                else
                    passingIndices = indicesOfNonValidElementsString(actual);
                    diag.addCondition(message('MATLAB:unittest:IsValid:VectorInputNotValidHandle',passingIndices));
                end
            else % failing
                diag = getFailingNegativeConstraintDiagnostic(constraint, actual);
                if isscalar(actual)
                    diag.addCondition(message('MATLAB:unittest:IsValid:ScalarInputMustBeInValid'));
                else
                    diag.addCondition(message('MATLAB:unittest:IsValid:VectorInputMustBeInValid'));
                end
            end
        end
    end
end

% Helper function to create instance of ConstriantDiagnostic to generate passing positive diagnostics
function diag = getPassingPositiveConstraintDiagnostic(constraint, actual)
    import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory
    import matlab.unittest.internal.diagnostics.DiagnosticSense
    diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, DiagnosticSense.Positive, actual);
end

% Helper function to create instance of ConstriantDiagnostic to generate passing negative diagnostics
function diag = getPassingNegativeConstraintDiagnostic(constraint, actual)
    import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory
    import matlab.unittest.internal.diagnostics.DiagnosticSense
    diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, DiagnosticSense.Negative, actual);
end

% Helper function to create instance of ConstriantDiagnostic to generate failing positive diagnostics
function diag = getFailingPositiveConstraintDiagnostic(constraint, actual)
    import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory
    import matlab.unittest.internal.diagnostics.DiagnosticSense
    diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, DiagnosticSense.Positive, actual);
end

% Helper function to create instance of ConstriantDiagnostic to generate failing positive diagnostics
function diag = getFailingNegativeConstraintDiagnostic(constraint, actual)
    import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory
    import matlab.unittest.internal.diagnostics.DiagnosticSense
    diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, DiagnosticSense.Negative, actual);
end

% Helper function to generate indices of not valid elements as string
function str = indicesOfNonValidElementsString(actual)
    import matlab.unittest.internal.diagnostics.indent;
    str = indent(mat2str(reshape(find(~isvalid(actual)),1,[])));
end