classdef ScriptTestFactory < matlab.unittest.internal.MATLABCodeTestFactory
    %This class is undocumented and may change in a future release.
    
    % ScriptTestFactory - Factory for creating suites for script-based tests.
    
    % Copyright 2014-2021 The MathWorks, Inc.
    
    properties(Constant)
        SupportsParameterizedTests = false;
    end
    
    properties (SetAccess=private, GetAccess=protected)
        Filename;
    end
    
    properties (Access=private)
        ParseTree;
    end
    
    methods
        function factory = ScriptTestFactory(filename, parseTree)
            factory.Filename = filename;
            factory.ParseTree = parseTree;
        end
    end
    
    methods (Access=protected)
        function suite = createSuite(factory, modifier, ~)
            import matlab.unittest.Test;
            import matlab.unittest.internal.TestScriptMFileModel;
            import matlab.unittest.internal.TestScriptMLXFileModel;
            import matlab.unittest.internal.ScriptTestCaseProvider;
            import matlab.unittest.internal.LiveScriptTestCaseProvider;

            filename = factory.Filename;
            [~,~,ext] = fileparts(filename);
            
            if strcmpi(ext,'.m')
                model = TestScriptMFileModel.fromFile(filename, factory.ParseTree);
                provider = ScriptTestCaseProvider(model);
            elseif strcmp(ext,'.mlx')
                model = TestScriptMLXFileModel.fromFile(filename);
                provider = LiveScriptTestCaseProvider(model);
            end
            
            suite = modifier.apply(Test.fromProvider(provider));
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

% LocalWords:  MFile MLX mlx
