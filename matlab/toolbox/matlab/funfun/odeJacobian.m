classdef (Sealed = true) odeJacobian
    properties
        Jacobian % Jacobian function [ function_handle | constant matrix | cell array ]
        SparsityPattern = [] % Jacobian sparsity pattern [ sparse matrix | cell array ]
    end
    methods
        function obj = odeJacobian(nv)
            arguments
                nv.?odeJacobian
            end
            names = fieldnames(nv);
            for k = 1:numel(names)
                obj.(names{k}) = nv.(names{k});
            end
        end
        function obj = set.Jacobian(obj,J)
            % We don't worry about what J looks like here. The ODE solver
            % will have to decide what to do with it, as the odeJacobian
            % object doesn't have access to the ODE definition to bind
            % parameters or whatnot.
            if isa(J,'function_handle') || isnumeric(J) || iscell(J)
                if (iscell(J) && numel(J) ~= 2) || ...
                        (iscell(J) && (~isnumeric(J{1}) || ~isnumeric(J{2})))
                    error(message("MATLAB:ode:JacobianCellSize"));
                end
                obj.Jacobian = J;
            else
                error(message("MATLAB:ode:InvalidJacobian"));
            end
        end
        function obj = set.SparsityPattern(obj,J)
            % Basic checks for the type of the sparisty pattern passed.
            if isnumeric(J) || islogical(J) || iscell(J)
                if iscell(J) && numel(J) ~= 2 || ...
                        (iscell(J) && ( ...
                        ~(isnumeric(J{1}) || islogical(J{1})) || ...
                        ~(isnumeric(J{2}) || islogical(J{2}))))
                    error(message("MATLAB:ode:SparsityCellSize"));
                end
                obj.SparsityPattern = J;
            else
                error(message("MATLAB:ode:InvalidSparsityPattern"))
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
            b = ode.assignProps(a,false,"odeJacobian");
            % Keep track of versioning information.
            b.CompatibilityHelper.versionSavedFrom = a.Version;
            b.CompatibilityHelper.minCompatibleVersion = 1.0;
        end
    end

    methods (Hidden,Static)
        function b = loadobj(a)
            if odeJacobian.Version < a.CompatibilityHelper.minCompatibleVersion
                warning(message("MATLAB:ode:MinVersionIncompat","odeJacobian"));
                b = odeJacobian;
                return
            end
            b = ode.assignProps(a,true,"odeJacobian");
        end
    end

    methods (Hidden,Access={?ode,?odeSensitivity})
        function obj = complexToReal(obj,ODE)
            % Returns a new Jacobian object where the complex Jacobian
            % evaluates to the interleaved real form(s).
            J = obj.Jacobian;

            if ODE.EquationType == matlab.ode.EquationType.fullyimplicit
                if iscell(J)
                    J{1} = matlab.ode.internal.c2rMatrix(J{1});
                    J{2} = matlab.ode.internal.c2rMatrix(J{2});
                    obj.Jacobian = J;
                elseif isnumeric(J)
                    obj.Jacobian = matlab.ode.internal.c2rMatrix(J);
                elseif nargin(J) == 4
                    % No supported fully-implicit solver requires
                    % conversion of parameters. If one is added, here is
                    % where we would conditionally assign a wrapper for
                    % that case that accepts 4 inputs and converts inputs
                    % 2, 3, and 4. Following the existing naming pattern,
                    % it would be i4c234o2(J,t,y,yp,p).
                    obj.Jacobian = @(t,y,yp,p)i4c23o2(J,t,y,yp,p);
                else
                    obj.Jacobian = @(t,y,yp)i3c23o2(J,t,y,yp);
                end
                if ~isempty(obj.SparsityPattern)
                    % The sparsity pattern matrix is real even if the
                    % problem is complex. S(i,j) = 1 implies that J(i,j)
                    % might be nonzero either in real or imaginary part or
                    % both. We use the sparsity pattern mode of c2rMatrix
                    % because otherwise it would produce zeros
                    % corresponding to the imaginary parts.
                    columnwise = false;
                    sparsityPattern = true;
                    obj.SparsityPattern = { ...
                        matlab.ode.internal.c2rMatrix(obj.SparsityPattern{1},columnwise,sparsityPattern), ...
                        matlab.ode.internal.c2rMatrix(obj.SparsityPattern{2},columnwise,sparsityPattern)};
                end
            else
                if isnumeric(J)
                    obj.Jacobian = matlab.ode.internal.c2rMatrix(J);
                elseif nargin(J) == 3
                    if ODE.ComplexToRealParameters
                        obj.Jacobian = @(t,y,p)i3c23(J,t,y,p);
                    else
                        obj.Jacobian = @(t,y,p)i3c2(J,t,y,p);
                    end
                else
                    obj.Jacobian = @(t,y)i2c2(J,t,y);
                end
                if ~isempty(obj.SparsityPattern)
                    columnwise = false;
                    sparsityPattern = true;
                    obj.SparsityPattern = matlab.ode.internal.c2rMatrix(obj.SparsityPattern,columnwise,sparsityPattern);
                end
            end
        end
        function obj = complexToRealSensitivity(obj,~)
            % Converts a sensitivity Jacobian to columnwise real form.
            J = obj.Jacobian;
            columnwise = true;
            % Note that p is always converted for sensitivity analysis if
            % it is supplied.
            if isnumeric(J)
                obj.Jacobian = matlab.ode.internal.c2rMatrix(J,columnwise);
            elseif nargin(J) == 3
                % Note that we currently always convert complex parameters
                % to real when computing sensitivities.
                obj.Jacobian = @(t,y,p)i3c23sens(J,t,y,p);
            else
                obj.Jacobian = @(t,y)i2c2sens(J,t,y);
            end
            if ~isempty(obj.SparsityPattern)
                sparsityPattern = true;
                obj.SparsityPattern = matlab.ode.internal.c2rMatrix(obj.SparsityPattern,columnwise,sparsityPattern);
            end
        end
    end
