classdef (Sealed=true) odeEvent
    properties
        EventFcn function_handle % Events are zero crossings of EventFcn components.
        Direction matlab.ode.EventDirection = "both" % Events occur when zero crossings occur while increasing, decreasing, or both.
        Response matlab.ode.EventAction = "proceed" % When events are detected, either stop, proceed, or call the callback function.
        CallbackFcn function_handle % When the Response is "callback", call this function.
    end
    properties (Hidden, Access = {?ode})
        PostponeValidation = false; %#ok<*MCSUP>
        response_int = 1 % faster equivalent for EventAction.proceed
        direction_int = 0 % faster equivalent for EventDirection.both
        eventfcnnargin
    end
    properties (Hidden)
        ComplexToRealSolution = false;
        ComplexToRealParameters = false;
    end
    methods
        function obj = odeEvent(nv)
            arguments
                nv.?odeEvent
            end
            names = fieldnames(nv);
            for k = 1:numel(names)
                obj.(names{k}) = nv.(names{k});
            end
        end
        function obj = set.Direction(obj,d)
            obj.Direction = d;
            obj.direction_int = double(d);
        end
        function obj = set.Response(obj,r)
            obj.Response = r;
            obj.response_int = double(r);
        end
        function obj = set.EventFcn(obj,f)
            obj.EventFcn = f;
            if ~isempty(f)
                obj.eventfcnnargin = nargin(f);
            else
                obj.eventfcnnargin = nan;
            end
        end
    end

    methods (Hidden,Access={?ode,?matlab.ode.internal.Solver,?matlab.ode.internal.ProblemPackager})
        function [value,terminal,direction] = evaluateStandard(obj,t,y,p)
            enarg = obj.eventfcnnargin;
            if obj.ComplexToRealSolution
                y = matlab.ode.internal.r2cVector(y);
            end
            if enarg > 2 || (enarg == -1 && ~isequal(p,[]))
                if obj.ComplexToRealParameters
                    p = matlab.ode.internal.r2cVector(p);
                end
                value = obj.EventFcn(t,y,p);
            else
                value = obj.EventFcn(t,y);
            end
            value = real(value);
            value = value(:);
            if nargout > 1
                [terminal,direction] = getTerminalAndDirection(obj,value);
            end
        end
        function [value,terminal,direction] = evaluateImplicitOrDelay(obj,t,y,yp,p)
            enarg = obj.eventfcnnargin;
            if obj.ComplexToRealSolution
                y = matlab.ode.internal.r2cVector(y);
                yp = matlab.ode.internal.r2cArray(yp);
            end
            if enarg > 3 || (enarg == -1 && ~isequal(p,[]))
                value = obj.EventFcn(t,y,yp,p);
            else
                value = obj.EventFcn(t,y,yp);
            end
            value = real(value);
            value = value(:);
            if nargout > 1
                [terminal,direction] = getTerminalAndDirection(obj,value);
            end
        end
        function [value,terminal,direction] = evaluateNeutralDelay(obj,t,y,ydel,ypdel,p)
            enarg = obj.eventfcnnargin;
            if obj.ComplexToRealSolution
                y = matlab.ode.internal.r2cVector(y);
                ydel = matlab.ode.internal.r2cArray(ydel);
                ypdel = matlab.ode.internal.r2cArray(ypdel);
            end
            if enarg > 4 || (enarg == -1 && ~isequal(p,[]))
                value = obj.EventFcn(t,y,ydel,ypdel,p);
            else
                value = obj.EventFcn(t,y,ydel,ypdel);
            end
            value = real(value);
            value = value(:);
            if nargout > 1
                [terminal,direction] = getTerminalAndDirection(obj,value);
            end
        end
        function p = isCallback(obj,ie)
            if isscalar(obj.Response)
                p = obj.Response == matlab.ode.EventAction.callback;
            else
                p = obj.Response(ie) == matlab.ode.EventAction.callback;
            end
        end
        function p = isTerminal(obj,ie)
            if isscalar(obj.Response)
                p = obj.Response == matlab.ode.EventAction.stop;
            else
                p = obj.Response(ie) == matlab.ode.EventAction.stop;
            end
        end
        function [stop,teCallback,yeCallback,ieCallback] = getCallbackInfo(obj,te,ye,ie)
            % Sort through the possibilities of multiple events in a step.
            if isempty(ie)
                % Not an event but an integration failure.
                stop = true;
                teCallback = zeros(0,1,"like",te);
                yeCallback = zeros(size(ye,1),0,"like",ye);
                ieCallback = zeros(0,1,"like",ie);
                return
            end
            % If multiple events have occurred in a step, all events prior
            % to the last te value must "proceed" events. Otherwise, the
            % integration would have terminated at the earlier event.
            n = length(ie);
            teCallback = te(end);
            yeCallback = ye(:,end);
            while n >= 2 && te(n - 1) == teCallback
                n = n - 1;
            end
            ieCallback = ie(n:end);
            stop = any(obj.isTerminal(ieCallback));
            ieCallback = ieCallback(obj.isCallback(ieCallback));
        end
        function [varargout] = execCallbackFcn(obj,varargin)
            % Permissively execute the callback function with respect to
            % the number of inputs and outputs:
            % [stop,ye,parameters] = callbackFcn(te,ye,ie,parameters)
            % This function always provides all three output values.
            % varargout{3} will be [] when parameters are not used.
            %
            % Initialize outputs with default values in case we don't have
            % anything to replace them with.
            varargout{1} = true; % Default is to stop the integration.
            varargout{2} = varargin{2}; % ye passes through unchanged.
            if nargin >= 5
                varargout{3} = varargin{4}; % parameters pass through unchanged.
            else
                varargout{3} = [];
            end
            if isempty(obj.CallbackFcn)
                % Quick return for missing callback function.
                warning(message('MATLAB:ode:NoCallbackFcn',sprintf('%g',varargin{1})));
                return
            end
            nin = nargin(obj.CallbackFcn);
            if nin == -1
                % Pass all inputs to varargin callback.
                nin = nargin - 1;
            end
            nout = nargout(obj.CallbackFcn);
            if nout == -1
                % Anonymous and varargout functions will be called with one output.
                nout = 1;
            end
            if obj.ComplexToRealSolution && nin >= 2
                % Convert split real to complex before calling the function.
                varargin{2} = matlab.ode.internal.r2cVector(varargin{2});
                if nin >= 4 && obj.ComplexToRealParameters
                    varargin{4} = matlab.ode.internal.r2cVector(varargin{4});
                end
            end
            % Call the callback function.
            [varargout{1:nout}] = obj.CallbackFcn(varargin{1:nin});
            if obj.ComplexToRealSolution
                % Convert complex results to split real.
                if nout >= 2
                    varargout{2} = matlab.ode.internal.c2rVector(varargout{2});
                    if nout >= 3 && obj.ComplexToRealParameters
                        varargout{3} = matlab.ode.internal.c2rVector(varargout{3});
                    end
                end
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
            b = ode.assignProps(a,false,"odeEvent");
            % Keep track of versioning information.
            b.CompatibilityHelper.versionSavedFrom = a.Version;
            b.CompatibilityHelper.minCompatibleVersion = 1.0;
        end
    end

    methods (Hidden,Access=?ode)
        function obj = complexToReal(obj,ODE)
            % Because this object already has wrappers around the user
            % functions, it doesn't wrap them. Rather, the wrappers perform
            % the conversions as needed.
            obj.ComplexToRealSolution = true;
            obj.ComplexToRealParameters = ODE.ComplexToRealParameters;
        end
    end

    methods(Access=private)
        function [terminal,direction] = getTerminalAndDirection(obj,value)
            nv = numel(value);
            terminal = false(nv,1);
            nr = numel(obj.response_int);
            if nr ~= 1 && nr ~= nv
                error(message('MATLAB:ode:ResponseSizeMismatch',nv,numel(obj.Response)));
            end
            terminal(:) = obj.response_int ~= 1; % 1 for proceed
            direction = zeros(nv,1);
            nd = numel(obj.direction_int);
            if nd ~= 1 && nd ~= nv
                error(message('MATLAB:ode:DirectionSizeMismatch',nv,numel(obj.Direction)));
            end
            direction(:) = obj.direction_int;
        end
    end

    methods (Hidden,Static)
        function b = loadobj(a)
            if odeEvent.Version < a.CompatibilityHelper.minCompatibleVersion
                warning(message("MATLAB:ode:MinVersionIncompat","odeEvent"));
                b = odeEvent;
                return
            end
            if isfield(a,'Direction') && isstruct(a.Direction)
                % Direction enum not available
                warning(message("MATLAB:ode:DefaultIncompat","Direction"));
                a.Direction = matlab.ode.EventDirection(0); % both
            end
            if isfield(a,'Response') && isstruct(a.Response)
                % Response enum not available
                warning(message("MATLAB:ode:DefaultIncompat","Response"));
                a.Response = matlab.ode.EventAction(1); % proceed
            end
            b = ode.assignProps(a,true,"odeEvent");
        end
    end

end

%    Copyright 2023-2024 MathWorks, Inc.
