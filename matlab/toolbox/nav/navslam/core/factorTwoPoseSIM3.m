classdef factorTwoPoseSIM3 < nav.algs.internal.FactorGaussianNoiseModel
%FACTORTWOPOSESIM3 Creates a factor object that relates 2 SIM(3) poses.
%
%   Monocular visual-odometry estimates poses at an unknown pose scale
%   than metric units like meters. It can also happen that the translation
%   component of the estimated world or absolute poses at different time
%   stamps can be at a different scale. This problem is referred to as
%   scale drift. A scalar multiplier for each pose that can transform all
%   translation components of the 3-D poses to common or uniform scale is
%   referred to as pose scale. SE(3) pose consisting of 3-D rotation and
%   translation along with pose scale is called as SIM(3) pose
%   representation.
% 
%   This factor connects to 2 SIM(3) poses where each SIM(3) pose is broken
%   into 2 nodes an SE(3) pose node and a pose scale node. So, this factor
%   relates 4 nodes when the first 2 belong to first SIM(3) pose and later
%   to second SIM(3) pose. This factor stores a SIM(3) pose vector of
%   length 8 as a measurement. Whenever 7 length SE(3) measurement is
%   supplied as an input the pose scale is assumed to be 1.
%
%    F = FACTORTWOPOSESIM3(ID) returns a factorTwoPoseSIM3 object, F, with
%    the node identification number set to ID
%    ([se3Id1, scaleId1, se3Id2, scaleId2]). The measurement represents an
%    SE (3) or SIM (3) relative pose of the form [x,y,z,qw,qx,qy,qz,scale].
%    By default, the measurement is set to [0,0,0,1,0,0,0,1] and the
%    corresponding information matrix is set to eye(7). If the nodes with
%    given node IDs do not exist, new nodes with expected types will be
%    initialized and added to the factor graph with given node IDs.
%
%   F = FACTORTWOPOSESIM3(...,Name=Value) specifies properties using one
%   or more name-value arguments.
%
%   FACTORTWOPOSESIM3 methods:
%       nodeType          - Retrieve the node type for specified node ID
%
%   FACTORTWOPOSESI3 properties:
%       NodeID - IDs of nodes to connect to in factor graph specified as
%          as an N-by-4 matrix of the form [se3PoseId1, poseScaleId1, 
%          se3PoseId2, poseScaleId2]
%
%       Measurement - SE (3) or SIM (3) measurement specified as
%          [x,y,z,qw,qx,qy,qz] or [x,y,z,qw,qx,qy,qz,scale]. The specified 
%          pose vector results in a similarity transformation of the form 
%          [scale*R,t; 0,1] where R is the rotation matrix representation 
%          of quaternion [qw,qx,qy,qz] and t is translation vector [x;y;z].
%
%       Information - Information matrix associated with measurement
%
%   Example:
%       % Construct and empty factor graph.
%       g = factorGraph;
%
%       % The first SIM(3) factor connects to 4 nodes where the first 2 
%       % nodes represent the SE(3) and pose scale components of first
%       % SIM(3) absolute pose.
%       firstSIM3IDs = generateNodeID(g, [1,2]); 
%       % The next 2 nodes represent SE(3) and pose scale components of 
%       % Second SIM(3) absolute pose IDs.
%       secondSIM3IDs = generateNodeID(g, [1,2]);
%       % 4 node combination of SIM(3) factor
%       nodeIDs1 = [firstSIM3IDs,secondSIM3IDs];
%       % SE(3) relative pose ([x,y,z,qw,qx,qy,qz]) estimated between  
%       % first and second pose sampling instants using monocular visual
%       % odometry.
%       relativePose1 = [1,0,0,1,0,0,0];
%       % Construct SIM(3) factor between second and third SIM(3) absolute 
%       % poses.
%       f1 = factorTwoPoseSIM3(nodeIDs1, Measurement=relativePose1);
%       % Add the first SIM(3) relative pose factor to the graph.
%       addFactor(g,f1);
%
%       % Construct and add second SIM(3) factor between second and third
%       % absolute SIM(3) poses.
%       relativePose2 = [0.5,0,0,1,0,0,0];
%       thirdSIM3IDs = generateNodeID(g, [1,2]);
%       nodeIDs2 = [secondSIM3IDs, thirdSIM3IDs];
%       f2 = factorTwoPoseSIM3(nodeIDs2, Measurement=relativePose2);
%
%       % Loop closure SIM(3) factor between first and third absolute
%       % pose nodes. Loop closure factors usually exist between non
%       % consecutive absolute pose nodes. Loop scale usually is non
%       %identity.
%       loopRelativePose = [1,0,0,1,0,0,0];
%       loopScale = 0.5;
%       nodeIDs3 = [firstSIM3IDs,thirdSIM3IDs];
%       f3 = factorTwoPoseSIM3(nodeIDs3, ...
%                    Measurement=[loopRelativePose, loopScale]);
%       addFactor(g, f3);
%
%       % It is a common practice to fix the first SIM(3) pose during
%       % the factor graph optimization to estimate every other pose
%       % relative to the first pose.
%       fixNode(g, firstSIM3IDs);
%
%       % Specify the absolute SE(3) pose guess estimated by monocular 
%       % visual odometry.
%       absolutePose1 = [0,0,0,1,0,0,0];
%       absolutePose2 = [1,0,0,1,0,0,0];
%       absolutePose3 = [1.5,0,0,1,0,0,0];
%       nodeState(g, ...
%           [firstSIM3IDs(1); secondSIM3IDs(1); thirdSIM3IDs(1)], ...
%           [absolutePose1;absolutePose2;absolutePose3]);
%
%       % Execute factor graph optimization to estimate refine absolute
%       % poses and pose scale values to bring all poses to common scale.
%       opts = factorGraphSolverOptions;
%       optimize(g, opts);
%
%       % Retrieved refined absolute poses and pose scales.
%       refinedPoses = nodeState(g, ...
%              [firstSIM3IDs(1); secondSIM3IDs(1); thirdSIM3IDs(1)]);
%       refinedScales = nodeState(g, ...
%             [firstSIM3IDs(2); secondSIM3IDs(2); thirdSIM3IDs(2)]);
%
%   See also factorGraph.