end

function X = i2c2(J,t,y)
% X = J(t,y) with conversion of y.
y = matlab.ode.internal.r2cVector(y);
X = J(t,y);
X = matlab.ode.internal.c2rMatrix(X);
end

function X = i3c2(J,t,y,p)
% X = J(t,y,p) with conversion of y but not p.
y = matlab.ode.internal.r2cVector(y);
X = J(t,y,p);
X = matlab.ode.internal.c2rMatrix(X);
end

function X = i3c23(J,t,y,p)
% X = J(t,y,p) with conversion of both y and p.
y = matlab.ode.internal.r2cVector(y);
p = matlab.ode.internal.r2cVector(p);
X = J(t,y,p);
X = matlab.ode.internal.c2rMatrix(X);
end

function X = i2c2sens(J,t,y)
% X = J(t,y) for sensitivity Jacobian evaluation.
% The output is the columnwise (half size) real form.
y = matlab.ode.internal.r2cVector(y);
X = J(t,y);
X = matlab.ode.internal.c2rMatrix(X,true);
end

function X = i3c23sens(J,t,y,p)
% X = J(t,y,p) for sensitivity Jacobian evaluation. y and p are converted.
% The output is the columnwise (half size) real form.
y = matlab.ode.internal.r2cVector(y);
p = matlab.ode.internal.r2cVector(p);
X = J(t,y,p);
X = matlab.ode.internal.c2rMatrix(X,true);
end

function [X1,X2] = i3c23o2(J,t,y,yp)
% X = J(t,y,yp) and [X1,X2] = J(t,y,yp) with conversion of both y and yp.
% This is a nested function so nargout == 2.
y = matlab.ode.internal.r2cVector(y);
yp = matlab.ode.internal.r2cVector(yp);
[X1,X2] = J(t,y,yp);
X1 = matlab.ode.internal.c2rMatrix(X1);
X2 = matlab.ode.internal.c2rMatrix(X2);
end

function [X1,X2] = i4c23o2(J,t,y,yp,p)
% [X1,X2] = J(t,y,yp,p) with conversion of both y and
% yp but not p.
y = matlab.ode.internal.r2cVector(y);
yp = matlab.ode.internal.r2cVector(yp);
[X1,X2] = J(t,y,yp,p);
X1 = matlab.ode.internal.c2rMatrix(X1);
X2 = matlab.ode.internal.c2rMatrix(X2);
end

%    Copyright 2023-2024 MathWorks, Inc.