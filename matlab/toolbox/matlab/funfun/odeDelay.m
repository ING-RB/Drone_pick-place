classdef (Sealed = true) odeDelay
    properties
        History {mustBeFcnOrNumeric(History)} = [] % History for DDE
        ValueDelay {mustBeFcnOrNumeric(ValueDelay)} = [] % Solution delays for DDE
        SlopeDelay {mustBeFcnOrNumeric(SlopeDelay)} = [] % Derivative delays for DDE
    end

    methods
        function obj = odeDelay(nv)
            arguments
                nv.?odeDelay
            end
            names = fieldnames(nv);
            for k = 1:numel(names)
                obj.(names{k}) = nv.(names{k});
            end
        end

        function obj = set.History(obj, val)
            if isa(val, "function_handle")
                if ( nargin(val)~=1 && nargin(val)~=2 ) || abs(nargout(val))~=1
                    error(message('MATLAB:odedelay:HistoryArgs'))
                end
            end
            if ~isempty(val) && isnumeric(val)
                val = val(:);
            end
            obj.History = val;
        end

        function obj = set.ValueDelay(obj, val)
            if isa(val, "function_handle")
                if ( nargin(val)~=2 && nargin(val)~=3 ) || abs(nargout(val))~=1
                    error(message('MATLAB:odedelay:ValueDelayArgs'))
                end
            end
            if ~isempty(val) && isnumeric(val)
                val = val(:);
            end
            obj.ValueDelay = val;
        end

        function obj = set.SlopeDelay(obj, val)
            if isa(val, "function_handle")
                if ( nargin(val)~=2 && nargin(val)~=3 ) || abs(nargout(val))~=1 
                    error(message('MATLAB:odedelay:SlopeDelayArgs'))
                end
            end
            if ~isempty(val) && isnumeric(val)
                val = val(:);
            end
            obj.SlopeDelay = val;
        end
    end

    methods(Hidden, Access=?ode)
        function obj = complexToReal(obj,ODE)
            assert(~ODE.ComplexToRealParameters);
            % convert history
            if ~isempty(obj.History)
                % split history [real(h) ; imag(h)]
                history = obj.History;
                if isnumeric(history)
                    obj.History = matlab.ode.internal.c2rVector(history);
                else % function
                    nin = nargin(history);
                    % ODE.ComplexToRealParmeters can never be used in this
                    % branch, but would be included here if so.
                    if nin == 2
                        obj.History = @(t,p) matlab.ode.internal.c2rVector(history(t,p));
                    else
                        obj.History = @(t) matlab.ode.internal.c2rVector(history(t));
                    end
                end
            end
            % convert value delays
            if ~isempty(obj.ValueDelay)
                % return delay real(t)
                del = obj.ValueDelay;
                if isnumeric(obj.ValueDelay)
                    obj.ValueDelay = real(del);
                else % function
                    nin = nargin(del);
                    % ODE.ComplexToRealParmeters can never be used in this
                    % branch, but would be included here if so.
                    if nin == 3
                        obj.ValueDelay = @(t,y,p) i3c2r(del,t,y,p);
                    else % (t,y)
                        obj.ValueDelay = @(t,y) i2c2r(del,t,y);
                    end
                end
            end
            % convert slope delays
            if ~isempty(obj.SlopeDelay)
                % return delay real(t)
                del = obj.SlopeDelay;
                if isnumeric(obj.SlopeDelay)
                    obj.SlopeDelay = real(del);
                else % function
                    nin = nargin(del);
                    % ODE.ComplexToRealParmeters can never be used in this
                    % branch, but would be included here if so.
                    if nin == 3
                        obj.SlopeDelay = @(t,y,p) i3c2r(del,t,y,p);
                    else % (t,y)
                        obj.SlopeDelay = @(t,y) i2c2r(del,t,y);
                    end
                end
            end
        end
    end

    properties(Constant,Hidden)
        % 1.0 : Initial version (R2025a)
        Version = 1.0;
    end

    methods (Hidden)
        function b = saveobj(a)
            % Save all properties to struct.
            b = ode.assignProps(a,false,"odeDelay");
            % Keep track of versioning information.
            b.CompatibilityHelper.versionSavedFrom = a.Version;
            b.CompatibilityHelper.minCompatibleVersion = 1.0;
        end
    end

    methods (Hidden,Static)
        function b = loadobj(a)
            if odeEvent.Version < a.CompatibilityHelper.minCompatibleVersion
                warning(message("MATLAB:ode:MinVersionIncompat","odeDelay"));
                b = odeDelay;
                return
            end
            b = ode.assignProps(a,true,"odeDelay");
        end
    end


end

function mustBeFcnOrNumeric(a)
    if ~(isa(a,'function_handle') || isnumeric(a))
        error(message('MATLAB:odedelay:InvalidDelayProperty'))
    end
    if isnumeric(a)
        mustBeFinite(a);
    end
end

function v = i2c2r(fun,t,y)
    % fun(t,p) converting p
    y = matlab.ode.internal.r2cVector(y);
    v = real(fun(t,y));
end

function v = i3c2r(fun,t,y,p)
    % fun(t,y,p) converting y but not p
    y = matlab.ode.internal.r2cVector(y);
    v = real(fun(t,y,p));
end

%    Copyright 2024 MathWorks, Inc.