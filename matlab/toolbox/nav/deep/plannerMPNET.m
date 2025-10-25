classdef plannerMPNET < nav.internal.BidirectionalNeuralPlanner &...
        matlabshared.tracking.internal.CustomDisplay
%

% Copyright 2023 The MathWorks, Inc.

%#codegen

    properties(Access=public)
        ClassicalPlannerFcn function_handle
    end

    properties(Access=private)
        BeaconStates double
        ClassicalStates double
        EnableClassicalReplanning logical
    end

    properties(Hidden, Dependent)
        Environment
    end

    methods
        function obj = plannerMPNET(stateValidator, mpnet, NameValueArgs)

            arguments
                stateValidator {mustBeA(stateValidator, 'nav.StateValidator')}
                mpnet {mustBeA(mpnet, {'mpnetSE2', 'nav.internal.MPNET'})}
                NameValueArgs.MaxLearnedStates (1,1) {mustBeNumeric, mustBeInteger, mustBeNonnegative} = 50
                NameValueArgs.ClassicalPlannerFcn function_handle  = @undefined;
            end
            %

            % Check if the stateValidator and mpnet inputs are compatible
            plannerMPNET.checkStateValidatorMPNetCompatibility(stateValidator, mpnet)

            % Initialize bidirectional neural planner and class properties
            obj = obj@nav.internal.BidirectionalNeuralPlanner(stateValidator, mpnet);
            obj.MaxLearnedStates = NameValueArgs.MaxLearnedStates;

            % Codegen does not allow redefinition of function handles once
            % initialized. For codegen, ClassicalPlannerFcn can be defined
            % only once either through constructor or property setter. If
            % the user input is not provided the default classical planner
            % will be used during the call to the plan method.
            if strcmp(func2str(NameValueArgs.ClassicalPlannerFcn),'undefined')
                if coder.target('MATLAB')
                    obj.ClassicalPlannerFcn =  plannerMPNET.defaultClassicalPlannerFcn(stateValidator);
                end
            else
                obj.ClassicalPlannerFcn = NameValueArgs.ClassicalPlannerFcn;
            end

            % Check state validator property
            if ~(isprop(obj.StateValidator, 'Map') || isprop(obj.StateValidator, 'Environment')) ||...
                    (isprop(obj.StateValidator, 'Map') && isempty(obj.StateValidator.Map)) ||...
                    (isprop(obj.StateValidator, 'Environment') && isempty(obj.StateValidator.Environment))
                coder.internal.error('nav:navalgs:mpnet:InvalidStateValidator')
            end
        end

        function [pathObj, solnInfo] = plan(obj, startState, goalState)

            arguments
                obj
                startState {validateState(obj, startState, 'startState')}
                goalState {validateState(obj, goalState, 'goalState')}
            end

            %

            % Initialization
            pathObj = navPath(obj.StateSpace);
            solnInfo = plannerMPNET.solutionInfoDefaults(obj.StateSpace);
            obj.initialize();

            if obj.MaxLearnedStates>0
                %Compute MPNet path when MaxLearnedStates>0
                [path, pathFound] = planMPNetPath(obj, startState, goalState);
                if pathFound
                    pathObj = navPath(obj.StateSpace, path);
                    solnInfo.IsPathFound = true;
                end
                ind = ~isnan(obj.LearnedStates(:,1));
                solnInfo.LearnedStates = obj.LearnedStates(ind,:);
                solnInfo.BeaconStates = obj.BeaconStates;
                solnInfo.ClassicalStates = obj.ClassicalStates;
            else
                % Compute pure classical path when MaxLearnedStates=0
                [pathObj, pathFound] = obj.planClassicalPath(startState, goalState);
                solnInfo.IsPathFound = pathFound;
                solnInfo.ClassicalStates = pathObj.States;
            end
        end

        function copyObj = copy(obj)

            stateValidator = obj.StateValidator.copy();
            mpnet = obj.MotionPlanningNetwork.copy();
            copyObj = plannerMPNET(stateValidator, mpnet);
            copyObj.MaxLearnedStates    = obj.MaxLearnedStates;
            copyObj.ClassicalPlannerFcn = obj.ClassicalPlannerFcn;
        end

        function environment = get.Environment(obj)

            if isprop(obj.StateValidator, 'Map')
                environment = obj.StateValidator.Map;
            elseif isprop(obj.StateValidator, 'Environment')
                environment = obj.StateValidator.Environment;
            end
        end
    end

    methods(Access=?nav.algs.internal.InternalAccess)

        function [pathStates, pathFound] = planMPNetPath(obj, startState, goalState)
        %planMPNetPath Plan path using "MPNetPath" algorithm from
        %Qureshi, Motion Planning Networks,
        %https://doi.org/10.1109/TRO.2020.3006716.
        %
        % Inputs:
        %   startState  : Start state for path planning
        %   goalState   : Goal state for path planning
        %
        % Outputs:
        %   pathStates  : Path output matrix where each row is a state
        %   pathFound   : Boolean indicating if the path found is valid
        %

        % Neural planning
            pathSegments = obj.planNeuralPath(startState, goalState);
            [pathStates, pathFound] = obj.pathFromSegments(pathSegments);

            % Neural re-planning
            if ~pathFound
                obj.EnableClassicalReplanning = false;
                obj.BeaconStates = obj.beaconStatesFromPathSegments(pathSegments);
                while obj.NumLearnedStates < obj.MaxLearnedStates
                    pathSegments = obj.replanPath(pathSegments);
                    [pathStates, pathFound] = obj.pathFromSegments(pathSegments);
                    if pathFound
                        break
                    end
                end
            end

            % Classical re-planning
            if ~pathFound
                obj.EnableClassicalReplanning = true;
                pathSegments = obj.replanPath(pathSegments);
                [pathStates, pathFound] = obj.pathFromSegments(pathSegments);
            end
        end


        function pathSegments = planNeuralPath(obj, startState, goalState)
        % planNeuralPath Plan path using Bidirectional Neural Planner
        %
        %
        % Inputs:
        %   startState  : Start state for path planning
        %   goalState   : Goal state for path planning
        % Outputs:
        %   pathSegments: Path segments predicted by Bidirectional
        %                 Neural Planner. Each row contains first and
        %                 last state of each path segment and a flag
        %                 indicating whether it is valid based on
        %                 StateValidator.isMotionValid.
        %                 E.g., [x1,y1,theta1,x2,y2,theta2,true] means
        %                 we have path segment connecting SE(2) states
        %                 (x1,y1,theta1), (x,y2,theta2) & this path
        %                 segment is valid

            pathStates = planNeuralPath@nav.internal.BidirectionalNeuralPlanner(obj,startState, goalState);
            if isempty(pathStates)
                isSegmentValid = false;
                pathSegments = [startState, goalState, isSegmentValid];
                return
            end
            pathSegments = obj.segmentsFromPath(pathStates);
            pathSegments = obj.lazyStatesContraction(pathSegments);
        end


        function replannedPathSegments = replanPath(obj, pathSegments)
        % replanPath Replan path segments which are invalid.
        %
        % This algorithm finds the beacon states corresponding to the
        % invalid path segments and attempts to replan using these
        % beacon states as local start and goal states. At first it
        % attempts to use bidirectional neural planner for replanning.
        % After the number of learned samples exceeds
        % MaxLearnedSamples, it switches to classical planning.
        %
        % Inputs:
        %   pathSegments  : Input path segments for replanning
        % Outputs:
        %   replannedPathSegments: Updated path segments after
        %                 replanning with Bidirectional Neural Planner
        %                 or Classical Planner

        % Initialize
            beaconInd = find(~pathSegments(:,end));
            numBeacons = length(beaconInd);
            replannedPaths = cell(1, numBeacons);
            j = 1:obj.NumStateVariables; % index to keep track of start state in a motion segment
            k = obj.NumStateVariables+1:2*obj.NumStateVariables; % index to keep track of end state in a motion segment

            % Loop through beacon states for re-planning
            for i = 1:numBeacons
                startState = pathSegments(beaconInd(i), j);
                goalState = pathSegments(beaconInd(i), k);

                % Re-plan path for the current beacon states
                if ~obj.EnableClassicalReplanning
                    replannedPathSegments = obj.planNeuralPath(startState, goalState);
                    pathFound = all(replannedPathSegments(:,end));
                else
                    [pathObj, pathFound] = planClassicalPath(obj, startState, goalState);
                    replannedPathSegments = obj.segmentsFromPath(pathObj.States);
                    obj.ClassicalStates = [obj.ClassicalStates; pathObj.States];
                end

                if pathFound
                    replannedPathSegments = obj.lazyStatesContraction(replannedPathSegments);
                    replannedPaths{i} = replannedPathSegments;
                else
                    replannedPaths{i} = [];
                end
            end

            numNewPathSegments = 0;
            numSuccessfulReplans = 0;
            for i = 1:numBeacons
                numNewPathSegments = numNewPathSegments + height(replannedPaths{i});
                numSuccessfulReplans = numSuccessfulReplans + ~isempty(replannedPaths{i});
            end
            replannedPathSegments = nan(height(pathSegments)+numNewPathSegments-numSuccessfulReplans,...
                                        2*obj.NumStateVariables+1);
            j = 1;
            k = 1;
            for i = 1:height(pathSegments)
                if ~any(beaconInd==i)
                    replannedPathSegments(k,:) = pathSegments(i,:);
                    k = k+1;
                else
                    replannedPath = replannedPaths{j};
                    numReplannedSegments = height(replannedPath);
                    if ~isempty(replannedPath)
                        replannedPathSegments(k:k+numReplannedSegments-1,:) = replannedPath;
                        k = k+numReplannedSegments;
                    else
                        replannedPathSegments(k,:) = pathSegments(i,:);
                        k = k+1;
                    end
                    j = j+1;
                end
            end

            replannedPathSegments = obj.lazyStatesContraction(replannedPathSegments);
        end

        function [pathObj, pathFound] = planClassicalPath(obj, startState, goalState)
        %planClassicalPath Plan path using ClassicalPlannerFcn and
        %check if the path is valid
        %
        % Inputs:
        %   startState  : Start state for path planning
        %   goalState   : Goal state for path planning
        % Outputs:
        %   pathObj     : Path object computed by ClassicalPlannerFcn
        %   pathFound   : Boolean indicating if the path is found

            pathObj = obj.ClassicalPlannerFcn(startState, goalState);
            pathFound = true;
            for i = 1:pathObj.NumStates-1
                if ~obj.StateValidator.isMotionValid(...
                    pathObj.States(i,:), pathObj.States(i+1,:))
                    pathFound = false;
                    break
                end
            end
        end

        function lscPathSegments = lazyStatesContraction(obj, pathSegments)
        %lazyStatesContraction Remove lazy states in the path
        %
        % Connects the directly connectable non-consecutive states
        % i.e., xi and x>i+1 and removes the intermediate/lazy states
        %
        % Inputs:
        %   pathSegments  : Input path segments for lazy states
        %                   contraction
        % Outputs:
        %   lscPathSegments: Updated path segments after
        %                          lazy states contraction

            lscPathSegments = pathSegments;
            i = 1; % index to keep track of the number of motion segments
            j = 1:obj.NumStateVariables; % index to keep track of start state in a motion segment
            k = obj.NumStateVariables+1:2*obj.NumStateVariables; % index to keep track of end state in a motion segment
            numSegments = height(lscPathSegments);
            while i < numSegments
                isSegmentValid = obj.StateValidator.isMotionValid(...
                    lscPathSegments(i,j),...
                    lscPathSegments(i+1,k));
                shortcut = lscPathSegments(i,end) && ...
                    lscPathSegments(i+1,end) &&...
                    isSegmentValid;
                beacon = ~lscPathSegments(i,end) &&...
                         ~lscPathSegments(i+1,end);
                if shortcut || beacon
                    lscPathSegments(i,k) = lscPathSegments(i+1,k);
                    lscPathSegments(i+1,:) = [];
                    numSegments = numSegments-1;
                    i = i-1;
                end
                i = i+1;
            end
        end

        function [pathStates, pathFound] = pathFromSegments(obj, pathSegments)
        %pathFromSegments Get path states from path segments
        %
        % Inputs:
        %   pathSegments: Path segments and their validity. Each row
        %                 contains first and last state of each path
        %                 segment and a flag indicating whether it is
        %                 valid.
        %
        % Outputs:
        %   pathStates  : Path states extracted from pathSegments. Each
        %                 row is a state.
        %   pathFound   : true if all path segments are valid

            validSegments = pathSegments(:,end);
            pathFound = all(validSegments);
            i = obj.NumStateVariables;
            pathStates = [pathSegments(:,1:i); pathSegments(end,i+1:end-1)];
        end

        function pathSegments = segmentsFromPath(obj, pathStates)
        %segmentsFromPath Get path segments from path states
        %
        % Inputs:
        %   pathStates  : Path states extracted from pathSegments. Each
        %                 row is a state.
        %
        % Outputs:
        %   pathSegments: Path segments and their validity. Each row
        %                 contains first and last state of each path
        %                 segment and a flag indicating whether it is
        %                 valid.

            numSegments = height(pathStates)-1;
            validSegments = nan(numSegments,1);
            for i = 1:numSegments
                validSegments(i) = obj.StateValidator.isMotionValid(...
                    pathStates(i,:), pathStates(i+1,:));
            end
            pathSegments = [pathStates(1:end-1,:), pathStates(2:end,:), validSegments];
        end

        function beaconStates = beaconStatesFromPathSegments(obj, pathSegments)
        %beaconStatesFromPathSegments Get beacon states from path
        %                             segments which are invalid
        % Inputs:
        %   pathSegments: Path segments and their validity. Each row
        %                 contains first and last state of each path
        %                 segment and a flag indicating whether it is
        %                 valid
        %
        % Outputs:
        %   beaconStates: Path states corresponding to invalid path
        %                 segments. Each row contains a state.

            validSegmentsInd = pathSegments(:,end)==0;
            beaconSegments = pathSegments(validSegmentsInd, 1:end-1);
            beaconStates = [beaconSegments(:,1:obj.NumStateVariables);
                            beaconSegments(:,obj.NumStateVariables+1:end)];
        end
    end

    methods(Access=private)
        function initialize(obj)
        % initialize Initialize the internal properties to prepare the
        % object for the plan method
            if ~coder.internal.is_defined(obj.ClassicalPlannerFcn)
                obj.ClassicalPlannerFcn =  plannerMPNET.defaultClassicalPlannerFcn(obj.StateValidator);
            end
            obj.EnableClassicalReplanning = false; % Neural replanning is used for initial attempts
            obj.LearnedStates = nan(obj.MaxLearnedStates, obj.NumStateVariables);
            obj.BeaconStates = zeros(0, obj.NumStateVariables);
            classicalStates = zeros(0, obj.NumStateVariables);
            coder.varsize("classicalStates")
            obj.ClassicalStates = classicalStates;
        end

        function validateState(obj, state, name)
        % validateState Validation of start and goal states
            validateattributes(state, {'single', 'double'}, {'nonempty', 'nonnan', 'finite', 'size', [1 obj.NumStateVariables]},...
                               'plannerMPNET', name);
        end
    end

    methods(Static, Access=private)
        function planFcn = defaultClassicalPlannerFcn(stateValidator)
        %defaultClassicalPlannerFcn Get function handle to the plan
        %method of the default classical planner function
            plannerRRTStarObj = plannerRRTStar(stateValidator.StateSpace, stateValidator,...
                                               MaxConnectionDistance=1);
            planFcn = @(varargin)plannerRRTStarObj.plan(varargin{:});
        end

        function defaults = solutionInfoDefaults(stateSpace)
        % solutionInfoDefaults Define the default outputs for solution
        % info assuming no path is found
            defaults = struct(...
                'IsPathFound', false,...
                'LearnedStates', zeros(0,stateSpace.NumStateVariables),...
                'BeaconStates', zeros(0,stateSpace.NumStateVariables),...
                'ClassicalStates', zeros(0,stateSpace.NumStateVariables));
        end

        function checkStateValidatorMPNetCompatibility(stateValidator, mpnet)
        %checkStateValidatorMPNetCompatibility Check if the state
        %validator and mpnet are compatible with each other

            numStateVariables = stateValidator.StateSpace.NumStateVariables;
            numStateVariablesMPNET = mpnet.NumStateVariables;
            coder.internal.errorIf(numStateVariables~=numStateVariablesMPNET,...
                                   'nav:navalgs:mpnet:IncompatibleStateValidatorAndMPNET',...
                                   class(mpnet), mpnet.NumStateVariables)
        end
    end

    methods (Access = protected, Hidden)
        function propgrp = getPropertyGroups(obj)
        %getPropertyGroups Custom property group display
        %   This function overrides the function in the CustomDisplay
        %   base class.

            propList = struct(...
                "StateValidator", obj.StateValidator,...
                "MotionPlanningNetwork", obj.MotionPlanningNetwork,...
                "MaxLearnedStates", obj.MaxLearnedStates);

            % Display ClassicalPlannerFcn if its a custom one
            defaultPlannerFcn = plannerMPNET.defaultClassicalPlannerFcn(obj.StateValidator);
            if ~strcmp(func2str(obj.ClassicalPlannerFcn), func2str(defaultPlannerFcn))
                propList.ClassicalPlannerFcn = obj.ClassicalPlannerFcn;
            end

            % Property group to be displayed
            propgrp = matlab.mixin.util.PropertyGroup(propList);
        end
    end
end
