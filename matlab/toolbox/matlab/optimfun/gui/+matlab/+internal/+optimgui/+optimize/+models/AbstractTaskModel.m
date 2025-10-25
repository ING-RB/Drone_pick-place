classdef (Abstract) AbstractTaskModel < handle & matlab.mixin.Heterogeneous
    % The AbstractTaskModel class defines a common interface for back-end
	% Optimize LET classes. All model classes a hold reference to the
    % task State (data). Their key responsibility (generally) is to interpret
    % some piece of that data and generate corresponding code.
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2021 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = protected)

        % The State holds the task data
        State % Class type varies by task
    end

    methods (Access = public)

        function this = AbstractTaskModel(state)

            % Check for input arguments
            if nargin > 0

                % Set State from input argument
                this.State = state;
            end
        end
    end

    methods (Abstract, Access = public)

        % Determines whether the model is set/complete
        tf = isSet(this);

        % Generates code for the model
        code = generateCode(this);
    end
end