%   Copyright 2024 The MathWorks, Inc.

%#codegen

    properties (Hidden, Constant)
        FactorType = "Two_SIM3_F";
    end

    methods
        function obj = factorTwoPoseSIM3(ids, varargin)
            %FACTORTWOPOSESIM3 Constructor

            narginchk(1, 5);
            obj@nav.algs.internal.FactorGaussianNoiseModel(ids, 4, [0,0,0,1,0,0,0,1], eye(7), varargin{:});
        end
    end

    methods (Access=protected)
        function type = nodeTypeImpl(obj, id)
            [~, col] = find(obj.NodeID == id);
            if any(col == 1) || any(col == 3)
                type = nav.internal.factorgraph.NodeTypes.SE3;
            else
                type = nav.internal.factorgraph.NodeTypes.SE3Scale;
            end
        end

        function obj = setMeasurement(obj, measurement)
            %setMeasurement Setter for Measurement property
            validateattributes(measurement, 'numeric', ...
                {'real', 'finite', 'nonempty', 'nonsparse','2d','nrows',size(obj.NodeID,1)}, class(obj), 'measurement');
            numCols = size(measurement,2);
            coder.internal.errorIf((numCols~=7)&&(numCols~=8),'nav:navalgs:factors:WrongSizeSIM3Measurement');
            numColsIsSeven = (numCols==7);
            if numColsIsSeven
                obj.MeasurementInternal = [double(measurement(:,1:7)),ones(size(measurement,1),1)];
            else
                coder.internal.errorIf(any(measurement(:,8) <= 0),'nav:navalgs:factors:InvalidPoseScale');
                obj.MeasurementInternal = double(measurement(:,1:8));
            end
        end
    end

    methods (Static, Hidden)
        function obj = loadobj(s)
            %loadobj Load saved lidarSLAM

            obj = factorTwoPoseSIM3(s.NodeID, ...
                Measurement=s.MeasurementInternal, Information=s.InformationInternal);
        end
    end
end

