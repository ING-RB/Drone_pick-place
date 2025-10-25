classdef trajectoryGeneratorFrenet < nav.algs.internal.InternalAccess
%

%   Copyright 2020-2023 The MathWorks, Inc.

%#codegen

    properties (Hidden,Constant)
        DefaultTimeResolution = 0.1;
    end

    properties
        ReferencePath

        TimeResolution = trajectoryGeneratorFrenet.DefaultTimeResolution;
    end

    methods
        function obj = trajectoryGeneratorFrenet(referencePath, varargin)
        %
            narginchk(1,3);
            obj.ReferencePath = referencePath;

            % Parse optional arguments
            if nargin > 1
                validatestring(varargin{1},{'TimeResolution'},'trajectoryGeneratorFrenet');
                coder.internal.prefer_const(varargin{2});

                % Set optional properties
                obj.TimeResolution = varargin{2};
            end
        end

        function [frenetTrajectory, globalTrajectory] = connect(obj, initialState, terminalState, timeSpan)
        %

            narginchk(4,4);

            % Organize inputs into two sets of N-row state pairs
            [f0,f1,tF] = obj.parseTrajInputs(initialState,terminalState,timeSpan);

            % Generate trajectories in Frenet coordinates
            frenetTrajectory = obj.connectPairs(f0, f1, obj.TimeResolution, tF);

            if nargout == 2
                % Convert trajectories to global coordinates if requested
                globalTrajectory = frenetTrajectory;
                for i = 1:numel(frenetTrajectory)
                    globalTrajectory(i).Trajectory = obj.ReferencePath.frenet2global(frenetTrajectory(i).Trajectory);
                end
            end
        end

        function [globalState,frenetState,lateralTimeDerivatives] = ...
                createParallelState(obj,S,L,v,a,invertHeading)
        %

        % Validate inputs
            narginchk(5,6);
            validateattributes(S,{'numeric'},{'finite','column'},'createParallelState','s');
            n = numel(S);
            validateattributes(L,{'numeric'},{'finite','column','numel',n},'createParallelState','l');
            validateattributes(v,{'numeric'},{'finite','column','numel',n},'createParallelState','v');
            validateattributes(a,{'numeric'},{'finite','column','numel',n},'createParallelState','a');
            if nargin == 5
                invertHeading = false(n,1);
            else
                validateattributes(invertHeading,{'numeric','logical'},{'binary','column','numel',n},'createParallelState','invertHeading');
            end

            % Construct a set of Frenet states using the provided S,L and with
            % dummy longitudinal velocity/acceleration.
            frenetState = zeros(n,6);
            frenetState(:,1) = S;
            frenetState(:,4) = L;
            frenetState(:,2) = 1;

            % Convert dummy states to global
            globalState = obj.ReferencePath.frenet2global(frenetState);

            % Invert heading and curvature
            globalState(invertHeading,3) = robotics.internal.wrapToPi(globalState(invertHeading,3)+pi);
            globalState(invertHeading,4) = -globalState(invertHeading,4);

            % Populate velocity/acceleration
            globalState(:,5) = v;
            globalState(:,6) = a;

            % Convert back to Frenet
            [frenetState, lateralTimeDerivatives] = obj.ReferencePath.global2frenet(globalState, frenetState(:,1));
        end

        function cObj = copy(obj)
        %
            cObj = trajectoryGeneratorFrenet(copy(obj.ReferencePath), ...
                                             'TimeResolution', obj.TimeResolution);
        end

        function set.ReferencePath(obj, refPathObj)
        %
            validateattributes(refPathObj, {'nav.algs.internal.FrenetReferencePath'}, {'scalar'},'trajectoryGeneratorFrenet','referencePath');
            obj.ReferencePath = refPathObj;
        end

        function set.TimeResolution(obj, resolution)
        %
            validateattributes(resolution,{'numeric'},{'scalar','real','positive','nonnan','finite'},'trajectoryGeneratorFrenet','TimeResolution');
            obj.TimeResolution = resolution;
        end
    end

    methods (Access = ?nav.algs.internal.InternalAccess, Static)
        function trajectories = connectPairs(f0,f1,dt,timeSpan)
        %

        %connectPairs Connect N pairs of start/end states
        % Number of expected trajectories
            numTraj = size(f0,1);

            % Preallocate trajectory variables
            longitudinalTrajectories = repmat({nav.algs.internal.QuinticQuarticTrajectory([0 0 0],[1 1 1],1)},numTraj,1);
            lateralTrajectories = repmat({nav.algs.internal.QuinticQuarticTrajectory([0 0 0],[1 1 1],1)},numTraj,1);

            trajectories = trajectoryGeneratorFrenet.allocateTrajectories(dt,timeSpan);

            for trajIdx = 1:numTraj
                % Extract longitudinal boundary conditions
                sV0 = f0(trajIdx,1:3);
                sV1 = f1(trajIdx,1:3);
                tFinal = timeSpan(trajIdx);

                % Fit quintic/quartic polynomial
                longitudinalTrajectories{trajIdx} = ...
                    nav.algs.internal.QuinticQuarticTrajectory(sV0,sV1,tFinal);

                % Evaluate longitudinal trajectory at evenly spaced
                % intervals wrt time
                t = (dt:dt:dt*(ceil(tFinal/dt)+1))'-dt;
                sV = longitudinalTrajectories{trajIdx}.evaluate([0 1 2], t)';

                % Extract longitudinal boundary conditions
                dV0 = f0(trajIdx,4:6);
                dV1 = f1(trajIdx,4:6);
                dsMax = sV(end,1)-sV(1);

                % Fit quintic/quartic polynomial
                lateralTrajectories{trajIdx} = ...
                    nav.algs.internal.QuinticQuarticTrajectory(dV0,dV1,dsMax);

                % Evaluate lateral trajectory based on arclength
                ds = sV(:,1)-sV(1);
                dV = lateralTrajectories{trajIdx}.evaluate([0 1 2], ds)';

                % Combine and populate output struct
                trajectories(trajIdx).Trajectory = reshape([sV dV],[],6);
                trajectories(trajIdx).Times = t;
            end
        end

        function trajectories = allocateTrajectories(dt,timeSpan)
        %

        % Find max timespan and number of trajectories
            coder.internal.prefer_const(timeSpan);
            maxTime = max(timeSpan);
            numTraj = numel(timeSpan);

            % Convert max time to max number of steps
            maxSteps = int32(ceil(maxTime/dt)+1);

            % Allocate placeholder values and apply upper bounds
            if coder.target('MATLAB')
                % Varsize on by default
                traj = [];
                t = [];
                trajectories = repmat(struct('Trajectory',traj,'Times',t), numTraj, 1);
            else
                if coder.internal.isConst(timeSpan)
                    % Entire dimensions of output struct will be compile-time
                    % constant if nTraj is constant.
                    nTraj = numel(timeSpan);
                    trajs = cell(nTraj,1);
                    times = cell(nTraj,1);
                    coder.unroll(coder.internal.isConst(nTraj))
                    for i = 1:nTraj
                        n = ceil(timeSpan(i)/dt)+1;
                        trajs{i} = zeros(n,6);
                        times{i} = zeros(n,1);
                    end
                    trajectories = struct('Trajectory',trajs,'Times',times);
                else
                    % Output trajectory dimensions are controlled by the user's
                    % inputs. If DynamicMemoryAllocation is turned off, the
                    % timeSpan and nTraj inputs provided by the user must be
                    % compile-time constant or have known upper limits.
                    traj = [];
                    t = [];
                    if coder.internal.isConst(maxSteps)
                        coder.varsize('traj',[maxSteps, 6],[1 0]);
                        coder.varsize('t',[maxSteps, 1],[1 0]);
                    else
                        coder.varsize('traj',[inf, 6],[1 0]);
                        coder.varsize('t',[inf, 1],[1 0]);
                    end
                    trajectories = repmat(struct('Trajectory',traj,'Times',t), numTraj, 1);
                end
            end
        end

        function [x0,x1,tF] = parseTrajInputs(initState, termState, timeSpan)
        %

        %parseTrajInputs Parses and organizes the inputs into two sets of N-row state pairs

        % Lock down size and span information immediately
            coder.internal.prefer_const(timeSpan);
            numInit = size(initState,1);
            numTerm = size(termState,1);
            numTime = numel(timeSpan);
            numTraj = max([numInit, numTerm, numTime]);

            % Validate inputs
            trajectoryGeneratorFrenet.validateConnect(initState, termState, timeSpan);

            % Attempt to expand inputs
            x0 = trajectoryGeneratorFrenet.expandInput(initState,numTraj,'States');
            x1 = trajectoryGeneratorFrenet.expandInput(termState,numTraj,'States');
            tF = trajectoryGeneratorFrenet.expandInput(timeSpan(:),numTraj,'Times');
        end

        function expandedInput = expandInput(input,numTraj,varType)
            n = size(input,1);
            coder.internal.assert(any(n == [1 numTraj]), ['nav:navalgs:trajectorygeneratorfrenet:MismatchedNum' varType]);
            if coder.internal.isConstTrue(n ~= 1)
                % This input cannot be resized, as it is already non-scalar and
                % has passed the validation size check.
                expandedInput = input;
            else
                expandedInput = repmat(input,numTraj/n,1);
            end
        end

        function validateConnect(initState, termState, time)
        %

        %validateConnect Validate type/size of inputs to connect method
        %
        %   The first column of terminal state is allowed to be nan,
        %   reducing boundary constraints by 1 and allowing us to use 4th
        %   order polynomial to satisfy velocity, acceleration, and initial
        %   position.

        % Verify attributes of initial state
            validateattributes(initState,{'numeric'},{'size',[nan 6],'finite','nonnan'},'connect','initState');

            % Verify size of terminal states
            assert(size(termState,2) == 6);
            % Verify terminal states form valid 4th/5th order boundary conditions
            validateattributes(termState(:,2:end),{'numeric'},{'nonnan','finite'},'connect','termState');

            % Verify the times are valid
            validateattributes(time,{'numeric'},{'finite','nonempty','vector','positive'},'connect','time');
        end
    end

    methods (Static, Hidden)
        function result = matlabCodegenSoftNontunableProperties(~)
        %matlabCodegenSoftNontunableProperties Mark properties as nontunable during codegen
        %
        % Marking properties as 'Nontunable' indicates to Coder that
        % the property should be made compile-time Constant.
            result = {'TimeResolution'};
        end
    end
end
