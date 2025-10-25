classdef(Hidden) SubsetSupersetConstraint < matlab.unittest.constraints.BooleanConstraint & ...
                                            matlab.unittest.internal.constraints.HybridDiagnosticMixin & ...
                                            matlab.unittest.internal.constraints.HybridNegativeDiagnosticMixin
    % This class is undocumented and may change in a future release.
    
    % SubsetSupersetConstraint is implemented to avoid duplication of code
    % between IsSubsetOf, IsSupersetOf, and IsSameSetOf.
    
    %  Copyright 2015-2024 The MathWorks, Inc.
    
    properties(Abstract,Hidden,Access=protected)
        Expected
    end
    
    properties(Abstract,Hidden,Constant,Access=protected)
        Catalog
        DoSubsetCheck
        DoSupersetCheck
    end

    methods(Sealed)
        function bool = satisfiedBy(constraint, actual)
            expected = constraint.Expected;
            
            bool = areCompatibleSets(actual,expected) && ...
                (~constraint.DoSubsetCheck || isSubset(actual, expected)) && ...
                (~constraint.DoSupersetCheck || isSubset(expected, actual)) && ...
                (~doCountCheck(constraint) || areEqualSets(actual, expected));
        end
    end
    
    methods(Hidden,Sealed)
        function diag = getConstraintDiagnosticFor(constraint, actual)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.internal.diagnostics.DiagnosticSense;
            
            createUnsatisfiedDiag = @(constraint, actual) ...
                ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint,...
                DiagnosticSense.Positive, actual, constraint.Expected);
            createSatisfiedDiag = @(constraint, actual) ...
                ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint,...
                DiagnosticSense.Positive, actual, constraint.Expected);
            
            diag = constraint.generateDiagnostic(actual,...
                createUnsatisfiedDiag,createSatisfiedDiag,'Positive');
        end
        
        function diag = getNegativeConstraintDiagnosticFor(constraint,actual)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.internal.diagnostics.DiagnosticSense;
            
            createUnsatisfiedDiag = @(constraint, actual) ...
                ConstraintDiagnosticFactory.generatePassingDiagnostic(constraint,...
                DiagnosticSense.Negative, actual, constraint.Expected);
            createSatisfiedDiag = @(constraint, actual) ...
                ConstraintDiagnosticFactory.generateFailingDiagnostic(constraint,...
                DiagnosticSense.Negative, actual, constraint.Expected);
            
            diag = constraint.generateDiagnostic(actual,...
                createUnsatisfiedDiag,createSatisfiedDiag,'Negative');
        end
    end
    
    methods(Hidden,Access=protected)
        function args = getInputArguments(constraint)
            args = {constraint.Expected};
        end

        function bool = doCountCheck(~)
            bool = false;
        end
    end
    
    methods(Access=private)
        function diag = generateDiagnostic(constraint,actual,createUnsatisfiedDiag,createSatisfiedDiag,sensePrefix)
            import matlab.unittest.internal.diagnostics.ConstraintDiagnosticFactory;
            import matlab.unittest.diagnostics.Diagnostic;
            
            if ~areCompatibleSets(actual,constraint.Expected)
                diag = createUnsatisfiedDiag(constraint,actual);
                subdiag = ConstraintDiagnosticFactory.generateClassMismatchDiagnostic(...
                    actual, constraint.Expected);
                diag.addCondition(subdiag);
                constraint.updateExpValHeader(diag,sensePrefix);
                return;
            end
            
            conditionList = Diagnostic.empty(1,0);
            
            if constraint.DoSubsetCheck
                conditionList = [conditionList,...
                    constraint.generateExtraElementsCondition(actual,sensePrefix)];
            end
            
            if constraint.DoSupersetCheck
                conditionList = [conditionList,...
                    constraint.generateMissingElementsCondition(actual,sensePrefix)];
            end

            if isempty(conditionList) && doCountCheck(constraint)
                conditionList = [conditionList,...
                    constraint.generateMismatchedCountElementsCondition(actual,sensePrefix)];
            end
            
            if ~isempty(conditionList)
                diag = createUnsatisfiedDiag(constraint,actual);
                diag.addCondition(conditionList);
            else
                diag = createSatisfiedDiag(constraint,actual);
                diag.addCondition(constraint.generatePassingCondition(sensePrefix));
            end
            constraint.updateExpValHeader(diag,sensePrefix);
        end
        
        function condition = generateExtraElementsCondition(constraint,actual,sensePrefix)
            [~,extraIndicesList] = isSubset(actual,constraint.Expected);
            prefix = [sensePrefix 'Extra'];
            condition = constraint.generateMissingOrExtraElementsCondition(...
                actual,extraIndicesList,prefix);
        end
        
        function condition = generateMissingElementsCondition(constraint,actual,sensePrefix)
            [~,missingIndicesList] = isSubset(constraint.Expected,actual);
            prefix = [sensePrefix 'Missing'];
            condition = constraint.generateMissingOrExtraElementsCondition(...
                constraint.Expected,missingIndicesList,prefix);
        end
        
        function condition = generateMissingOrExtraElementsCondition(constraint,setOfElements,indicesList,prefix)
            import matlab.unittest.diagnostics.ConstraintDiagnostic;
            import matlab.unittest.internal.supportsArrayIndexing;

            if isempty(indicesList)
                condition = ConstraintDiagnostic.empty(1,0);
                return;
            end
            
            catalog = constraint.Catalog;
            
            condition = ConstraintDiagnostic();
            condition.DisplayDescription = true;
            condition.DisplayConditions = true;

            numElements = numel(indicesList);
            if numElements > 5
                condition.Description = catalog.getString([prefix 'ElementsFirst5'],numElements);
            else
                condition.Description = catalog.getString([prefix 'Elements'],numElements);
            end

            arrayIndexingSupported = supportsArrayIndexing(setOfElements);
            for k=1:min(numElements,5)
                condition.addCondition(constraint.createElementSubCondition(...
                    indicesList{k},setOfElements,arrayIndexingSupported));
            end
        end

        function condition = generateMismatchedCountElementsCondition(constraint,actual,sensePrefix)
            import matlab.unittest.diagnostics.ConstraintDiagnostic;
            import matlab.unittest.internal.supportsArrayIndexing;
            import matlab.unittest.diagnostics.Diagnostic;

            [uniqueExpected,~,expIndexForCount] = unique(constraint.Expected);
            cntExpected = accumarray(expIndexForCount,1).';
            [uniqueActual,indexToArray,actIndexForCount] = unique(actual);
            cntActual = accumarray(actIndexForCount,1).';

            catalog = constraint.Catalog;
            condition = ConstraintDiagnostic();
            condition.DisplayDescription = true;
            condition.DisplayConditions = true;
            condition.Description = catalog.getString([sensePrefix 'NoMatch']);

            arrayIndexingSupported = supportsArrayIndexing(actual);

            if numel(cntExpected) == numel(cntActual) &&  isequal(uniqueActual,uniqueExpected)
                for k = 1:numel(cntActual)                    
                    if cntActual(k) ~= cntExpected(k)
                        condition.addCondition(constraint.createElementWithCountSubCondition(...
                    indexToArray(k),actual,cntActual(k),cntExpected(k),arrayIndexingSupported));
                        return;
                    end
                end
            end

            condition = ConstraintDiagnostic.empty(1,0);
        end
        
        function subCondition = createElementSubCondition(constraint,indices,setOfElements,arrayIndexingSupported)
            catalog = constraint.Catalog;
            if arrayIndexingSupported
                element = setOfElements(indices(1));
                elementStr = createElementDisplayStr(element);
                if isscalar(indices)
                    subCondition = catalog.getString('ElementAtIndex',indices,elementStr);
                else
                    subCondition = catalog.getString('ElementAtIndices',getIndicesStr(indices),elementStr);
                end
            else
                if isscalar(indices)
                    subCondition = catalog.getString('IndexOfElement',indices);
                else
                    subCondition = catalog.getString('IndicesOfElement',getIndicesStr(indices));
                end
            end
        end

        function subCondition = createElementWithCountSubCondition(constraint,indices,setOfElements,actualCount,expectedCount,arrayIndexingSupported)
            catalog = constraint.Catalog;
            if arrayIndexingSupported
                element = setOfElements(indices(1));
                elementStr = createElementDisplayStr(element);
                if isscalar(indices)
                    subCondition = catalog.getString('ElementAtIndexWithCount',indices,elementStr,actualCount,expectedCount);
                end
            else
                if isscalar(indices)
                    subCondition = catalog.getString('IndexofElementWithCount',indices,actualCount,expectedCount);
                end
            end
        end
        
        function condition = generatePassingCondition(constraint,sensePrefix)
            condition = constraint.Catalog.getString([sensePrefix 'Satisfied']);
        end
        
        function updateExpValHeader(constraint,diag,sensePrefix)
            diag.ExpValHeader = constraint.Catalog.getString(...
                [sensePrefix 'ExpectedHeader']);
        end
    end
