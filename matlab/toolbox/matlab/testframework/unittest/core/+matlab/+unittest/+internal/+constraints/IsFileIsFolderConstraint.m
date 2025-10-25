classdef(Hidden) IsFileIsFolderConstraint < matlab.unittest.constraints.BooleanConstraint & ...
                                            matlab.unittest.internal.constraints.HybridDiagnosticMixin & ...
                                            matlab.unittest.internal.constraints.HybridNegativeDiagnosticMixin
    % This class is undocumented and may change in a future release.
    
    % Copyright 2017-2021 The MathWorks, Inc.
    
    properties(Abstract,Hidden,Constant,Access=protected)
        CheckFcn
        Catalog
    end
    
    methods(Sealed)
        function bool = satisfiedBy(constraint, actual)
            bool = isSupportedActualValue(actual) && constraint.CheckFcn(actual);
        end
    end
    
    methods(Hidden,Sealed)
        function diag = getConstraintDiagnosticFor(constraint, actual)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.internal.diagnostics.DiagnosticSense;
            
            createUnsatisfiedDiag = @(constraint, actual) ...
                ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint,...
                DiagnosticSense.Positive, actual);
            createSatisfiedDiag = @(constraint, actual) ...
                ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint,...
                DiagnosticSense.Positive, actual);
            
            diag = constraint.generateDiagnostic(actual,...
                createUnsatisfiedDiag,createSatisfiedDiag);
        end
        
        function diag = getNegativeConstraintDiagnosticFor(constraint,actual)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.internal.diagnostics.DiagnosticSense;
            
            createUnsatisfiedDiag = @(constraint, actual) ...
                ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint,...
                DiagnosticSense.Negative, actual);
            createSatisfiedDiag = @(constraint, actual) ...
                ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint,...
                DiagnosticSense.Negative, actual);
            
            diag = constraint.generateDiagnostic(actual,...
                createUnsatisfiedDiag,createSatisfiedDiag);
        end
    end
    
    methods(Access=private)
        function diag = generateDiagnostic(constraint,actual,createUnsatisfiedDiag,createSatisfiedDiag)
            import matlab.unittest.internal.folderResolver;
            
            if ~isSupportedActualValue(actual)
                diag = createUnsatisfiedDiag(constraint, actual);
                diag.addCondition(constraint.Catalog.getString('ActualIsNotSupportedType',...
                    class(actual),mat2str(size(actual))));
                return;
            end
            
            if ~constraint.CheckFcn(actual)
                diag = createUnsatisfiedDiag(constraint, actual);
                diag.addCondition(constraint.Catalog.getString('DoesNotExist'));
            else
                diag = createSatisfiedDiag(constraint, actual);
                [~,info] = fileattrib(char(actual));
                resolvedName = info.Name;
                if strcmp(actual,resolvedName)
                    diag.addCondition(constraint.Catalog.getString('Exists'));
                else
                    diag.addCondition(constraint.Catalog.getString(...
                        'ResolvedExists',resolvedName));
                end
            end
            
            currentFolder = folderResolver(".");
            if ~startsWith(actual,[currentFolder filesep])
                %Display current folder whenever a relative path is given
                %or if the pwd is not a parent folder
                diag.addCondition(constraint.Catalog.getString('CurrentFolder', currentFolder));
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

% LocalWords:  unittest ASupported