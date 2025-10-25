classdef (Hidden) Teardownable < matlab.mixin.Copyable
    %

    % Copyright 2012-2023 The MathWorks, Inc.
    
    properties (Access=private)
        TeardownDelegate;
    end
    
    methods
        function teardownable = Teardownable
            teardownable.TeardownDelegate = matlab.unittest.internal.TeardownDelegate;
        end
        
        function delete(teardownable)
            teardownable.runAllTeardownThroughProcedure_( ...
                @(fcn,varargin)fcn(teardownable, varargin{:}));
        end
    end
    
    methods(Access = protected)
        % Override copyElement method:
        function newCopy = copyElement(original)
            newCopy = copyElement@matlab.mixin.Copyable(original);
            newCopy.TeardownDelegate = copy(newCopy.TeardownDelegate);
        end
    end
    
    methods(Sealed)
        function addTeardown(teardownable, fcn, varargin)
            % addTeardown - Dynamically add a teardown routine.
            %
            %   addTeardown(TESTCONTENT, TEARDOWNFCN) registers the TEARDOWNFCN
            %   function handle that defines teardown code. When the TESTCONTENT
            %   instance goes out of scope, the TEARDOWNFCN functions added to that
            %   instance are executed in the opposite order in which they were added.
            %
            %   addTeardown(TESTCONTENT, TEARDOWNFCN, ARG1, ARG2, ..., ARGN)
            %   optionally includes the input arguments ARG1, ARG2, ..., ARGN
            %   as inputs to TEARDOWNFCN.
            %
            %   Example:
            %
            %       classdef SomeTest < matlab.unittest.TestCase
            %           methods(TestMethodSetup)
            %               function setFormatCompact(testCase)
            %                   f = format;
            %                   testCase.addTeardown(@format, f.LineSpacing);
            %                   format("compact");
            %               end
            %           end
            %           methods(Test)
            %               function test1(testCase)
            %               end
            %           end
            %       end
            %
            %   See also:
            %       matlab.unittest.TestCase

            import matlab.unittest.internal.TeardownElement;
            
            if isa(fcn, 'matlab.unittest.internal.TeardownElement')
                teardownElement = fcn;
            else
                validateattributes(fcn, {'function_handle'}, {}, '', 'teardownFcn');
                teardownElement = TeardownElement(@runTeardown, [{fcn}, varargin]);
            end
            
            teardownable.TeardownDelegate.doAddTeardown(teardownElement);
        end
    end
    
    methods (Sealed, Access={?matlab.unittest.internal.TestRunnerExtension,?matlab.unittest.internal.FixtureRole})
        function runTeardown(~, fcn, varargin)
            fcn(varargin{:});
        end
        
        function runAllTeardownThroughProcedure_(teardownable, procedure)
            teardownable.TeardownDelegate.doRunAllTeardownThroughProcedure(procedure);
        end
    end
    
    methods (Sealed, Access=?matlab.unittest.internal.TestContentDelegateSubstitutor)
        function transferTeardownDelegate_(supplierTeardownable, acceptorTeardownable)
            import matlab.unittest.internal.AddTeardownDelegate;
            
            % First, move any existing teardown content from the acceptor's stack to the supplier's stack.
            supplierTeardownable.TeardownDelegate.appendTeardownFrom(acceptorTeardownable.TeardownDelegate);
            
            acceptorTeardownable.TeardownDelegate = AddTeardownDelegate(supplierTeardownable.TeardownDelegate);
        end
    end
end

% LocalWords:  TEARDOWNFCN TEARDOWNFC Ns ARGN TSome teardownable Substitutor TESTCONTENT
