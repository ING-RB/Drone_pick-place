classdef (Sealed) ODEResults < matlab.mixin.CustomDisplay

    properties(SetAccess={?ode})
        Time
        Solution
        Sensitivity
        EventTime
        EventSolution
        EventIndex
        EventSensitivity
    end

    properties(Hidden,Access={?ode})
        hasEvents = false;
        hasSensitivity = false;
    end

    % constructor restricted to ode class and unit tests
    methods(Access={?ode,?matlab.unittest.TestCase})
        function obj = ODEResults(nv)
            arguments
                nv.Time
                nv.Solution
                nv.Sensitivity
                nv.EventTime
                nv.EventSolution
                nv.EventIndex
                nv.EventSensitivity
                nv.hasEvents
                nv.hasSensitivity
            end
            names = fieldnames(nv);
            for k = 1:numel(names)
                obj.(names{k}) = nv.(names{k});
            end
        end
    end

    % constructor restricted to ode class and unit tests
    methods(Hidden,Access=?ode)
        function obj = realToComplex(obj)
            obj.Solution = matlab.ode.internal.r2cArray(obj.Solution);
            if obj.hasSensitivity
                obj.Sensitivity = matlab.ode.internal.r2cArray(obj.Sensitivity);
            end
            if obj.hasEvents
                obj.EventSolution = matlab.ode.internal.r2cArray(obj.EventSolution);
                if obj.hasSensitivity
                    obj.EventSensitivity = matlab.ode.internal.r2cArray(obj.EventSensitivity);
                end
            end
        end
    end

    methods(Access=protected)
        function props = getRightProps(obj)
            props = {'Time';'Solution'};
            if obj.hasEvents
                props = [props(:);{'EventTime'};{'EventSolution'};{'EventIndex'}];
            end
            if obj.hasSensitivity
                props = [props(:);{'Sensitivity'}];
            end
            if obj.hasEvents && obj.hasSensitivity
                props = [props(:);{'EventSensitivity'}];
            end
        end

        % only display nonempty properties
        function group = getPropertyGroups(obj)
            % custom display property groups
            group = getRightProps(obj);
            group = matlab.mixin.util.PropertyGroup(group);
        end
    end

    methods(Hidden)
        % only tab complete nonempty properties
        function props = properties(obj)
            if nargout == 0
                % call builtin to print standard message with no output
                builtin('properties',obj);
                return
            end
            props = getRightProps(obj);
        end
    end

    % save-load
    properties(Constant,Hidden)
        % 1.0 : Initial version (R2023b)
        Version = 1.0;
    end

    methods (Hidden)
        function b = saveobj(a)
            % Save all properties to struct. 
            b = ode.assignProps(a,false,"matlab.ode.ODEResults");
            % Keep track of versioning information.
            b.CompatibilityHelper.versionSavedFrom = a.Version;
            b.CompatibilityHelper.minCompatibleVersion = 1.0;
        end
    end

    methods (Hidden,Static)
        function b = loadobj(a)
            if matlab.ode.ODEResults.Version < a.CompatibilityHelper.minCompatibleVersion
                warning(message("MATLAB:ode:MinVersionIncompat","matlab.ode.ODEResults"));
                b = matlab.ode.ODEResults;
                return
            end
            b = ode.assignProps(a,true,"matlab.ode.ODEResults");
        end
    end

end

%    Copyright 2023 MathWorks, Inc.