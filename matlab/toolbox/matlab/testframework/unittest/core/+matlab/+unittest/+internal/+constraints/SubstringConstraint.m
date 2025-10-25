classdef(Hidden) SubstringConstraint < matlab.unittest.constraints.BooleanConstraint & ...
        matlab.unittest.internal.constraints.HybridDiagnosticMixin & ...
        matlab.unittest.internal.constraints.HybridNegativeDiagnosticMixin & ...
        matlab.unittest.internal.mixin.IgnoringCaseMixin & ...
        matlab.unittest.internal.mixin.IgnoringWhitespaceMixin
    % This class is undocumented and may change in a future release.
    
    % SubstringConstraint is implemented to avoid duplication of code
    % between ContainsSubstring, IsSubstringOf, EndsWithSubstring,
    % and StartsWithSubstring.
    
    %  Copyright 2016-2022 The MathWorks, Inc.
    
    properties (Hidden, GetAccess = protected, SetAccess = immutable)
        ExpectedValue
    end
    
    properties(Abstract,Hidden,Constant,GetAccess=protected)
        PropertyName
    end
    
    methods(Abstract, Hidden, Access=protected)
        catalog = getMessageCatalog(constraint)
        bool = satisfiedByText(constraint, text)
    end
    
    methods
        function constraint = SubstringConstraint(expectedValue, varargin)
            import matlab.unittest.internal.mustBeTextScalar;
            import matlab.unittest.internal.mustContainCharacters;
            
            mustBeTextScalar(expectedValue,constraint.PropertyName);
            mustContainCharacters(expectedValue,constraint.PropertyName);
            constraint.ExpectedValue = expectedValue;
            constraint = constraint.parse(varargin{:});
            
            if constraint.IgnoreWhitespace && ...
                    strlength(constraint.removeWhitespaceFrom(expectedValue)) == 0
                error(message("MATLAB:automation:StringInputValidation:InvalidValueMustContainCharactersWhenIgnoringWhitespace", ...
                    constraint.PropertyName));
            end
        end
    end
    
    methods(Sealed)
        function bool = satisfiedBy(constraint, actual)
            bool = isSupportedActualValue(actual) && ...
                constraint.satisfiedByText(actual);
        end
    end
    
    methods(Hidden, Access = protected)
        function diag = getNotSatisfiedByTextCondition(constraint, ~)
            diag = constraint.getDiagnosticCondition('NotSatisfiedByText');
        end
        
        function diag = getSatisfiedByTextCondition(constraint, ~)
            diag = constraint.getDiagnosticCondition('SatisfiedByText');
        end
    end
    
    methods(Hidden,Sealed)
        function diag = getConstraintDiagnosticFor(constraint, actual)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.internal.diagnostics.DiagnosticSense;
            catalog = constraint.getMessageCatalog();
            
            if ~isSupportedActualValue(actual)
                diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                    DiagnosticSense.Positive, actual);
                diag.addCondition(catalog.getString('ActualMustBeASupportedType',...
                    class(actual),mat2str(size(actual))));
            elseif ~constraint.satisfiedByText(actual)
                diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                    DiagnosticSense.Positive, actual, constraint.ExpectedValue);
                diag.ExpValHeader = catalog.getString('ExpectedValueHeader');
                diag.addCondition(constraint.getNotSatisfiedByTextCondition(actual));                
            else
                diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, ...
                    DiagnosticSense.Positive, actual, constraint.ExpectedValue);
                diag.ExpValHeader = catalog.getString('ExpectedValueHeader');
                diag.addCondition(constraint.getSatisfiedByTextCondition(actual));
            end
        end
        
        function diag = getNegativeConstraintDiagnosticFor(constraint, actual)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.internal.diagnostics.DiagnosticSense;
            catalog = constraint.getMessageCatalog();
            
            if ~isSupportedActualValue(actual)
                diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, ...
                    DiagnosticSense.Negative, actual);
                diag.addCondition(catalog.getString('ActualIsNotASupportedType',...
                    class(actual),mat2str(size(actual))));
            elseif ~constraint.satisfiedByText(actual)
                diag = ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint, ...
                    DiagnosticSense.Negative, actual, constraint.ExpectedValue);
                diag.ExpValHeader = catalog.getString('ProhibitedValueHeader');
                diag.addCondition(constraint.getNotSatisfiedByTextCondition(actual));
            else
                diag = ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint, ...
                    DiagnosticSense.Negative, actual, constraint.ExpectedValue);
                diag.ExpValHeader = catalog.getString('ProhibitedValueHeader');
                diag.addCondition(constraint.getSatisfiedByTextCondition(actual));                
            end
        end
    end
        
    methods(Hidden ,Access=protected)
        function args = getInputArguments(constraint)
            args = {constraint.ExpectedValue};
            if constraint.IgnoreCase
                args = [args,{'IgnoringCase',true}];
            end
            if constraint.IgnoreWhitespace
                args = [args,{'IgnoringWhitespace',true}];
            end           
        end
    end
    
    methods (Hidden, Access = protected)
        function cond = getDiagnosticCondition(constraint,keyPrefix)
            catalog = constraint.getMessageCatalog();
            
            if constraint.IgnoreWhitespace && constraint.IgnoreCase
                cond = catalog.getString([keyPrefix 'IgnoringCaseAndWhitespace']);
            elseif constraint.IgnoreWhitespace
                cond = catalog.getString([keyPrefix 'IgnoringWhitespace']);
            elseif constraint.IgnoreCase
                cond = catalog.getString([keyPrefix 'IgnoringCase']);
            else
                cond = catalog.getString(keyPrefix);
            end
        end
    end
end

function bool = isSupportedActualValue(value)
bool = isCharacterVector(value) || isStringScalar(value);
end

function bool = isStringScalar(value)
bool = isstring(value) && isscalar(value);
end

function bool = isCharacterVector(value)
bool = ischar(value) && (isrow(value) || strcmp(value,''));
end

% LocalWords:  lon ASupported isstring unittest strlength
