classdef ShortenpathImpl < nav.algs.internal.InternalAccess
% This Class is for internal use only. It may be removed in the future.

% This is a helper class that has implementation of shortenpath feature.

%   Copyright 2024 The MathWorks, Inc.

%#codegen

    properties
        StateValidator
        Path
    end

    methods
        function obj=ShortenpathImpl(path, stateValidator)
            obj.Path = path;
            obj.StateValidator = stateValidator;
        end

        function shortPath = shorten(obj)
        % shorten shorten the path

        % skip stateValidation in supported state spaces and state
        % validators.
            skipStateValidationInStateSpaceAndValidator(obj);

            % Restore SkipStateValidation in stateSpace and StateValidator
            % if shortening fails.
            if coder.target('MATLAB')
                cleaner = onCleanup(@()cleanUp(obj));
            end

            shortenedStates = obj.Path.States;
            numStates = height(shortenedStates);
            isStatePruned = true(numStates,1);
            % Do not prune the start state and the goal state
            isStatePruned([1, end]) = false;

            startNode = 1;
            evaluationNode = 2;

            % 1. Initialize the algorithm by setting the 'startNode' to 1
            %    'evaluationNode' to 2.
            % 2. Check if motion is valid between the pose at 'startNode' and
            %    'evaluationNode'.
            % 3. If the motion is valid, increment the 'evaluationNode' by 1
            %    to evaluate the next pose. If the motion is not valid, set
            %    'startNode' to the pose just before the current
            %    'evaluationNode' (i.e., 'evaluationNode' - 1) and add this
            %    pose to the list of non-pruned states.
            % 4. Continue this loop until the 'evaluationNode' reaches the
            %    total number of states in the path.

            while evaluationNode <= numStates
                % Checking the validity of path between two selected states
                isValid = isMotionValid(obj.StateValidator, ...
                                        shortenedStates(startNode,:), shortenedStates(evaluationNode,:));
                % If motion is invalid between startNode and evaluationNode, then do
                % not prune the state before the evaluationNode.
                if ~isValid
                    if (evaluationNode - startNode) == 1
                        coder.internal.error('nav:navalgs:shortenpath:MotionInvalid');
                    end
                    isStatePruned(evaluationNode-1) = false;
                    startNode = evaluationNode-1;
                else
                    evaluationNode = evaluationNode + 1;
                end
            end

            % create a navPath object with the shortened path
            maxStates = obj.Path.MaxNumStates;
            shortPath = navPath(obj.StateValidator.StateSpace, shortenedStates(~isStatePruned,:), maxStates);
        end

        function cleanUp(obj)
        % cleanUp To clean up after shortenpath
            svInternal = obj.StateValidator;
            ssInternal = svInternal.StateSpace;
            switch class(ssInternal)
              case 'stateSpaceSE2'
                ssInternal.SkipStateValidation = false;
              case 'stateSpaceDubins'
                ssInternal.SkipStateValidation = false;
              case 'stateSpaceReedsShepp'
                ssInternal.SkipStateValidation = false;
              case 'manipulatorStateSpace'
                ssInternal.SkipStateValidation = false;
              case 'stateSpaceSE3'
                ssInternal.SkipStateValidation = false;
            end
            if isa(obj.StateValidator, 'validatorOccupancyMap') || ...
                    isa(obj.StateValidator, 'validatorOccupancyMap3D') || ...
                    isa(obj.StateValidator, 'manipulatorCollisionBodyValidator')
                obj.StateValidator.SkipStateValidation = false;
            end
        end

        function skipStateValidationInStateSpaceAndValidator(obj)
        % skipStateValidationInStateSpaceAndValidator skip
        % stateValidation in supported state spaces and state
        % validators.

        % For performance improvement, skip further state validation
        % if validator is validatorOccupancyMap, or validatorOccupancyMap3D
        % or manipulatorCollisionBodyValidator.
            if isa(obj.StateValidator, 'validatorOccupancyMap3D') || ...
                    isa(obj.StateValidator, 'manipulatorCollisionBodyValidator')
                obj.StateValidator.SkipStateValidation = true;
            end

            if isa(obj.StateValidator, 'validatorOccupancyMap')
                obj.StateValidator.SkipStateValidation = true;
                obj.StateValidator.configureValidatorForFastOccupancyCheck();
            end

            % For performance improvement, skip further state validation for supported stateSpaces
            stateSpaces = {'stateSpaceSE2', 'stateSpaceDubins', ...
                           'stateSpaceReedsShepp', 'stateSpaceSE3', 'manipulatorStateSpace'};
            if any(strcmp(class(obj.StateValidator.StateSpace),stateSpaces))
                obj.StateValidator.StateSpace.SkipStateValidation = true;
            end
        end
    end
end
