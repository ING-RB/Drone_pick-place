classdef DoNothing < matlab.mock.actions.MethodCallAction & matlab.mock.actions.PropertySetAction
    % DoNothing - Take no action.
    %
    %   The DoNothing action specifies a mock object method call or property
    %   modification that should do nothing.
    %
    %   DoNothing methods:
    %       DoNothing - Class constructor
    %       then      - Specify subsequent action
    %       repeat    - Perform the same action multiple times
    %
    %   See also:
    %       matlab.mock.TestCase
    %       matlab.mock.actions.AssignOutputs
    %       matlab.mock.MethodCallBehavior/when
    %       matlab.mock.PropertySetBehavior/when
    %
    
    % Copyright 2019 The MathWorks, Inc.
    
    methods
        function action = DoNothing
            % DoNothing - Class constructor
            %
            %   ACTION = DoNothing constructs a DoNothing instance.
            %
            %   Example:
            %       import matlab.mock.actions.DoNothing;
            %       testCase = matlab.mock.TestCase.forInteractiveUse;
            %
            %       % Create a mock class with a property
            %       [mock, behavior] = testCase.createMock("AddedProperties", "Value");
            %
            %       % Set up behavior such that the property is unchanged
            %       % when set to 7.
            %       when(behavior.Value.setToValue(7), DoNothing);
            %
            %       % Use the mock
            %       mock.Value = 5;
            %       mock.Value  % Value contains 5
            %       mock.Value = 7;
            %       mock.Value  % Value still contains 5
            %
        end
    end
    
    methods (Hidden)
        function callMethod(varargin)
        end
        function setProperty(varargin)
        end
    end
end