end


function bool = areCompatibleSets(actual,expected)
bool = (classID(actual) == classID(expected)) || ...
    isobject(actual) || isobject(expected);
end


function [bool,extraIndicesList] = isSubset(sub,super)
foundMask = reshape(ismember(sub,super),1,[]);
bool = all(foundMask);
if nargout > 1
    extraIndicesList = getExtraIndicesList(sub,~foundMask);
end
end


function list = getExtraIndicesList(value,extraMask)
indexMap = getIndexMap(value);
uniqueValueMask = indexMap == 1:numel(indexMap);
uniqueExtrasInds = find(extraMask & uniqueValueMask);
list = arrayfun(@(ind) find(indexMap == ind),...
    uniqueExtrasInds,'UniformOutput',false);
end


function indMap = getIndexMap(value)
[~,indMap] = ismember(value,value);
indMap = reshape(indMap,1,[]);

% Address NaN and missing cases, by making each of them point to themselves
missingMask = indMap==0;
indMap(missingMask) = find(missingMask);
end

function bool = areEqualSets(actual, expected)
if numel(actual) ~= numel(expected)
    bool = false;
else
    actualSet = reshape(actual,1,[]);
    expectedSet = reshape(expected,1,[]);
    bool = isequal(sort(actualSet), sort(expectedSet));
end
end

function str = createElementDisplayStr(element)
import matlab.unittest.internal.diagnostics.getDisplayableStringWithNoHeader;
import matlab.unittest.internal.diagnostics.getDisplayableString;
if isobject(element)
    str = char(getDisplayableString(element));
else
    str = char(getDisplayableStringWithNoHeader(element));
end
end


function str = getIndicesStr(indices)
if numel(indices) > 10
    str = char("[" + join(string(indices(1:10)),',') + ",...]");
else
    str = char("[" + join(string(indices),',') + "]");
end
end

% LocalWords:  Superset
