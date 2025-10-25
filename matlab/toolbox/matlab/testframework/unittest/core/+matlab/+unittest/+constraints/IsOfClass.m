classdef IsOfClass < matlab.unittest.constraints.BooleanConstraint & ...
        matlab.unittest.internal.constraints.HybridDiagnosticMixin & ...
        matlab.unittest.internal.constraints.HybridNegativeDiagnosticMixin & ...
        matlab.unittest.internal.constraints.HybridCasualDiagnosticMixin
    % IsOfClass - Constraint specifying a given exact type
    %
    %   The IsOfClass constraint produces a qualification failure for any
    %   actual value whose class is not the specified MATLAB class. The
    %   expected class can be specified as a string, character vector, or
    %   meta.class instance.
    %
    %   IsOfClass methods:
    %       IsOfClass - Class constructor
    %
    %   IsOfClass properties:
    %       Class - The class name a value must be to satisfy the constraint
    %
    %   Examples:
    %       import matlab.unittest.constraints.IsOfClass;
    %       import matlab.unittest.TestCase;
    %
    %       % Create a TestCase for interactive use
    %       testCase = TestCase.forInteractiveUse;
    %
    %       % Passing scenarios
    %       %%%%%%%%%%%%%%%%%%%%
    %       testCase.verifyThat(5, IsOfClass('double'));
    %       testCase.assertThat(@sin, IsOfClass(?function_handle));
    %
    %
    %       % Failing scenarios
    %       %%%%%%%%%%%%%%%%%%%%
    %       testCase.verifyThat(5, IsOfClass('char'));
    %       testCase.assertThat('sin', IsOfClass(?function_handle));
    %
    %       classdef DerivedExample < BaseExample
    %       end
    %       testCase.assertThat(DerivedExample, IsOfClass(?BaseExample));
    %
    %   See also:
    %       IsInstanceOf
    %       class

    % Copyright 2010-2024 The MathWorks, Inc.

    properties (SetAccess=private)
        % Class - The class name a value must be to satisfy the constraint
        Class
    end

    properties (SetAccess=private, Hidden)
        ClassID
    end

    methods
        function constraint = IsOfClass(class)
            % IsOfClass - Class constructor
            %
            %   IsOfClass(CLASS) creates a constraint that is able to determine whether
            %   an actual value's class matches the CLASS provided. This is an exact
            %   class match which does not succeed if CLASS is a superclass if the
            %   actual value instance. CLASS can either be a char whose value is a
            %   fully qualified class name, or CLASS can be an instance of meta.class.

            if isa(class, "classID")
                constraint.ClassID = class;
                constraint.Class = class.Name;
            else
                constraint.Class = class;
            end
        end

        function tf = satisfiedBy(constraint, actual)
            import matlab.alias.internal.getNewNameFromAlias;

            actualCID = classID(actual);
            if isempty(constraint.ClassID)
                if ~isempty(actualCID.DefiningPackage)
                    error(message('MATLAB:unittest:IsOfClass:MustNotBePackageClass'));
                end

                actualClassName = class(actual);
                tf = strcmp(actualClassName, constraint.Class) || ...
                    strcmp(actualClassName, getNewNameFromAlias(constraint.Class));
            else
                tf = (actualCID == constraint.ClassID);
            end
        end

        function constraint = set.Class(constraint, class)
            import matlab.unittest.internal.mustBeTextScalar;
            import matlab.unittest.internal.mustContainCharacters;
            validateattributes(class, {'char','matlab.metadata.Class','string'}, {}, '', 'Class');

            if isa(class,'matlab.metadata.Class')
                validateattributes(class, {'matlab.metadata.Class'}, {'scalar'}, '', 'Class');
                class = class.Name;
            else
                mustBeTextScalar(class,'Class');
                mustContainCharacters(class,'Class');
            end

            constraint.Class = char(class);
        end

        function constraint = set.ClassID(constraint, class)
            validateattributes(class,{'classID'},{'scalar'},'','Class');

            constraint.ClassID = class;
        end
    end

    methods(Hidden,Sealed)
        function diag = getConstraintDiagnosticFor(constraint, actual)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.internal.diagnostics.DiagnosticSense;

            if constraint.satisfiedBy(actual)
                if isempty(constraint.ClassID)
                    diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, ...
                        DiagnosticSense.Positive, actual, constraint.Class);
                else
                    diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, ...
                        DiagnosticSense.Positive, actual, generateClassIDDiagnosticText(constraint.ClassID));
                end
                diag.ExpValHeader = getString(message('MATLAB:unittest:IsOfClass:ExpectedClass'));
            else
                diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                                                                  DiagnosticSense.Positive, actual);

                % Use a sub-diagnostic to report the value's wrong class
                if isempty(constraint.ClassID)
                    classDiag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                        DiagnosticSense.Positive,  class(actual), constraint.Class);
                else
                    classDiag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                        DiagnosticSense.Positive,  generateClassIDDiagnosticText(classID(actual)), generateClassIDDiagnosticText(constraint.ClassID));
                end

                classDiag.Description = getString(message('MATLAB:unittest:IsOfClass:MustBeClass'));
                classDiag.ActValHeader = getString(message('MATLAB:unittest:IsOfClass:ActualClass'));
                classDiag.ExpValHeader = getString(message('MATLAB:unittest:IsOfClass:ExpectedClass'));
                diag.addCondition(classDiag);
            end
        end

        function diag = getNegativeConstraintDiagnosticFor(constraint, actual)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.internal.diagnostics.DiagnosticSense;

            if constraint.satisfiedBy(actual)
                if isempty(constraint.ClassID)
                    diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                        DiagnosticSense.Negative, actual, constraint.Class);
                else
                    diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                        DiagnosticSense.Negative, actual, generateClassIDDiagnosticText(constraint.ClassID));
                end
                diag.addCondition(message('MATLAB:unittest:IsOfClass:MustNotBeClass'));
                diag.ExpValHeader = getString(message('MATLAB:unittest:IsOfClass:UnexpectedClass'));
            else
                if isempty(constraint.ClassID)
                    diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, ...
                        DiagnosticSense.Negative, actual, constraint.Class);
                else
                    diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, ...
                        DiagnosticSense.Negative, actual, generateClassIDDiagnosticText(constraint.ClassID));
                end

                diag.ExpValHeader = getString(message('MATLAB:unittest:IsOfClass:UnexpectedClass'));
            end
        end
    end

    methods(Hidden,Sealed,Access=protected)
        function args = getInputArguments(constraint)
            if isempty(constraint.ClassID)
                args = {constraint.Class};
            else
                args = {constraint.ClassID};
            end
        end
    end
end

function diagText = generateClassIDDiagnosticText(cid)
diagText = matlab.unittest.internal.constraints.generateClassIDDiagnosticText(cid);
end

% LocalWords:  unittest
