classdef MATLABCodeTestFactory < matlab.unittest.internal.TestSuiteFactory
    % This class is undocumented.
    
    % Copyright 2019-2022 The MathWorks, Inc.
    
    properties (Abstract, SetAccess=private, GetAccess=protected)
        Filename;
    end
    
    properties(Constant)
        CreatesSuiteForValidTestContent = true;
    end
    
    methods (Abstract, Access=protected)
        suite = createSuite(factory, modifier, parameters);
    end
    
    methods (Sealed)
        function suite = createSuiteExplicitly(factory, modifier, parameters, varargin)
            suite = factory.createSuite(modifier, parameters);
        end
        
        function suite = createSuiteImplicitly(factory, modifier, parameters, nvpairs)

            arguments
                factory
                modifier
                parameters
                nvpairs.InvalidFileFoundAction {mustBeMember(nvpairs.InvalidFileFoundAction,["error","warn"])} = "warn"
            end

            import matlab.unittest.internal.diagnostics.indent;
            
            try
                suite = factory.createSuite(modifier, parameters);
            catch ex               
                if strcmp(nvpairs.InvalidFileFoundAction, "error")
                    rethrow(ex);
                end
                
                warning(message("MATLAB:unittest:TestSuite:FileExcluded", ...
                    factory.Filename, indent(ex.message)));
                suite = matlab.unittest.Test.empty;
            end
        end
    end
end