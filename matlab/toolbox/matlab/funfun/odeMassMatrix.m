
classdef (Sealed = true) odeMassMatrix
    properties
        MassMatrix % Mass matrix [ constant matrix | function_handle ]
        Singular(1,1) matlab.ode.Singular % Mass matrix is singular  [ yes | no | {maybe} ]
        StateDependence(1,1) matlab.ode.StateDependence % Dependence of the mass matrix on y [ none | {weak} | strong ]
        SparsityPattern % dM/dy sparsity pattern [ sparse matrix ]
    end
    methods
        function obj = odeMassMatrix(nv)
            arguments
                nv.MassMatrix
                nv.StateDependence(1,1) matlab.ode.StateDependence
                nv.Singular(1,1) matlab.ode.Singular
                nv.SparsityPattern
            end
            % Apply defaults without losing the ability to determine
            % whether they were supplied by the user.
            obj.StateDependence = matlab.ode.StateDependence.weak;
            obj.Singular = matlab.ode.Singular.maybe;
            % Assign values according to inputs.
            names = fieldnames(nv);
            for k = 1:numel(names)
                obj.(names{k}) = nv.(names{k});
            end
            if isfield(nv,"MassMatrix")
                if isnumeric(obj.MassMatrix)
                    if ~isfield(nv,"StateDependence")
                        obj.StateDependence = matlab.ode.StateDependence.none;
                    end
                    if ~isfield(nv,"Singular") && isfloat(obj.MassMatrix)
                        if issparse(obj.MassMatrix)
                            nz = nnz(obj.MassMatrix);
                            % Use double precision eps because sparse is
                            % only double or logical.
                            isSingular = nz*eps*condest(obj.MassMatrix) > 1;
                        else
                            isSingular = rank(obj.MassMatrix) < size(obj.MassMatrix,2);
                        end
                        if isSingular
                            obj.Singular = matlab.ode.Singular.yes;
                        else
                            obj.Singular = matlab.ode.Singular.no;
                        end
                    end
                elseif ~isfield(nv,"StateDependence") && nargin(obj.MassMatrix) <= 1
                    obj.StateDependence = matlab.ode.StateDependence.none;
                end
            end
        end
        function obj = set.MassMatrix(obj,M)
            if isa(M,'function_handle') || isnumeric(M)
                obj.MassMatrix = M;
            else
                error(message("MATLAB:ode:InvalidMassMatrix"));
            end
        end
    end

    properties(Constant,Hidden)
        % 1.0 : Initial version (R2023b)
        Version = 1.0;
    end

    methods (Hidden)
        function b = saveobj(a)
            % Save all properties to struct.
            b = ode.assignProps(a,false,"odeMassMatrix");
            % Keep track of versioning information.
            b.CompatibilityHelper.versionSavedFrom = a.Version;
            b.CompatibilityHelper.minCompatibleVersion = 1.0;
        end
    end

    methods (Hidden,Static)
        function b = loadobj(a)
            if odeMassMatrix.Version < a.CompatibilityHelper.minCompatibleVersion
                warning(message("MATLAB:ode:MinVersionIncompat","odeMassMatrix"));
                b = odeMassMatrix;
                return
            end
            b = ode.assignProps(a,true,"odeMassMatrix");
        end
    end

    methods (Hidden,Access=?ode)
        function obj = complexToReal(obj,ODE)
            M = obj.MassMatrix;
            if isnumeric(M)
                obj.MassMatrix = matlab.ode.internal.c2rMatrix(M);
            elseif nargin(M) == 3
                % M(t,y,p)
                if ODE.ComplexToRealParameters
                    obj.MassMatrix = @(t,y,p)i3c23(M,t,y,p);
                else
                    obj.MassMatrix = @(t,y,p)i3c2(M,t,y,p);
                end
            elseif nargin(M) == 2
                if obj.StateDependence == matlab.ode.StateDependence.none && ~ODE.ComplexToRealParameters
                    % M(t,p) without sensitivity analysis.
                    obj.MassMatrix = @(t,p)i2c0(M,t,p);
                else
                    % M(t,y) and M(t,p) with sensitivity analysis.
                    obj.MassMatrix = @(t,y)i2c2(M,t,y);
                end
            else
                obj.MassMatrix = @(t)i1c0(M,t);
            end
            if ~isempty(obj.SparsityPattern)
                columnwise = false;
                sparsityPattern = true;
                obj.SparsityPattern = matlab.ode.internal.c2rMatrix(obj.SparsityPattern,columnwise,sparsityPattern);
            end
        end
    end

end

function M = i3c23(Mfcn,t,y,p)
% M(t,y,p) with conversion of y and p
y = matlab.ode.internal.r2cVector(y);
p = matlab.ode.internal.r2cVector(p);
M = matlab.ode.internal.c2rMatrix(Mfcn(t,y,p));
end

function M = i3c2(Mfcn,t,y,p)
% M(t,y,p) with conversion of y but not p
y = matlab.ode.internal.r2cVector(y);
M = matlab.ode.internal.c2rMatrix(Mfcn(t,y,p));
end

function M = i2c0(Mfcn,t,p)
% M(t,p) with output conversion only
M = matlab.ode.internal.c2rMatrix(Mfcn(t,p));
end

function M = i2c2(Mfcn,t,y)
% M(t,y) with conversion of y
y = matlab.ode.internal.r2cVector(y);
M = matlab.ode.internal.c2rMatrix(Mfcn(t,y));
end

function M = i1c0(Mfcn,t)
% M(t) with output conversion only
M = matlab.ode.internal.c2rMatrix(Mfcn(t));
end

%    Copyright 2023-2024 MathWorks, Inc.

