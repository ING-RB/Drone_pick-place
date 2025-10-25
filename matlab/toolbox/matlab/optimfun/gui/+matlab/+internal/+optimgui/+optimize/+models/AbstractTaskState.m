classdef (Abstract) AbstractTaskState < handle
    % The AbstractTaskState class defines common behavior for Optimize LET
    % state (data).
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2022 The MathWorks, Inc.

    properties (Abstract, Access = public)

        % State classes must track version history
        Version (1, 1) double
    end

    methods (Access = public)

        function this = updateState(this, stateStruct)

            % Account for any required state struct updates, such as
            % version related updates
            stateStruct = this.updateStateStruct(stateStruct);

            % Assign properties to corresponding struct field values
            propNames = properties(this);
            for ct = 1:numel(propNames)
                this.(propNames{ct}) = stateStruct.(propNames{ct});
            end
        end
    end

    methods (Access = protected)

        function state = updateStateStruct(this, state)

            % Subclasses can extend method for other necessary updates

            % Update to the latest version number
            state.Version = this.getLatestVersionNumber();
        end
    end

    methods (Abstract, Static, Access = public)

        % Use a static method to return this value because it does not
        % belong in the State
        ver = getLatestVersionNumber();
    end
end
