classdef Invoke < matlab.mock.actions.MethodCallAction
    % Invoke - Delegate to specified function.
    %
    %   The Invoke action specifies a function handle to be invoked when a mock
    %   object method is called. The Invoke constructor accepts the function
    %   handle. When the mock object method is called, the function handle is
    %   invoked with the inputs and number of outputs matching how the method
    %   was called.
    %
    %   Invoke methods:
    %       Invoke - Class constructor
    %       then   - Specify subsequent action
    %       repeat - Perform the same action multiple times
    %
    %   Invoke properties:
    %       Function - The function handle to be invoked
    %
    %   See also:
    %       matlab.mock.TestCase
    %       matlab.mock.actions.AssignOutputs
    %       matlab.mock.MethodCallBehavior/when
    %
    
    % Copyright 2017 The MathWorks, Inc.
    
    properties (SetAccess=immutable)
        % Function - The function handle to be invoked
        %
        %   The Function property is the function handle that is invoked when a
        %   mock object method is called.
        %
        Function (1,1) function_handle = @()[];
    end
    
    methods
        function action = Invoke(fcn)
            % Invoke - Class constructor.
            %
            %   ACTION = Invoke(FCN) constructs an Invoke instance. The specified
            %   function handle FCN is invoked to carry out the implementation of a
            %   mock object method.
            %
            %   Example:
            %       import matlab.mock.actions.Invoke;
            %       testCase = matlab.mock.TestCase.forInteractiveUse;
            %
            %      % Create a mock for a class that represents a 6-sided die
            %      [mock, behavior] = testCase.createMock("AddedMethods","roll");
            %
            %       % Set up behavior to return a random integer 1 through 6 each time called
            %      when(withExactInputs(behavior.roll), Invoke(@(die)randi(6)));
            %
            %      % Use the mock
            %      value = mock.roll
            %
            action.Function = fcn;
        end
    end
    
    methods (Hidden)
        function varargout = callMethod(action, ~, ~, ~, varargin)
            [varargout{1:nargout}] = action.Function(varargin{:});
        end
    end
end

% LocalWords:  randi
