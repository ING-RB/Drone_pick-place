classdef factorCameraSE3AndPointXYZ < nav.algs.internal.FactorGaussianNoiseModel & ...
                                      nav.algs.internal.CheckoutCVTLicense
%FACTORCAMERASE3ANDPOINTXYZ Factor relating SE(3) camera pose and 3-D point
%
%   The factorCameraSE3AndPointXYZ object describes the visual projection
%   factor relating the poses of the pinhole camera in the SE(3) state
%   space and a 3-D landmark points. You can add this object as a factor
%   to a factorGraph object.
% 
%   F = FACTORCAMERASE3ANDPOINTXYZ(ID,CAMERAINTRINSICMATRIX) creates a
%   factorCameraSE3AndPointXYZ object, F, with the specified node ID pairs
%   property NodeID set to ID, and with property K set to
%   CAMERAINTRINSICMATRIX. The factor object supports the construction of
%   multiple factors with different node ID pairs at the same time. ID is
%   an N-by-2 or N-by-3 matrix with rows of the form [cameraPoseID
%   landmarkID] or [poseID landmarkID sensorTransformID]. N is the number
%   of factors, cameraPoseID is the camera pose node ID, landmarkID is the
%   landmark node ID, poseID is base sensor pose node ID in multi-sensor
%   scenario and sensorTransformID is the sensor transform node ID.
%
%   Note that whenever a sensorTransformID is specified as a third column
%   in the IDs input the SensorTransform name-value is ignored and 
%   identity sensor transform is used instead. If a sensor transform is
%   known accurately use SensorTransform name-value instead of specifying
%   ID. If it is important to refine or estimate the sensor transform  
%   using factor graph optimization prefer specifying sensorTransformID. 
%   Specifying sensor transform ID is important for multi-sensor  
%   extrinsic calibration workflows.
%   
%   The Measurement property specified as an N-by-2 matrix represents a 
%   2-D image point observation [x,y] of a specified 3-D point in a 
%   specified camera frame. The Information property specified as a 
%   2-by-2 or 2-by-2-by-N matrix represents the uncertainty of the 
%   measurement. When specified as a 2-by-2 matrix, the same information 
%   matrix applies to all the factors. N is the number of factors. By 
%   default the measurement is set to [0,0] and the corresponding 
%   information matrix is set to eye(2).
%
%   F = FACTORCAMERASE3ANDPOINTXYZ(...,Name=Value) specifies properties
%   using one or more name-value arguments in addition to the argument 
%   from the previous syntax.
%
%   FACTORCAMERASE3ANDPOINTXYZ methods:
%       nodeType          - Retrieve node type for specified node ID
%
%   FACTORCAMERASE3ANDPOINTXYZ properties:
%       NodeID            - Node ID pairs 
%       K                 - Camera intrinsic matrix 
%       Measurement       - Measured image point position
%       Information       - Information matrix associated with measurement
%       SensorTransform   - Transformation consisting of 3-D translation
%                           and rotation to transform connecting pose 
%                           nodes to initial camera sensor reference frame
%
%   Example:
%       % create a factor graph object G.
%       G = factorGraph;
%
%       % Generate 1 new unique node ID to represent camera pose node.
%       camId = generateNodeID(G,1);
%
%       % Generate 2 new unique IDs to represent 3D points.
%       pointIds = generateNodeID(G,2);
%
%       % specify camera intrinsic matrix.
%       focalLength    = [800, 800]; % specified in units of pixels
%       principalPoint = [320, 240]; % in pixels [x, y]
%       cameraIntrinsicMatrix = [focalLength(1),0,principalPoint(1); ...
%                               0,focalLength(2),principalPoint(2);0,0,1];
%
%       camMeasurements = [240, 115; .... %first factor measurement
%                          100,315 ... %second factor measurement
%                         ];
%
%       % Create a factorCameraSE3AndPointXYZ object that specifies two
%       % factors. The first factor connects camera pose node 1 and first
%       % point node. The second factor connects camera pose node and 
%       % second point node.
%       fCam = factorCameraSE3AndPointXYZ(...
%                  [camId pointIds(1); camId pointIds(2)], ...
%                  cameraIntrinsicMatrix, ...
%                  Measurement = camMeasurements);
%       
%       % Add the factor object to the factor graph to create the factors.
%       % Nodes with ids camId and pointIds are added to the factor graph
%       % and connected as specified by the factors.
%       addFactor(G,fCam);
%
%       % Node camId is type "POSE_SE3". Nodes pointIds are type
%       % "POINT_XYZ" and both connect to camera node.
%       nodeType(G,camId);
%       nodeType(G,pointIds(1));
%       nodeType(G,pointIds(2));
%
%   See also factorGraph, factorIMU, estimateGravityRotation, 
%   estimateGravityRotationAndPoseScale
    
