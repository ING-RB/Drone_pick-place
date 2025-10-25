classdef IsInstanceOf < matlab.unittest.constraints.BooleanConstraint & ...
        matlab.unittest.internal.constraints.HybridDiagnosticMixin & ...
        matlab.unittest.internal.constraints.HybridNegativeDiagnosticMixin & ...
        matlab.unittest.internal.constraints.HybridCasualDiagnosticMixin
    % IsInstanceOf - Constraint specifying inclusion in a given class hierarchy
    %
    %   The IsInstanceOf constraint produces a qualification failure for any
    %   actual value that does not derive from a specified MATLAB class. The
    %   expected class can be specified either by its classname as a char or by
    %   the expected meta.class instance.
    %
    %   IsInstanceOf methods:
    %       IsInstanceOf - Class constructor
    %
    %   IsInstanceOf properties:
    %       Class - The class name a value must derive from or be to satisfy the constraint
    %
    %   Examples:
    %       import matlab.unittest.constraints.IsInstanceOf;
    %       import matlab.unittest.TestCase;
    %
    %       % Create a TestCase for interactive use
    %       testCase = TestCase.forInteractiveUse;
    %
    %       % Passing scenarios
    %       %%%%%%%%%%%%%%%%%%%%
    %       testCase.verifyThat(5, IsInstanceOf('double'));
    %       testCase.assertThat(@sin, IsInstanceOf(?function_handle));
    %
    %       classdef DerivedExample < BaseExample
    %       end
    %       testCase.assertThat(DerivedExample, IsInstanceOf(?BaseExample));
    %
    %       % Failing scenarios
    %       %%%%%%%%%%%%%%%%%%%%
    %       testCase.verifyThat(5, IsInstanceOf('char'));
    %       testCase.assertThat('sin', IsInstanceOf(?function_handle));
    %
    %   See also:
    %       IsOfClass
    %       isa

    %  Copyright 2010-2024 The MathWorks, Inc.

    properties (SetAccess=private)
        % Class - The class name a value must derive from or be to satisfy the constraint
        Class
    end

    properties (SetAccess=private, Hidden)
        ClassID
    end

    methods
        function constraint = IsInstanceOf(class)
            % IsInstanceOf - Class constructor
            %
            %   IsInstanceOf(CLASS) creates a constraint that is able to determine
            %   whether an actual value is an instance of a class that derives from the
            %   CLASS provided. This is not an exact class match, but rather specifies
            %   an "isa" relationship between the actual value instance and CLASS.
            %   CLASS can either be a char whose value is a fully qualified class
            %   name, or CLASS can be an instance of meta.class.

            if isa(class, "classID")
                constraint.ClassID = class;
                constraint.Class = class.Name;
            else
                constraint.Class = class;
            end
        end

        function tf = satisfiedBy(constraint, actual)
            if isempty(constraint.ClassID)
                actualCID = classID(actual);
                if ~isempty(actualCID.DefiningPackage)
                    error(message('MATLAB:unittest:IsInstanceOf:MustNotBePackageClass'));
                end

                tf = isa(actual, constraint.Class);
            else
                tf = isa(actual, constraint.ClassID);
            end
        end

        function constraint = set.Class(constraint, class)
            import matlab.unittest.internal.mustBeTextScalar;
            import matlab.unittest.internal.mustContainCharacters;
            validateattributes(class,{'char','matlab.metadata.Class','string'},{},'','Class');

            if isa(class,'matlab.metadata.Class')
                validateattributes(class,{'matlab.metadata.Class'},{'scalar'},'','Class');
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
                diag.ExpValHeader = getString(message('MATLAB:unittest:IsInstanceOf:ExpectedClass'));
            else
                diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                    DiagnosticSense.Positive, actual);

                % Use a sub-diagnostic to report the value's wrong class
                if isempty(constraint.ClassID)
                    classDiag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                        DiagnosticSense.Positive, class(actual), constraint.Class);
                else
                    classDiag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                        DiagnosticSense.Positive, generateClassIDDiagnosticText(classID(actual)), generateClassIDDiagnosticText(constraint.ClassID));
                end
                classDiag.Description = getString(message('MATLAB:unittest:IsInstanceOf:MustBeInstance'));
                classDiag.ActValHeader = getString(message('MATLAB:unittest:IsInstanceOf:ActualClassHeader'));
                classDiag.ExpValHeader = getString(message('MATLAB:unittest:IsInstanceOf:ExpectedClass'));
                diag.addCondition(classDiag);
            end
        end

        function diag = getNegativeConstraintDiagnosticFor(constraint, actual)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.internal.diagnostics.DiagnosticSense;

            if constraint.satisfiedBy(actual)

                diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                    DiagnosticSense.Negative, actual);

                % Use a sub-diagnostic to report the value's wrong class
                if isempty(constraint.ClassID)
                    classDiag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                        DiagnosticSense.Positive, class(actual), constraint.Class);
                else
                    classDiag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                        DiagnosticSense.Positive, generateClassIDDiagnosticText(classID(actual)), generateClassIDDiagnosticText(constraint.ClassID));
                end
                classDiag.Description = getString(message('MATLAB:unittest:IsInstanceOf:MustNotBeInstance'));
                classDiag.ActValHeader = getString(message('MATLAB:unittest:IsInstanceOf:ActualClassHeader'));
                classDiag.ExpValHeader = getString(message('MATLAB:unittest:IsInstanceOf:UnexpectedClass'));
                diag.addCondition(classDiag);

            else
                if isempty(constraint.ClassID)
                    diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, ...
                        DiagnosticSense.Negative, actual, constraint.Class);
                else
                    diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, ...
                        DiagnosticSense.Negative, actual, generateClassIDDiagnosticText(constraint.ClassID));
                end
                diag.ExpValHeader = getString(message('MATLAB:unittest:IsInstanceOf:UnexpectedClass'));
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
