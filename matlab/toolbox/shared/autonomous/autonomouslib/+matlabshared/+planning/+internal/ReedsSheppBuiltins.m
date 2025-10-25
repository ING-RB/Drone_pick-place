classdef ReedsSheppBuiltins
%This class is for internal use only. It may be removed in the future.

%ReedsSheppBuiltins Interface to builtins used for ReedsShepp connection
%
%   This class is a collection of static functions used for different ReedsShepp
%   motion primitive calculations. Its main purpose is to dispatch
%   function calls correctly when executed in MATLAB or code
%   generation.
%   During MATLAB execution, we call the standard builtins. During code
%   generation we use a codegen-compatible version in ReedsSheppBuildable.
%
%   See also matlabshared.planning.internal.coder.ReedsSheppBuildable

% Copyright 2018-2019 The MathWorks, Inc.

%#codegen

    methods (Static)
        function [cost, motionLengths, motionTypes] = ...
                autonomousReedsSheppSegments(startPose, goalPose, turningRadius, ...
                                             forwardCost, reverseCost, pathSegments, disabledTypes)
            %autonomousReedsSheppSegments Dispatch autonomousReedsSheppSegments call
            %   The code paths are different for MATLAB execution and code
            %   generation.

            if isempty(coder.target)
                % Call standard builtin in MATLAB
                [cost, motionLengths, motionTypes] = ...
                    autonomousReedsSheppSegments(startPose, goalPose, turningRadius, ...
                                                 forwardCost, reverseCost, pathSegments, disabledTypes);
            else
                % Generate code through external dependency
                [cost, motionLengths, motionTypes] = ...
                    matlabshared.planning.internal.coder.ReedsSheppBuildable.autonomousReedsSheppSegments(...
                        startPose, goalPose, turningRadius, ...
                        forwardCost, reverseCost, pathSegments, disabledTypes);

            end
        end

        function dist = autonomousReedsSheppDistance(startPose, goalPose, turningRadius, reverseCost)
        %autonomousReedsSheppDistance Dispatch autonomousReedsSheppDistance call
        %   The code paths are different for MATLAB execution and code
        %   generation.


            if isempty(coder.target)
                % Call standard builtin in MATLAB
                dist = autonomousReedsSheppDistance(startPose, goalPose, turningRadius, reverseCost);
            else
                % Generate code through external dependency
                dist = ...
                    matlabshared.planning.internal.coder.ReedsSheppBuildable.autonomousReedsSheppDistance(...
                        startPose, goalPose, turningRadius, reverseCost);
            end
        end

        function poses = autonomousReedsSheppInterpolate(startPose, goalPose, ...
                                                         connectionDistance, numSteps, turningRadius, reverseCost)
            %autonomousReedsSheppInterpolate Dispatch autonomousReedsSheppInterpolate call
            %   The code paths are different for MATLAB execution and code
            %   generation.

            if isempty(coder.target)
                % Call standard builtin in MATLAB
                poses = autonomousReedsSheppInterpolate(startPose, goalPose, ...
                                                        connectionDistance, numSteps, turningRadius, reverseCost);
            else
                % Generate code through external dependency
                poses = ...
                    matlabshared.planning.internal.coder.ReedsSheppBuildable.autonomousReedsSheppInterpolate(...
                        startPose, goalPose, connectionDistance, numSteps, turningRadius, reverseCost);
            end
        end
        
        function [poses, directions] = autonomousReedsSheppInterpolateSegments(startPose, goalPose, samples, ...
                turningRadius, segmentsLengths, segmentsDirections, segmentsTypes)
            %autonomousReedsSheppInterpolateSegments Dispatch autonomousReedsSheppInterpolateSegments call
            %   The code paths are different for MATLAB execution and code
            %   generation.
            
            if isempty(coder.target)
                % Call standard builtin in MATLAB
                [poses, directions] = autonomousReedsSheppInterpolateSegments(startPose, goalPose, samples, ...
                    turningRadius, segmentsLengths, segmentsDirections, segmentsTypes);
            else
                % Generate code through external dependency
                [poses, directions] = ...
                    matlabshared.planning.internal.coder.ReedsSheppBuildable.autonomousReedsSheppInterpolateSegments(...
                    startPose, goalPose, samples, turningRadius, segmentsLengths, segmentsDirections, segmentsTypes);
            end
        end
    end
end
