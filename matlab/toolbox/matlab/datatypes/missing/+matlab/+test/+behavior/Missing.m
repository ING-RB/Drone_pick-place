classdef Missing < matlab.unittest.TestCase
%

%   Copyright 2018-2024 The MathWorks, Inc.

    properties (Abstract)
        MissingValue (1,1);
        PrototypeValue (1,1);
        ClassesWithSupportedConversions (1,:) string;
    end
    
    properties (SetAccess=protected)
        SupportsComparison (1,1) logical = true;
        SupportsOrdering (1,1) logical = true;
        UsableAsMissingIndicator (1,1) logical = true;
        FillValue (1,1);
        ExtraConstructorArguments (1,:) cell = {};
    end
    
    properties (SetAccess=private, Dependent)
        ContractClass (1,:) char;
    end
    
    methods
        function value = get.ContractClass(testCase)
            value = class(testCase.PrototypeValue);
        end
    end
    
    methods (TestClassSetup, Sealed)
        function basicValidation(testCase)
            testCase.assertClass(testCase.MissingValue, testCase.ContractClass, getString(message('MATLAB:test:behavior:missing:SameClass')));
            testCase.assertTrue(ismissing(testCase.MissingValue), getString(message('MATLAB:test:behavior:missing:IsMissingValue')));
            testCase.assertFalse(ismissing(testCase.PrototypeValue), getString(message('MATLAB:test:behavior:missing:PrototypeNotMissing')));
        end
        
        function setupFillValue(testCase)
            testCase.FillValue = testCase.MissingValue;
        end
    end
    
    methods (Access = protected)
        function verifyEqualToLocalValue(testCase, computedValue, localValue, varargin)
            %

            % Method that can be overridden if necessary to compare a computed value against
            % a literal local value.
            testCase.verifyEqual(computedValue, localValue, varargin{:});
        end
    end
    
    methods (Test, Sealed)
        function conversion(testCase)
            converted = feval(testCase.ContractClass, missing, testCase.ExtraConstructorArguments{:});
            testCase.verifyEqual(testCase.MissingValue, converted, getString(message('MATLAB:test:behavior:missing:ScalarConversion', testCase.ContractClass)));
            
            converted = feval(testCase.ContractClass, repmat(missing,3), testCase.ExtraConstructorArguments{:});
            expanded = repmat(testCase.MissingValue, 3);
            testCase.verifyEqual(converted, expanded, getString(message('MATLAB:test:behavior:missing:MatrixConversion', testCase.ContractClass)));

            % Do not support converting back to missing
            a = missing;
            testCase.verifyError(@()assignValue(a, 1, testCase.PrototypeValue), 'MATLAB:UnableToConvert', getString(message('MATLAB:test:behavior:missing:MissingConversion', 'PrototypeValue')));
            testCase.verifyError(@()assignValue(a, 1, testCase.MissingValue), 'MATLAB:UnableToConvert', getString(message('MATLAB:test:behavior:missing:MissingConversion', 'MissingValue')));
        end
        
        function conversionOfOtherTypes(testCase)
            %

            % Test Plan Objective: A class that can convert an supported
            % type should also be able to convert a missing of the supported
            % type.
            
            for conversion = testCase.ClassesWithSupportedConversions
                converted = feval(conversion, missing);
                testCase.assertClass(converted, conversion, getString(message('MATLAB:test:behavior:missing:ConversionConversion', conversion)));
                
                act = feval(testCase.ContractClass, converted, testCase.ExtraConstructorArguments{:});
                exp = testCase.MissingValue;
                testCase.verifyEqual(act, exp, getString(message('MATLAB:test:behavior:missing:ConversionRoundTrip', testCase.ContractClass, conversion)));
            end
        end
        
        function subscriptedAssignment(testCase)
            expanded = repmat(testCase.PrototypeValue, 3);
            expanded(4) = missing;
            expected = false(3);
            expected(4) = true;
            testCase.verifyEqualToLocalValue(ismissing(expanded), expected, getString(message('MATLAB:test:behavior:missing:ScalarAssignment')));
            
            expanded(2:7) = missing;
            expected(2:7) = true;
            testCase.verifyEqualToLocalValue(ismissing(expanded), expected, getString(message('MATLAB:test:behavior:missing:ExpansionAssignment')));
            
            expanded(1:4) = repmat(missing,1,4);
            expected(1:4) = true(1,4);
            testCase.verifyEqualToLocalValue(ismissing(expanded), expected, getString(message('MATLAB:test:behavior:missing:ArrayAssignment')));
        end
        
        function concatenation(testCase)
            %

            % Horizontal concatenation
            c = [testCase.PrototypeValue, missing];
            testCase.verifyEqualToLocalValue(ismissing(c), [false, true], getString(message('MATLAB:test:behavior:missing:Horzcat')));
            c2 = cat(2, testCase.PrototypeValue, missing);
            testCase.verifyEqual(c, c2, getString(message('MATLAB:test:behavior:missing:Cat2')));
            
            % Vertical concatenation
            % Intentionally using explicit call to vertcat
            c = vertcat(missing,testCase.PrototypeValue);
            testCase.verifyEqualToLocalValue(ismissing(c), [true; false], getString(message('MATLAB:test:behavior:missing:Vertcat')));
            c2 = cat(1, missing, testCase.PrototypeValue);
            testCase.verifyEqual(c, c2, getString(message('MATLAB:test:behavior:missing:Cat1')));
        end
        
        function comparison(testCase)
            testCase.assumeTrue(testCase.SupportsComparison);
            testCase.verifyFalse(testCase.MissingValue == testCase.MissingValue, getString(message('MATLAB:test:behavior:missing:EqualFalse')));
            testCase.verifyTrue(testCase.MissingValue ~= testCase.MissingValue, getString(message('MATLAB:test:behavior:missing:NotEqualTrue')));
            testCase.verifyFalse(testCase.MissingValue == missing, getString(message('MATLAB:test:behavior:missing:EqualFalse')));
            testCase.verifyTrue(testCase.MissingValue ~= missing, getString(message('MATLAB:test:behavior:missing:NotEqualTrue')));
            testCase.verifyFalse(missing == testCase.MissingValue, getString(message('MATLAB:test:behavior:missing:EqualFalse')));
            testCase.verifyTrue(missing ~= testCase.MissingValue, getString(message('MATLAB:test:behavior:missing:NotEqualTrue')));
        end
        
        function ordering(testCase)
            testCase.assumeTrue(testCase.SupportsComparison);
            testCase.assumeTrue(testCase.SupportsOrdering);
            testCase.verifyFalse(testCase.MissingValue < testCase.MissingValue, getString(message('MATLAB:test:behavior:missing:LessThanFalse')));
            testCase.verifyFalse(testCase.MissingValue > testCase.MissingValue, getString(message('MATLAB:test:behavior:missing:GreaterThanFalse')));
            testCase.verifyFalse(testCase.MissingValue <= testCase.MissingValue, getString(message('MATLAB:test:behavior:missing:LessThanOrEqualFalse')));
            testCase.verifyFalse(testCase.MissingValue >= testCase.MissingValue, getString(message('MATLAB:test:behavior:missing:GreaterThanOrEqualFalse')));
            testCase.verifyFalse(missing < testCase.MissingValue, getString(message('MATLAB:test:behavior:missing:LessThanFalse')));
            testCase.verifyFalse(missing > testCase.MissingValue, getString(message('MATLAB:test:behavior:missing:GreaterThanFalse')));
            testCase.verifyFalse(missing <= testCase.MissingValue, getString(message('MATLAB:test:behavior:missing:LessThanOrEqualFalse')));
            testCase.verifyFalse(missing >= testCase.MissingValue, getString(message('MATLAB:test:behavior:missing:GreaterThanOrEqualFalse')));
            testCase.verifyFalse(testCase.MissingValue < missing, getString(message('MATLAB:test:behavior:missing:LessThanFalse')));
            testCase.verifyFalse(testCase.MissingValue > missing, getString(message('MATLAB:test:behavior:missing:GreaterThanFalse')));
            testCase.verifyFalse(testCase.MissingValue <= missing, getString(message('MATLAB:test:behavior:missing:LessThanOrEqualFalse')));
            testCase.verifyFalse(testCase.MissingValue >= missing, getString(message('MATLAB:test:behavior:missing:GreaterThanOrEqualFalse')));
        end
        
        function isequalRules(testCase)
            testCase.verifyFalse(isequal(testCase.MissingValue, missing), getString(message('MATLAB:test:behavior:missing:IsEqualMissingValueMissing')));
            testCase.verifyFalse(isequal(missing, testCase.MissingValue), getString(message('MATLAB:test:behavior:missing:IsEqualMissingMissingValue')));
            testCase.verifyFalse(isequal(testCase.MissingValue, testCase.MissingValue), getString(message('MATLAB:test:behavior:missing:IsEqualMissingValueMissingValue')));
            
            testCase.verifyTrue(isequaln(testCase.MissingValue, missing), getString(message('MATLAB:test:behavior:missing:IsEqualnMissingValueMissing')));
            testCase.verifyTrue(isequaln(missing, testCase.MissingValue), getString(message('MATLAB:test:behavior:missing:IsEqualnMissingMissingValue')));
            testCase.verifyTrue(isequaln(testCase.MissingValue, testCase.MissingValue), getString(message('MATLAB:test:behavior:missing:IsEqualnMissingValueMissingValue')));
        end
        
        function IsMissing2ndInput(testCase)
            testCase.assumeTrue(testCase.UsableAsMissingIndicator);
            testCase.verifyTrue(ismissing(testCase.MissingValue, missing), getString(message('MATLAB:test:behavior:missing:IsMissingMissingIndicator')));
            testCase.verifyTrue(ismissing(testCase.MissingValue, testCase.MissingValue), getString(message('MATLAB:test:behavior:missing:IsMissingMissingValueIndicator')));
            testCase.verifyFalse(ismissing(testCase.PrototypeValue, missing), getString(message('MATLAB:test:behavior:missing:IsNotMissingMissingIndicator')));
            testCase.verifyTrue(ismissing(testCase.PrototypeValue, testCase.PrototypeValue), getString(message('MATLAB:test:behavior:missing:IsMissingPrototypeIndicator')));
        end
        
        function testFillValue(testCase)
            missingObj([3,8]) = testCase.PrototypeValue;
            
            actMissingElements = missingObj([1,2,4:7]);
            
            expMissingElements = repmat(testCase.FillValue, size(actMissingElements));
            testCase.verifyEqual(actMissingElements, expMissingElements, getString(message('MATLAB:test:behavior:missing:FillValue')));
        end
        
        function empties(testCase)
            missingObj = missing.empty;
            testCase.verifyError(@()(functionToTest(missingObj, testCase.PrototypeValue)), 'MATLAB:UnableToConvert', getString(message('MATLAB:test:behavior:missing:AssignToEmptyMissing'))); 
            
            function functionToTest(missingObj, valueToAssign)
                missingObj(1) = valueToAssign; %#ok<NASGU>
            end
        end
    end
end

function a = assignValue(a, i, b)
    a(i) = b;
end
