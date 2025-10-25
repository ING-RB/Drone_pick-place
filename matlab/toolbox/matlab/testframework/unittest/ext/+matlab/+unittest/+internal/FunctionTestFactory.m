classdef FunctionTestFactory < matlab.unittest.internal.MATLABCodeTestFactory
    % This class is undocumented.
    
    % FunctionTestFactory - Factory for creating suites for function-based tests.
    
    % Copyright 2014-2021 The MathWorks, Inc.
    
    properties(Constant)
        SupportsParameterizedTests = false;
    end
    
    properties (Access=private)
        TestFunctionName;
    end
    
    properties (SetAccess=private, GetAccess=protected)
        Filename;
    end
    
    methods
        function factory = FunctionTestFactory(fcn)
            factory.TestFunctionName = fcn;
        end
        
        function filename = get.Filename(factory)
            import matlab.unittest.internal.whichFile;
            filename = whichFile(factory.TestFunctionName);
        end
    end
    
    methods (Access=protected)
        function suite = createSuite(factory, modifier, ~)
            import matlab.unittest.internal.FunctionTestCaseModifierProvider;

            % Store modifier for use by functiontests.
            modifierProvider = FunctionTestCaseModifierProvider;
            cleaner = modifierProvider.set(factory.TestFunctionName, modifier); %#ok<NASGU> 

            suite = feval(factory.TestFunctionName);
        end
    end
    
    methods(Hidden)
        function bool = isValidProcedureName(factory,procedureName)            
            import matlab.unittest.selectors.HasProcedureName;
            
            suite = factory.createSuite(HasProcedureName(procedureName));
            bool = ~isempty(suite);
        end
    end
end