%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    properties
        %SensorTransform Sensor transform
        %   Transformation consisting of 3-D translation and rotation to
        %   transform connecting pose nodes to the initial camera sensor
        %   reference frame, specified as a se3 object.
        %   
        %   For example, if the connected pose nodes store IMU poses in 
        %   the initial IMU sensor reference frame, the sensor transform
        %   rotates and translates a pose in the initial IMU sensor
        %   reference frame to the initial camera sensor reference frame.
        %   The initial sensor reference frame has the very first sensor
        %   pose at its origin.
        %
        %   A sensor transform is unnecessary if the connecting pose nodes
        %   contain poses in the initial camera sensor reference frame.
        %   Otherwise, you must specify the sensor transform.
        %
        %    Default: se3()
        SensorTransform
    end

    properties (Hidden, Constant)
        FactorType = "Camera_SE3_Point3_F";
    end

    properties (Hidden)
        %InternalFactorType string identifier to internal projection 
        %   factor type. When non empty this is used as the factor type.
        InternalFactorType

        %IntrinsicVector intrinsic vector storing pinhole camera parameters
        %   in the form [fx,fy,cx,cy,skew,k1,k2,k3,k4,k5,k6,p1,p2].
        IntrinsicVector
    end

    properties (SetAccess = protected)
        %K Camera intrinsic matrix 
        %   Camera intrinsic matrix, specified as a 3-by-3 matrix or
        %   3-by-3-by-N matrix. N is the number of factors. When specified
        %   as a 3-by-3 matrix, the same camera intrinsic matrix applies to
        %   all the factors. The 3-by-3 matrix has the format
        %
        %   fx  0  cx
        %   0  fy  cy
        %   0   0   1
        %
        %   The coordinates [cx cy] represent the camera's principal point
        %   in pixels. The coordinates [fx fy] represent the camera's focal
        %   length in pixels.
        %
        %   Note: This property is equivalent to a property of the same
        %   name on the cameraIntrinsics object from the Computer Vision
        %   Toolbox.
        %
        %   You must specify this property at object creation.
        K
    end
    
    methods
        function obj = factorCameraSE3AndPointXYZ(ids, cameraIntrinsicMatrix, varargin)
            %FACTORCAMERASE3ANDPOINTXYZ Constructor
            
            narginchk(2, Inf);

            if isStringScalar(cameraIntrinsicMatrix) || ischar(cameraIntrinsicMatrix)
                coder.internal.error('nav:navalgs:factors:ExpectedK');
            end

            % ids is numeric matrix with 2 or 3 column
            validateattributes(ids, 'numeric', ...
            {'integer', 'nonempty', 'nonnegative', 'nonsparse'}, 'factorCameraSE3AndPointXYZ', 'ids')
            idDimension = 0;
            if (size(ids,2)==2)
                idDimension = 2;
            elseif (size(ids,2)==3)
                idDimension = 3;
            else
                coder.internal.error('nav:navalgs:factors:InvalidIDsProjectionFactor');
            end

            % default value for sensor transform is se3()
            obj@nav.algs.internal.FactorGaussianNoiseModel(ids, idDimension, zeros(1,2), eye(2), 'SensorTransform', se3(), varargin{:});
            obj.K = cameraIntrinsicMatrix;

            % set the internal factor type only when sensor transform ID is
            % provided as the third column in the input ids.
            if idDimension == 3
                obj.InternalFactorType = "Distorted_Pinhole_Camera_Projection_With_Fixed_Intrinsics_F";
            else
                obj.InternalFactorType = "";
            end

            obj.IntrinsicVector = [squeeze(cameraIntrinsicMatrix(1,1,:)),squeeze(cameraIntrinsicMatrix(2,2,:)),squeeze(cameraIntrinsicMatrix(1,3,:)),squeeze(cameraIntrinsicMatrix(2,3,:)),zeros(size(cameraIntrinsicMatrix,3),9)];
        end
    end

    methods (Access=protected)
        function type = nodeTypeImpl(obj, id)
            % The node in the first column is SE3 type and the second column is Point3.
            [~, col] = find(obj.NodeID == id);
            if col == 1
                type = nav.internal.factorgraph.NodeTypes.SE3;
            elseif col == 2
                type = nav.internal.factorgraph.NodeTypes.Point3;
            else
                type = nav.internal.factorgraph.NodeTypes.TransformSE3;
            end
        end
    end

    methods
        function obj = set.K(obj, cameraIntrinsicMatrix)
            %set.K

            if length(size(cameraIntrinsicMatrix))==3
                validateattributes(cameraIntrinsicMatrix, 'numeric', ...
                    {'size', [3, 3, obj.MeasurementSize(1)], 'real','nonempty', 'nonnan', 'finite', 'nonsparse'}, 'factorCameraSE3AndPointXYZ', 'K');
            else
                validateattributes(cameraIntrinsicMatrix, 'numeric', ...
                    {'size', [3, 3], 'real','nonempty', 'nonnan', 'finite', 'nonsparse'}, 'factorCameraSE3AndPointXYZ', 'K');
            end
            obj.K = double(cameraIntrinsicMatrix);
        end

        function obj = set.SensorTransform(obj, t)
            %set.SensorTransform

            validateattributes(t, {'se3'}, ...
                {'nonempty','scalar'}, 'factorCameraSE3AndPointXYZ', 'SensorTransform');
            if (size(obj.NodeID,2) == 3) && ~isequal(t, se3())
                coder.internal.warning('nav:navalgs:factors:SensorTransformIgnoredProjectionFactor');
                return;
            end
            obj.SensorTransform = t;
        end
    end

    methods (Static, Hidden)
        function obj = loadobj(s)
            %loadobj Load saved lidarSLAM

            obj = factorCameraSE3AndPointXYZ(s.NodeID, s.K, ...
                Measurement=s.MeasurementInternal, Information=s.InformationInternal, ...
                SensorTransform=s.SensorTransform);
        end
    end
end

