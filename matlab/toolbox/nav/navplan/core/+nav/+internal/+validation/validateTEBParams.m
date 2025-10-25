classdef validateTEBParams
% This class is for internal use only. It may be removed in the future.

%validateTEBParams validate, set and get properties and input attributes of 
% controllerTEB.

%   Copyright 2024 The MathWorks, Inc.

%#codegen

    methods (Static)

        function  setWeightTime(obj, weights)
            validateattributes(weights, 'numeric', ...
                {'nonempty', 'scalar', 'nonnan', 'finite', 'real', 'nonnegative'}, ...
                obj.getClassName, 'WeightTime');

            obj.TEBParams.WeightTime = weights;
        end

        function  weights = getWeightTime(obj)
            weights = obj.TEBParams.WeightTime;
        end

        function setWeightSmoothness(obj, weights)
            validateattributes(weights, 'numeric', ...
                {'nonempty', 'scalar', 'nonnan', 'finite', 'real', 'nonnegative'}, ...
                obj.getClassName, 'WeightSmoothness');

            obj.TEBParams.WeightSmoothness = weights;
        end

        function weights = getWeightSmoothness(obj)
            weights = obj.TEBParams.WeightSmoothness;
        end

        function setWeightObstacle(obj, weights)
            validateattributes(weights, 'numeric', ...
                {'nonempty', 'scalar', 'nonnan', 'finite', 'real', 'nonnegative'}, ...
                obj.getClassName, 'WeightObstacles');

            obj.TEBParams.WeightObstacles = weights;
        end

        function weights = getWeightObstacle(obj)
            weights = obj.TEBParams.WeightObstacles;
        end

        function setRobotDimension(obj,dim,shape)
            nav.internal.validation.validateTEBParams.checkRobotShape(obj,dim,shape);
            nav.internal.validation.validateTEBParams.updateRobotInfo(obj);
        end

        function robotShape = setRobotShape(obj,shape)
            robshape = convertCharsToStrings(validatestring(shape,...
                {'Rectangle', 'Point'}, obj.getClassName, 'Shape'));

            if robshape == "Point"
                obj.TEBParams.RobotDimension = [0 0];
                nav.internal.validation.validateTEBParams.updateRobotInfo(obj);
            end
            robotShape = convertCharsToStrings(shape);
        end


        function ft = setRobotFixedTransform(obj,ft)

            if isnumeric(ft)
                %FixedTransform is provided as an array
                validateattributes(ft, {'numeric'}, {'nonempty', 'row', 'numel', ...
                    3, 'nonnan', 'finite', 'real'}, obj.getClassName, 'FixedTransform');
                obj.TEBParams.RobotFixedTransform = ft;
                ft = se2(ft(3), 'theta', ft(1:2));
            else
                %FixedTransform is provided as an SE2 object
                validateattributes(ft, {'double', 'se2'},{})
                obj.TEBParams.RobotFixedTransform = ft.xytheta;
            end
            nav.internal.validation.validateTEBParams.updateRobotCollisionCenters(obj);
        end

        function ft = getRobotFixedTransform(obj)
            if isnumeric(obj.TEBParams.RobotFixedTransform)
                ft = se2(obj.TEBParams.RobotFixedTransform(3), 'theta', ...
                    obj.TEBParams.RobotFixedTransform(1:2));
            else
                ft = obj.TEBParams.RobotFixedTransform;
            end
        end

        function setLookAheadTime(obj, lookAheadTime)
            validateattributes(lookAheadTime,...
                'numeric',{'nonempty', 'scalar', 'nonnan', 'finite',  ...
                'real', 'nonnegative'} , ...
                obj.getClassName, 'LookAheadTime');

            if(lookAheadTime~=0)
                % Validate that Look-ahead-time is atleast 3 times ReferenceDeltaTime.
                nav.internal.validation.validateTEBParams.validateLookAheadTime(obj, lookAheadTime);
            end

            obj.LookAheadDistance = lookAheadTime * obj.TEBParams.MaxVelocity(1);
            setMaxPathStates(obj);
        end

        function lat = getLookAheadTime(obj)
            lat = obj.LookAheadDistance / obj.TEBParams.MaxVelocity(1);
        end

        function setReferenceDeltaTime(obj, refDelT)
            validateattributes(refDelT,...
                'numeric',{'nonempty', 'scalar', 'nonnan', 'finite',  ...
                'real', 'nonnegative', 'nonsparse'} , ...
                obj.getClassName, 'ReferenceDeltaTime');
            obj.TEBParams.ReferenceDeltaTime = refDelT;
            setMaxPathStates(obj);
        end

        function refDelT = getReferenceDeltaTime(obj)
            refDelT = obj.TEBParams.ReferenceDeltaTime;
        end

        function setMaxVelocity(obj, maxVel)
            validateattributes(maxVel,...
                'numeric', {'nonempty', 'row', 'nonnan', 'finite',  ...
                'real', 'nonnegative', 'nonsparse', 'numel', 2} , ...
                obj.getClassName, 'MaxVelocity');
            beforeMaxVel = obj.TEBParams.MaxVelocity;
            obj.TEBParams.MaxVelocity = maxVel(1);
            obj.TEBParams.MaxAngularVelocity = maxVel(2);
            obj.LookAheadDistance = (obj.LookAheadDistance/beforeMaxVel)*obj.TEBParams.MaxVelocity;
            setMaxPathStates(obj);
        end

        function maxVel = getMaxVelocity(obj)
            maxVel = [obj.TEBParams.MaxVelocity ...
                obj.TEBParams.MaxAngularVelocity];
        end

        function setMaxReverseVelocity(obj, maxReverseVel)
            validateattributes(maxReverseVel,...
                'numeric', {'nonempty', 'scalar',  ...
                'real', 'nonnegative', 'nonsparse'} , ...
                obj.getClassName, 'MaxReverseVelocity');
            if isinf(maxReverseVel)
                validateattributes(maxReverseVel, 'numeric', {'finite'}, ...
                    obj.getClassName, 'MaxReverseVelocity'); % throw standardized error
            end
            obj.TEBParams.MaxReverseVelocity = maxReverseVel;
        end

        function maxReverseVel = getMaxReverseVelocity(obj)
            maxReverseVel = obj.TEBParams.MaxReverseVelocity;
        end

        function setMinTurningRadius(obj, minTurnRadius)
            validateattributes(minTurnRadius,...
                'numeric', {'nonempty', 'scalar', 'nonnan', 'finite',  ...
                'real', 'nonnegative', 'nonsparse'} , ...
                obj.getClassName, 'MinTurningRadius');
            robType = ~(minTurnRadius > 0);
            obj.TEBParams.MinTurningRadius = minTurnRadius;
            obj.TEBParams.RobotType = double(robType);
        end

        function minTurnRadius = getMinTurningRadius(obj)
            minTurnRadius = obj.TEBParams.MinTurningRadius;
        end

        function setMaxAcceleration(obj,maxAccel)
            validateattributes(maxAccel,...
                'numeric',{'nonempty', 'row', 'numel', 2, 'nonnan', 'finite',  ...
                'real', 'nonnegative', 'nonsparse'} , ...
                obj.getClassName, 'MaxAcceleration');
            obj.TEBParams.MaxAcceleration = maxAccel(1);
            obj.TEBParams.MaxAngularAcceleration = maxAccel(2);
        end

        function maxAccel = getMaxAcceleration(obj)
            maxAccel = [obj.TEBParams.MaxAcceleration ...
                obj.TEBParams.MaxAngularAcceleration];
        end

        function setNumIteration(obj, numIter)
            validateattributes(numIter, 'numeric',...
                {'nonempty', 'scalar', 'nonnan', 'finite',  ...
                'real', 'positive', 'integer', 'nonsparse'} , ...
                obj.getClassName, 'NumIteration');
            obj.TEBParams.NumIteration = numIter;
        end

        function numIter = getNumIteration(obj)
            numIter = obj.TEBParams.NumIteration;
        end

        function setObstacleSafetyMargin(obj, margin)
            validateattributes(margin,...
                'numeric',{'nonempty', 'scalar', 'nonnan', 'finite',  ...
                'real', 'nonnegative', 'nonsparse'} , ...
                obj.getClassName, 'ObstacleSafetyMargin');
            nav.internal.validation.validateTEBParams.updateSafetyMargin(obj,margin);
        end

        function margin = getObstacleSafetyMargin(obj)
            margin = obj.TEBParams.ObstacleSafetyMargin - obj.CellHalfDiagLen;
        end

        function refPath = getReferencePath(obj)
            refPath = obj.ReferencePathInternal;
        end

        function setReferencePath(obj, refPath)
            obj.ReferencePathInternal = ...
                nav.internal.validation.validateTEBParams.parseValidateReferencePath(...
                refPath, obj.getClassName);
            % If the user reset the reference path, the index in reference
            % path which is closest to the robot should also be reset to 1.
            obj.IdxCloseToRobot = 1;
        end

        function setGoalTolerance(obj, goalTol)
            validateattributes(goalTol,...
                'numeric', {'nonempty', 'row', 'numel', 3, 'nonnan', 'finite',  ...
                'real', 'positive', 'nonsparse'} , ...
                obj.getClassName, 'GoalTolerance');
            obj.GoalToleranceInternal = goalTol;
        end

        function goalTol = getGoalTolerance(obj)
            goalTol = obj.GoalToleranceInternal;
        end

        function stepInputs(obj,curstate,curvel,sdfMap)
            arguments
                obj  ...
                    {mustBeNonempty, mustBeA(obj, {'controllerTEB', 'nav.slalgs.internal.TimedElasticBand'})}
                curstate (1,3) ...
                    {mustBeNumeric, mustBeNonempty, mustBeNonNan, mustBeFinite, mustBeReal}
                curvel   (1,2) ...
                    {mustBeNumeric, mustBeNonempty, mustBeNonNan, mustBeFinite, mustBeReal}
                sdfMap ...
                    {mustBeNonempty, mustBeA(sdfMap, {'signedDistanceMap'})}
            end

            % Check if current robot pose is occupied and if last path on
            % the ReferencePath is occupied.
            laststate = obj.ReferencePathInternal(end,:);
            startGoalColliding = nav.algs.internal.checkCollisionVehicleCircles(...
                sdfMap, [curstate; laststate],...
                obj.RobotCollisionCenters, obj.RobotCollisionRadius);
            if any(startGoalColliding(1))
                curStateStr = ['[' ...
                    sprintf('%.3f %.3f %.3f', curstate(1), curstate(2), curstate(3)) ...
                    ']'];
                coder.internal.error("nav:navalgs:controllerteb:InvalidCurrentPose", curStateStr);
            end

            if any(startGoalColliding(2))
                lastStateStr = ['[' ...
                    sprintf('%.3f %.3f %.3f', laststate(1), laststate(2), laststate(3)) ...
                    ']'];
                coder.internal.error("nav:navalgs:controllerteb:InvalidLastPose", lastStateStr);
            end

            obj.TEBParams.StartVelocity = curvel(1);
            obj.TEBParams.StartAngularVelocity = curvel(2);
        end

    end

    methods(Static,Hidden)
        function checkRobotShape(obj, dim,shape)
            switch shape
                case "Point"
                    validateattributes(dim, 'numeric', ...
                        {'nonempty', 'row', 'numel', 2, 'nonnan', 'finite', 'real'}, ...
                        obj.getClassName, 'Dimension');

                    obj.TEBParams.RobotDimension = [0 0];
                case "Rectangle"
                    validateattributes(dim, 'numeric', ...
                        {'nonempty', 'row', 'numel', 2, 'nonnan', 'finite', 'real', 'positive'}, ...
                        obj.getClassName, 'Dimension');
                    obj.TEBParams.RobotDimension = dim;
            end
        end

        function updateSafetyMargin(obj,margin)
            margin = margin + obj.CellHalfDiagLen;
            obj.TEBParams.ObstacleSafetyMargin = margin;
            % Inline with default values
            obj.TEBParams.ObstacleCutOffDistance = 5*margin;
            % 1.5 factor is inline with default values, but also have minimum
            % obstacle inclusion distance as 0.2
            obj.TEBParams.ObstacleInclusionDistance = max(1.5*margin, 0.2);
        end

        function updateRobotInfo(obj)

            % Compute vehicle approximation using inflation circles
            [obj.RobotCollisionCenters, obj.RobotCollisionRadius] = ...
                nav.algs.internal.vehicleCirclesApproximation(...
                obj.TEBParams.RobotDimension,...
                obj.TEBParams.NumRobotCollisionCircles);
            nav.internal.validation.validateTEBParams.updateRobotCollisionCenters(obj);
        end

        function updateRobotCollisionCenters(obj)
            % Transform the collision circles based on the FixedTransform
            centers = obj.RobotCollisionCenters;
            xytheta = obj.TEBParams.RobotFixedTransform;
            R = [cos(xytheta(3))  -sin(xytheta(3));
                sin(xytheta(3)), cos(xytheta(3))];
            t =  xytheta(1:2);
            centersTransformed = (centers-t)*R;
            obj.RobotCollisionCenters = centersTransformed;
        end

        function validateLookAheadTime(obj, lookAheadTime)
            % validateLookAheadTime validate that the look ahead time is
            % atleast 3 times the ReferenceDeltaTime. This ensures the TEB
            % algorithm has atleast three poses for optimization.

            referenceDeltaT = obj.ReferenceDeltaTime;
            isLATInvalid = lookAheadTime <= 3*referenceDeltaT;
            expectedLookAheadTime = 3*referenceDeltaT;

            errorString = sprintf("%.1f", expectedLookAheadTime);
            coder.internal.errorIf(isLATInvalid,"nav:navalgs:controllerteb:InValidLookAheadTime", ...
                errorString);
        end

        function rp = parseValidateReferencePath(refpath,filename)
            %PARSEVALIDATEREFERENCEPATH Extract and validate values specified for ReferencePath

            validateattributes(refpath, {'numeric', 'navPath'}, {}, filename, 'Reference Path');

            if isa(refpath, "navPath")
                coder.internal.errorIf(class(refpath.StateSpace) ~= "stateSpaceSE2", ...
                    "nav:navalgs:controllerteb:InvalidPathInput");

                coder.internal.errorIf(refpath.NumStates < 3, ...
                    'nav:navalgs:controllerteb:MinPathPoints');

                rp = refpath.States;
            else
                % for now keep a numeric path as catch all, if the reference path is not a special
                % class it should be a numeric matrix
                validateattributes(refpath, 'numeric', ...
                    {'2d', 'nonempty', 'nonnan', 'finite', 'real'}, filename, 'ReferencePathInternal')

                coder.internal.errorIf(width(refpath)>3||width(refpath)<2,...
                    'nav:navalgs:controllerteb:InvalidPathInput');

                coder.internal.errorIf(height(refpath)<3, ...
                    'nav:navalgs:controllerteb:MinPathPoints');

                if width(refpath) == 2
                    heading = headingFromXY(refpath);
                    rp = [refpath heading];
                else
                    rp = refpath;
                end
            end

            delRefPthNorm = diff(rp(:,1:2));
            delRefPthNorm = delRefPthNorm./vecnorm(delRefPthNorm, 2, 2);
            oriRefPthVec = [cos(rp(1:end-1,3)) sin(rp(1:end-1,3))];
            dotDkQk = dot(delRefPthNorm, oriRefPthVec);
            dotDkQkThreshold = 1e-3;
            coder.internal.errorIf(all(abs(dotDkQk) < dotDkQkThreshold, "all"), ...
                'nav:navalgs:controllerteb:InputPathOrthogonality');

        end

    end
end