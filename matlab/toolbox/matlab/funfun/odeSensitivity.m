classdef (Sealed=true) odeSensitivity

    properties
        ParameterIndices double {mustBeReal,mustBeInteger,mustBePositive}
        Jacobian = []
        InitialValue (:,:) double {mustBeFinite}
        InitialSlope (:,:) double {mustBeFinite}
    end

    methods
        function obj = odeSensitivity(nv)
            arguments
                nv.?odeSensitivity
            end
            names = fieldnames(nv);
            for k = 1:numel(names)
                obj.(names{k}) = nv.(names{k});
            end
        end

        function obj = set.ParameterIndices(obj,p)
            if isempty(p)
                obj.ParameterIndices = [];
            else
                obj.ParameterIndices = p(:);
            end
        end

        function obj = set.Jacobian(obj,J)
            if isempty(J)
                obj.Jacobian = [];
            elseif isa(J,'odeJacobian')
                obj.Jacobian = J;
            else
                obj.Jacobian = odeJacobian(Jacobian=J);
            end
        end
    end

    properties(Constant,Hidden)
        % 1.0 : Initial version (R2024a)
        Version = 1.0;
    end

    methods (Hidden)
        function b = saveobj(a)
            % Save all properties to struct.
            b = ode.assignProps(a,false,"odeSensitivity");
            % Keep track of versioning information.
            b.CompatibilityHelper.versionSavedFrom = a.Version;
            b.CompatibilityHelper.minCompatibleVersion = 1.0;
        end
        function obj = complexToReal(obj,ODE)
            % We don't double the number of ParameterIndices because doing
            % so would produce a sensitivity result
            % S = [drealy/drealp, drealy/dimagp ; dimagy/drealp, dimagy/dimagp]
            % where, assuming differentiability, (Cauchy-Riemann)
            % drealy/drealp == dimagy/dimagp
            % drealy/dimagp == -dimagy/drealp
            % When we're done, we will construct the complex sensitivities
            % as S = complex(drealy/drealp,drealy/dimagp).
            if isempty(obj.ParameterIndices)
                idx = 1:2:2*numel(ODE.Parameters);
            else
                idx = 2*obj.ParameterIndices(:).'-1;
            end
            if isempty(obj.Jacobian)
                J = [];
            else
                % The complexToRealSensitivity produces a Jacobian that is
                % [real(J);imag(J)] rather than the more usual
                % [real(J),-imag(J);imag(J),real(J)].
                J = complexToRealSensitivity(obj.Jacobian,ODE);
            end
            if isempty(obj.InitialValue)
                s0 = zeros(2*numel(ODE.InitialValue),numel(idx));
            else
                s0 = matlab.ode.internal.c2rMatrix(obj.InitialValue,true);
            end
            if isempty(obj.InitialSlope)
                sp0 = zeros(2*numel(ODE.InitialValue),numel(idx));
            else
                sp0 = matlab.ode.internal.c2rMatrix(obj.InitialSlope,true);
            end
            obj = odeSensitivity( ...
                Jacobian=J, ...
                InitialValue=s0, ...
                InitialSlope=sp0, ...
                ParameterIndices=idx);
        end
    end

    methods (Hidden,Static)
        function b = loadobj(a)
            if odeSensitivity.Version < a.CompatibilityHelper.minCompatibleVersion
                warning(message("MATLAB:ode:MinVersionIncompat","odeSensitivity"));
                b = odeSensitivity;
                return
            end
            b = ode.assignProps(a,true,"odeSensitivity");
        end
    end

end

%    Copyright 2023-2024 MathWorks, Inc.