classdef DubinsBuiltins
    %This class is for internal use only. It may be removed in the future.
    
    %DUBINSBUILTINS Interface to builtins used for Dubins connection
    %
    %   This class is a collection of static functions used for different Dubins
    %   motion primitive calculations. Its main purpose is to dispatch
    %   function calls correctly when executed in MATLAB or code
    %   generation.
    %   During MATLAB execution, we call the standard builtins. During code
    %   generation we use a codegen-compatible version in DubinsBuildable.
    %
    %   See also matlabshared.planning.internal.coder.DubinsBuildable
    
    % Copyright 2018-2019 The MathWorks, Inc.
    
    %#codegen
    
    methods (Static)
        function [cost, motionLengths, motionTypes] = ...
                autonomousDubinsSegments(startPose, goalPose, turningRadius, pathSegments, disabledTypes)
            %autonomousDubinsSegments Dispatch autonomousDubinsSegments call
            %   The code paths are different for MATLAB execution and code
            %   generation.
            
            if isempty(coder.target)
                % Call standard builtin in MATLAB
                [cost, motionLengths, motionTypes] = ...
                    autonomousDubinsSegments(startPose, goalPose, turningRadius, pathSegments, disabledTypes);
            else
                % Generate code through external dependency
                [cost, motionLengths, motionTypes] = ...
                    matlabshared.planning.internal.coder.DubinsBuildable.autonomousDubinsSegments(...
                    startPose, goalPose, turningRadius, pathSegments, disabledTypes);
                
            end
        end
        
        function dist = autonomousDubinsDistance(startPose, goalPose, turningRadius)
            %autonomousDubinsDistance Dispatch autonomousDubinsDistance call
            %   The code paths are different for MATLAB execution and code
            %   generation.
            
            
            if isempty(coder.target)
                % Call standard builtin in MATLAB
                dist = autonomousDubinsDistance(startPose, goalPose, turningRadius);
            else
                % Generate code through external dependency
                dist = ...
                    matlabshared.planning.internal.coder.DubinsBuildable.autonomousDubinsDistance(...
                    startPose, goalPose, turningRadius);
            end
        end
        
        function poses = autonomousDubinsInterpolate(startPose, goalPose, ...
                connectionDistance, numSteps, turningRadius)
            %autonomousDubinsInterpolate Dispatch autonomousDubinsInterpolate call
            %   The code paths are different for MATLAB execution and code
            %   generation.
            
            if isempty(coder.target)
                % Call standard builtin in MATLAB
                poses = autonomousDubinsInterpolate(startPose, goalPose, ...
                    connectionDistance, numSteps, turningRadius);
            else
                % Generate code through external dependency
                poses = ...
                    matlabshared.planning.internal.coder.DubinsBuildable.autonomousDubinsInterpolate(...
                    startPose, goalPose, connectionDistance, numSteps, turningRadius);
            end
        end
        
        function poses = autonomousDubinsInterpolateSegments(startPose, goalPose, samples, ...
                turningRadius, segmentsLengths, segmentsTypes)
            %autonomousDubinsInterpolateSegments Dispatch autonomousDubinsInterpolateSegments call
            %   The code paths are different for MATLAB execution and code
            %   generation.
            
            if isempty(coder.target)
                % Call standard builtin in MATLAB
                poses = autonomousDubinsInterpolateSegments(startPose, goalPose, samples, ...
                    turningRadius, segmentsLengths, segmentsTypes);
            else
                % Generate code through external dependency
                poses = ...
                    matlabshared.planning.internal.coder.DubinsBuildable.autonomousDubinsInterpolateSegments(...
                    startPose, goalPose, samples, turningRadius, segmentsLengths, segmentsTypes);
            end
        end
    end
end
