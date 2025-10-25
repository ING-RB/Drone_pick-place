classdef (Abstract) AbstractTaskInput < matlab.internal.optimgui.optimize.models.AbstractTaskModel
    % The AbstractTaskInput class defines common behavior for Optimize LET
    % inputs. These are models that (generally) map into the task State.
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2021-2022 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = protected)

        % StatePropertyName helps map this input value into the State via dynamic referencing
        StatePropertyName (1, :) char
    end

    properties (Dependent, Access = public)

        % Value of this input. Pulls/stores the value from/to the State property
        Value % (1, :) char or (1, 1) struct
    end

    % Set/get methods
    methods

        function set.Value(this, value)

            % Call protected method so subclasses can override the set method
            this.setValue(value);
        end

        function value = get.Value(this)

            % Call protected method so subclasses can override the get method
            value = this.getValue();
        end
    end

    methods (Access = public)

        function this = AbstractTaskInput(state, name)

            % Call superclass constructor
            this@matlab.internal.optimgui.optimize.models.AbstractTaskModel(...
                state);

            % Set StatePropertyName from input arguments
            this.StatePropertyName = name;
        end
    end

    methods (Access = protected)

        function setValue(this, value)

            % Set corresponding property in the State
            this.State.(this.StatePropertyName) = value;
        end

        function value = getValue(this)

            % Get corresponding property in the State
            value = this.State.(this.StatePropertyName);
        end
    end
end
