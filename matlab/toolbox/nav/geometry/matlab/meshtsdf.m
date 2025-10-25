classdef meshtsdf < nav.algs.internal.InternalAccess
%meshtsdf Store signed distance over variably sized 3D region
%
%   The meshtsdf object is used to discretize meshes and store their
%   Truncated Signed Distance Field over a voxelized 3D space. Voxels
%   within a specified distance from a mesh boundary contain positive
%   and negative distance values and if they outside or inside the mesh,
%   respectively.
%
%   Voxels that lie outside the truncated region, are set to a signed
%   "background" value with magnitude equal to the TruncationDistance. Once
%   constructed, individual TSDFs can be moved by updating their SE3 pose,
%   and the object can provide distance/gradient information over the
%   discretized region.
%
%   TSDF = meshtsdf creates an empty object with default properties
%
%   TSDF = meshtsdf(meshArray) takes in an N-element struct-array of
%   meshes, meshArray, and caches signed distance over each meshes
%   truncated region. Each element of meshArray must contain the following:
%
%           ID       : integer-valued scalar identifier.
%                       (Defaults to 1:N)
%           Vertices : Nx3 list of vertices w.r.t. the Pose frame
%           Faces    : Nx3 matrix where each row contains three indices
%                      corresponding to rows in the Vertices matrix forming
%                      a triangle
%           Pose     : The 4x4 transformation from the world frame to the
%                      frame in which the vertices are defined
%
%   TSDF = meshtsdf(___,Name=Value) optionally accepts the following
%   NV-pairs:
%       FillInterior        : Determines if negative distances are computed
%                             to center of mesh (true) or only to a depth
%                             of -TruncationDistance
%
%                               Default: true
%
%       Resolution          : Grid resolution in cells per meter
%
%                               Default: 1
%
%       TruncationDistance  : Max distance from mesh surface over which 
%                             signed distances are computed and stored
%
%                               Default: 3/Resolution
%
%   meshtsdf properties:
%       MeshID              - Nx1 array of IDs managed by object
%       NumMesh             - Number of discretized meshes
%       MapLimits           - XYZ limits containing all active voxels
%       NumActiveVoxel      - Total number active voxels across all mesh
%       Resolution          - Grid resolution in cells per meter
%       TruncationDistance  - Max distance from mesh surface
%       FillInterior        - Determines if negative distances are computed
%                             to center of mesh
%
%   meshtsdf methods:
%       activeVoxels        - Return voxel info
%       distance            - Compute distance to the zero level set
%       poses               - Retrieve poses for one or more TSDF
%       updatePose          - Update pose of one or more TSDF
%       addMesh             - Discretize mesh and compute TSDF
%       gradient            - Compute gradient of the signed distance field
%       removeMesh          - Remove one or more TSDF
%       copy                - Create a copy of the object
%       show                - Display the TSDFs in a figure
%
%   References:
%       [1] https://www.ams.org/journals/mcom/2005-74-250/S0025-5718-04-01678-3/S0025-5718-04-01678-3.pdf
%
%   See also: meshtsdf/MESHSTRUCT, meshtsdf/POSESTRUCT
%

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen

    properties (Dependent, SetAccess = private)
        %MeshID Nx1 array of IDs managed by object
        MeshID (:,1) double

        %NumMesh Number of discretized meshes currently managed
        NumMesh (1,1) double

        %MapLimits XYZ limits containing all active voxels
        MapLimits (2,3) double

        %NumActiveVoxel Total number active voxels across all mesh
        NumActiveVoxel (1,1) double

        %Resolution Grid resolution in cells per meter
        Resolution (1,1) double

        %TruncationDistance Max distance from mesh surface over which
        % signed distance values are computed and stored
        TruncationDistance (1,1) double

        %FillInterior Determines if negative distances are computed to
        % center of mesh (true), or only to a depth of -TruncationDistance
        FillInterior (1,1) logical
    end

    properties (Access = ?nav.algs.internal.InternalAccess)
        %MeshtsdfBuiltin C++ MCOS Object
        MeshtsdfBuiltin

        %ColorbarLinks Stores property links for display of 2nd colorbar
        ColorbarLinks

        %ThemeListener Listeners for updating colors when theme changes
        ThemeListener

        %ScatterHandle Handle for storing scatterplots
        ScatterHandle
    end

    properties (Constant,Hidden)
        InterpolationMethodNearest = "nearest"
        InterpolationMethodLinear = "linear"
        InterpolationMethodQuadratic = "quadratic"
    end

    methods
        function obj = meshtsdf(meshArray,nv)
        %meshtsdf Store signed distance over variably sized 3D region
            arguments
                meshArray (:,1) = meshtsdf.meshStruct();
                nv.Resolution (1,1) {mustBeNumeric, mustBePositive, mustBeFinite} = 1.0;                    % cell/m
                nv.TruncationDistance (1,1) {mustBeNumeric} = nan;                                                          % m
                nv.FillInterior (1,1) {mustBeInteger,mustBeMember(nv.FillInterior,[0 1])} = 0;
            end

            if isnan(nv.TruncationDistance)
                % The minimum truncation distance
                nv.TruncationDistance = 3/nv.Resolution;
            else
                nav.geometry.internal.TSDFUtils.validateTruncationDistance(3/nv.Resolution,nv.TruncationDistance);
            end

            useFastSweep = true;

            % Create builtin object
            if coder.target('MATLAB')
                obj.MeshtsdfBuiltin = nav.geometry.internal.MeshtsdfBuiltin(...
                    nv.Resolution, nv.TruncationDistance, logical(nv.FillInterior), useFastSweep);
            else
                obj.MeshtsdfBuiltin = nav.geometry.internal.coder.meshtsdfBuildable(nv.Resolution, ...
                                                                                      nv.TruncationDistance, logical(nv.FillInterior), useFastSweep);
            end

            if ~isempty(meshArray)
                % Add meshes
                obj.addMesh(meshArray);
            end
        end

        function meshAdded = addMesh(obj,meshStructArray)
        %addMesh Discretize mesh and compute TSDF
        %
        %   MESHADDED = addMesh(OBJ, MESHSTRUCT) accepts an Nx1
        %   struct-array of meshes, MESHSTRUCT, and computes the TSDF
        %   within +/-TruncationDistance of each mesh. Returns MESHADDED,
        %   an N-element vector indicating whether the corresponding mesh
        %   was successfully added (1), or the mesh ID already exists (0).
        %
        %   Example:
        %       % Create an empty TSDF
        %       tsdf = meshtsdf(Resolution=10);
        %
        %       % Create mesh and convert to struct-array
        %       geom = collisionMesh(rand(10,3)*10);
        %       meshStruct = geom2struct({geom});
        %
        %       % Convert mesh to TSDF
        %       success = addMesh(tsdf,meshStruct);
        %       assert(success)
        %
        %       % Attempt to add the mesh a second time and verify failure
        %       success = addMesh(tsdf,meshStruct);
        %       assert(~success);
        %
        %       % Add the same geometry under a new ID in a new location
        %       meshStruct.Pose = [quat2rotm(randrot) rand(3,1)*5; 0 0 0 1];
        %       meshStruct.ID = 2;
        %       success = addMesh(tsdf,meshStruct);
        %       assert(success);
        %
        %       % Display
        %       show(tsdf);
        %
        %   See also: removeMesh, meshtsdf/MESHSTRUCT

            arguments
                obj
                meshStructArray (:,1) struct = meshtsdf.meshStruct();
            end
            if ~isempty(meshStructArray)
                % Validate mesh array
                validatedArray = meshtsdf.validateMeshStruct(meshStructArray);

                % Add meshes
                meshAdded = obj.MeshtsdfBuiltin.addMeshes(validatedArray(:));
            else
                meshAdded = zeros(0,1);
            end
        end

        function poseUpdated = updatePose(obj,poseStruct)
        %updatePose Update pose of one or more mesh TSDF
        %
        %   POSEUPDATED = updatePose(OBJ, POSESTRUCT) updates the pose of
        %   stored TSDFs corresponding to the N-element struct-array
        %   containing the following fields:
        %
        %           ID       : integer-valued scalar identifier.
        %                       (Defaults to 1:N)
        %           Pose     : The 4x4 transformation from the world frame to the
        %                      frame in which the vertices are defined
        %
        %   Returns POSEUPDATED, an N-element vector indicating whether the
        %   pose of the corresponding ID was successfully changed (1) or
        %   the mesh ID was not found (0).
        %
        %   Example:
        %
        %       % Create TSDF from geometry
        %       geom = {collisionSphere(1), collisionMesh(rand(10,3)*3)};
        %       meshStruct = geom2struct(geom);
        %       tsdf = meshtsdf(meshStruct,Resolution=10);
        %
        %       % Display the object
        %       subplot(1,2,1);
        %       show(tsdf);
        %
        %       % Move the second TSDF
        %       poseStruct = poses(tsdf,tsdf.MeshID(2));
        %       poseStruct.Pose(1:3,:) = [quat2rotm(randrot) rand(3,1)*10];
        %       success = updatePose(tsdf,poseStruct);
        %
        %       % Display the updated TSDF
        %       subplot(1,2,2);
        %       show(tsdf);
        %
        %   See also meshtsdf/POSESTRUCT

            arguments
                obj
                poseStruct (:,1) struct = meshtsdf.emptyPoseStruct();
            end

            if ~isempty(poseStruct)
                % Validate pose array
                validatedArray = meshtsdf.validatePoseStruct(poseStruct);

                % Update poses
                poseUpdated = obj.MeshtsdfBuiltin.updatePoses(validatedArray(:));
            else
                poseUpdated = zeros(0,1);
            end
        end

        function removeMesh(obj,id)
        %removeMesh Remove one or more TSDF
        %
        %   MESHREMOVED = removeMesh(OBJ,ID) removes one or more objects
        %   from the TSDF manager, corresponding to the N-element ID
        %   vector. Returns N-element vector, MESHREMOVED, indicating
        %   objects that were present and successfully removed (1).
        %
        %   Example:
        %
        %       % Create TSDF from geometry
        %       geom = collisionSphere(1);
        %       meshStruct = geom2struct({geom});
        %       tsdf = meshtsdf(meshStruct,Resolution=10);
        %       assert(tsdf.NumMesh == 1);
        %
        %       % Remove currently present mesh
        %       ID = tsdf.MeshID;
        %       removeMesh(tsdf,ID);
        %
        %   See also: addMesh

            arguments
                obj
                id (:,1) {mustBeInteger, mustBePositive} = ones(0,1);
            end
            if ~isempty(id)
                obj.MeshtsdfBuiltin.removeID(id);
            end
        end

        function dist = distance(obj,pts,nv)
        %distance Compute distance to the zero level set
        %
        %   DIST = distance(OBJ,PTS) takes in an Nx3 matrix of xyz
        %   query points, PTS, and returns the distance stored in their
        %   corresponding voxel. If the voxel lies outside the truncated or
        %   dilated radius, the distance will be the background value.
        %
        %   DIST = distance(OBJ,PTS,Name,Value) takes in optional
        %   name-value pairs:
        %
        %       InterpolationMethod - Method used for interpolation
        %
        %           nearest     : Returns the distance stored in the xyz's
        %                         corresponding voxel.
        %
        %           linear      : Uses trilinear interpolation to compute
        %                         distance using the 8 voxels surrounding
        %                         the query point.
        %
        %           quadratic   : Uses quadratic interpolation to compute
        %                         distance using the 27 voxels surrounding
        %                         the query point.
        %
        %   Example:
        %
        %       % Create empty field with resolution of 10 cells/meter
        %       tsdf = meshtsdf(Resolution=10);
        %
        %       % Create mesh of a closed volume
        %       capsule = collisionCapsule(1,5); % (radius,length)
        %       T = se3(eye(3), rand(1,3)*20).tform;
        %       capsule.Pose = T;
        %       [~,h] = show(capsule)
        %
        %       % Integrate mesh into the map
        %       meshStruct = geom2struct({capsule});
        %       addMesh(tsdf,meshStruct);
        %
        %       % Compute distance to mesh using various types of interpolation
        %       queryPt = T(1:3,end)' + 0.5;
        %       distNone        = distance(tsdf,queryPt);
        %       distLinear      = distance(tsdf,queryPt,InterpolationMethod="linear");
        %       distQuadratic   = distance(tsdf,queryPt,InterpolationMethod="quadratic");
        %
        %   See also: gradient

            arguments
                obj
                pts (:,3) double {mustBeReal, mustBeFinite}
                nv.InterpolationMethod (1,1) string {mustBeMember(nv.InterpolationMethod,{'nearest','linear','quadratic'})} = "nearest"
            end
            switch nv.InterpolationMethod
                case meshtsdf.InterpolationMethodNearest
                    iMethod = 0;
                case meshtsdf.InterpolationMethodLinear
                    iMethod = 1;
                case meshtsdf.InterpolationMethodQuadratic
                    iMethod = 2;
            end
            if obj.NumActiveVoxel == 0
                dist = repelem(obj.TruncationDistance,size(pts,1),1);
            else
                dist = obj.MeshtsdfBuiltin.distance(pts,iMethod);
            end
        end

        function grad = gradient(obj,pts,nv)
        %gradient Compute gradient of the signed distance field
        %
        %   GRAD = gradient(OBJ,PTS) takes in an Nx3 matrix of xyz
        %   query points, PTS, and returns the Nx3 gradient computed from
        %   voxels in the vicinity.
        %
        %   GRAD = gradient(OBJ,PTS,Name=Value) takes in optional
        %   name-value pairs:
        %
        %       InterpolationMethod - Method used for interpolation
        %
        %           linear      : Computes partial derivatives of the
        %                         trilinearly-interpolated distance field.
        %
        %           quadratic   : Computes partial derivatives of the
        %                         triquadratically-interpolated distance
        %                         field.
        %   Example:
        %
        %       % Create empty field with resolution of 10 cells/meter
        %       tsdf = meshtsdf(Resolution=10);
        %
        %       % Create mesh of a closed volume
        %       capsule = collisionCapsule(1,5); % (radius,length)
        %       T = se3(eye(3), rand(1,3)*20).tform;
        %       capsule.Pose = T;
        %       [~,h] = show(capsule)
        %
        %       % Integrate mesh into the map
        %       meshStruct = geom2struct({capsule});
        %       addMesh(tsdf,meshStruct);
        %
        %       % Compute gradient near mesh using various types of interpolation
        %       queryPt = T(1:3,end)' + 0.5;
        %       gradLinear      = gradient(tsdf,queryPt,InterpolationMethod="linear");
        %       gradQuadratic   = gradient(tsdf,queryPt,InterpolationMethod="quadratic");
        %
        %   See also: distance

            arguments
                obj
                pts (:,3) double {mustBeReal, mustBeFinite}
                nv.InterpolationMethod (1,1) string {mustBeMember(nv.InterpolationMethod,{'linear','quadratic'})} = "linear"
            end
            switch nv.InterpolationMethod
                case meshtsdf.InterpolationMethodLinear
                    iMethod = 1;
                case meshtsdf.InterpolationMethodQuadratic
                    iMethod = 2;
            end
            if obj.NumActiveVoxel == 0
                grad = nan(size(pts,1),3);
            else
                grad = obj.MeshtsdfBuiltin.gradient(pts,iMethod);
            end
        end

        function poseStruct = poses(obj,id)
        %poses Retrieve poses for one or more TSDF
        %
        %   POSESTRUCT = poses(OBJ) retrieves the N-element struct-array
        %   containing the following fields:
        %
        %       ID      - scalar identifier corresponding to mesh in OBJ
        %       Pose    - 4x4 homogeneous transformation
        %
        %   [___] = poses(OBJ, ID) accepts an N-element vector of mesh ID,
        %   and returns an M-element pose struct-array containing poses and
        %   ids. IDs not found in OBJ are ignored.
        %
        %   Example:
        %
        %       % Create object with multiple TSDF
        %       geom = {collisionSphere(1), collisionMesh(rand(10,3))};
        %       geom{2}.Pose(1:3,end) = 10;
        %       geomStruct = geom2struct(geom);
        %       tsdf = meshtsdf(geomStruct,Resolution=10);
        %
        %       % Query pose of all objects
        %       poseStruct1 = poses(tsdf);
        %
        %       % Query pose of last obj and another ID that does not exist
        %       queryID = [tsdf.MeshID(end) 10];
        %       poseStruct2 = poses(tsdf,queryID);
        %       mustBeScalarOrEmpty(poseStruct2);
        %       assert(isequal(poseStruct1(end),poseStruct2));
        %
        %   See also: updatePose

            arguments
                obj

                %id unique identifiers of TSDF
                id (:,1) double {mustBeInteger} = []
            end

            % Retrieve poses for all VDB objects being managed
            poseStruct = obj.MeshtsdfBuiltin.getPoses();

            if ~isempty(id)
                % Filter out those that were not requested
                poseStruct(~ismember([poseStruct.ID],id)) = [];
            end
        end

        function voxStruct = activeVoxels(obj,id)
        %activeVoxels Return voxel info
        %
        %   VOXSTRUCT = activeVoxels(OBJ) returns N-element VOXSTRUCT, a
        %   struct-array, containing the following fields for each TSDF:
        %
        %       ID          - Unique scalar identifier
        %       Distances   - Mx1 distance stored in each active voxel
        %       Centers     - Mx3 XYZ location of all active voxels
        %       Sizes       - Mx1 size of corresponding voxel
        %
        %   [___] = activeVoxels(OBJ,ID) optionally takes in N-element
        %   vector of IDs. IDs not found in OBJ are ignored.
        %
        %   Example:
        %
        %       % Create object with multiple TSDF
        %       geom = {collisionSphere(1), collisionMesh(rand(10,3))};
        %       geom{2}.Pose(1:3,end) = 10;
        %       geomStruct = geom2struct(geom);
        %       tsdf = meshtsdf(geomStruct,Resolution=10);
        %
        %       % Query voxel info for all objects
        %       voxInfo1 = activeVoxels(tsdf);
        %
        %       % Query info of last obj and another ID that does not exist
        %       queryID = [tsdf.MeshID(end) 10];
        %       voxInfo2 = activeVoxels(tsdf,queryID);
        %       assert(isequal(voxInfo1(end),voxInfo2));
        %
        %   See also: poses

            arguments
                obj

                %id unique identifiers of TSDF
                id (:,1) {mustBeInteger,mustBePositive} = ones(0,1);
            end

            % Retrieve voxels for all VDB objects being managed
            voxStruct = obj.MeshtsdfBuiltin.activeVoxels();

            if ~isempty(id)
                % Filter out those that were not requested
                voxStruct(~ismember([voxStruct.ID],id)) = [];
            end
        end

        function [h,hBar] = show(obj,nv)
        %show Display the TSDFs in a figure
        %
        %   H = show(OBJ) Displays active voxels for each mesh as an array
        %   of scatter plots, H, with red->green colors corresponding to 
        %   most negative to most positive distance values.
        %
        %   H = show(OBJ,Name=Value) takes in optional name-value
        %   pairs:
        %
        %       Parent          - Axes to plot the map, specified as an
        %                         axes handle.
        %
        %                           Default: gca
        %
        %       MeshID          - N-element vector of TSDF ID to visualize
        %
        %                           Default: obj.MeshID
        %
        %       IsoRange        - 2-element vector specifying the range of
        %                         distance values to consider during
        %                         visualization.
        %
        %                           Default: [-inf inf]
        %
        %
        %   Example:
        %
        %       % Create TSDF from geometry
        %       geom = {collisionSphere(1), collisionMesh(rand(10,3)*3)};
        %       meshStruct = geom2struct(geom);
        %       tsdf = meshtsdf(meshStruct,Resolution=10);
        %
        %       % Display all TSDF
        %       nexttile;
        %       show(tsdf);
        %
        %       % Only display the first TSDF
        %       nexttile;
        %       show(tsdf,MeshID=tsdf.MeshID(1));
        %
        %       % Display points lying near the boundary of second TSDF
        %       nexttile;
        %       voxDist = 1/tsdf.Resolution;
        %       show(tsdf,MeshID=tsdf.MeshID(2),IsoRange=voxDist*[-1 1]);

            arguments
                obj
                nv.Parent (1,1) {mustBeA(nv.Parent,{'matlab.graphics.axis.Axes','matlab.graphics.GraphicsPlaceholder'})} = matlab.graphics.GraphicsPlaceholder
                nv.IsoRange (1,2) {mustBeNumeric} = [-inf inf];
                nv.MeshID (:,1) double {mustBeNumeric, mustBePositive, mustBeInteger} = obj.MeshID;
                nv.Colorbar (1,1) matlab.lang.OnOffSwitchState = 'off'
                nv.FastUpdate (1,1) matlab.lang.OnOffSwitchState = 'off'
            end

            % Validate inputs
            validateattributes(nv.IsoRange,{'numeric'},{"increasing"},'IsoRange');
            mustBeMember(nv.MeshID,obj.MeshID);
            
            % Display object
            voxStruct = obj.activeVoxels(nv.MeshID);
            if nargout == 0
                nav.geometry.internal.TSDFUtils.showImpl(obj,voxStruct,nv);
            else
                [h,hBar] = nav.geometry.internal.TSDFUtils.showImpl(obj,voxStruct,nv);
            end
        end

        function copyObj = copy(obj)
        %copy Creates a deep copy of the handle object

        % Create empty object
            copyObj = meshtsdf();

            % Serialize the current C++ builtin and overwrite the new
            % object's builtin with the serialized information
            data = obj.MeshtsdfBuiltin.serialize();

            if coder.target('MATLAB')
                copyObj.MeshtsdfBuiltin.deserialize(data);
            else
                copyObj.MeshtsdfBuiltin = copyObj.MeshtsdfBuiltin.deserialize(data);
            end
        end
    end

    methods (Hidden)
        function S = saveobj(obj)
        % Serialize underlying C++ builtin
            data = obj.MeshtsdfBuiltin.serialize();

            % Store as property on a struct
            S.MgrData = data;
        end

        function [dMax,dRange] = depthInfo(obj,voxStruct,isoRange)
        %depthInfo Compute distance interval for visualization
            td = obj.TruncationDistance;
            if obj.FillInterior
                maxDepth = min(arrayfun(@(x)min(x.Distance),voxStruct));
                dRange = [max(isoRange(1),maxDepth) min(isoRange(2),td)];
            else
                dRange = [max(isoRange(1),-td) min(isoRange(2),td)];
            end
            dMax = max(abs(dRange));
        end
    end

    methods % Getters
        function numVoxel = get.Resolution(obj)
        %get.Resolution
            numVoxel = obj.MeshtsdfBuiltin.Resolution;
        end

        function numVoxel = get.TruncationDistance(obj)
        %get.TruncationDistance
            numVoxel = obj.MeshtsdfBuiltin.TruncationDistance;
        end

        function fillInteriorTF = get.FillInterior(obj)
        %get.FillInterior
            fillInteriorTF = obj.MeshtsdfBuiltin.FillInterior;
        end

        function numVoxel = get.NumActiveVoxel(obj)
        %get.NumActiveVoxels
            numVoxel = obj.MeshtsdfBuiltin.NumActiveVoxel;
        end

        function bounds = get.MapLimits(obj)
        %get.MapLimits
            bounds = obj.MeshtsdfBuiltin.MapLimits;
        end

        function bounds = get.MeshID(obj)
        %get.MapLimits
            bounds = obj.MeshtsdfBuiltin.VDBID;
        end

        function N = get.NumMesh(obj)
        %get.NumMesh
            N = obj.MeshtsdfBuiltin.NumVDB;
        end
    end

    methods (Static)
        function meshStruct = meshStruct(N)
        %meshStruct Create varsize-compatible struct for mesh
        %
        %   MESHSTRUCT = meshtsdf.meshStruct returns a 0x1 mesh
        %   struct with required fields
        %
        %   MESHSTRUCT = meshtsdf.meshStruct(N) Generates an Nx1
        %   struct-array with required fields
        %
        %   See also: meshtsdf/MESHSTRUCT

            arguments
                N (1,1) double {mustBeNonnegative, mustBeInteger} = 0;
            end

            meshStruct = robotics.internal.meshStruct(N);
        end

        function poseStruct = poseStruct(N)
        %emptyPoseStruct Create empty struct with fields to represent poses
        %
        %   poseStruct = meshtsdf.poseStruct returns a 0x1 pose
        %   struct with required fields
        %
        %   poseStruct = meshtsdf.poseStruct(N) returns an Nx1 pose
        %   struct with required fields
        %
        %   See also: meshtsdf/POSESTRUCT

            arguments
                N (1,1) double {mustBeNonnegative, mustBeInteger} = 0;
            end

            % Create default struct type
            poseStruct = repelem(struct('ID',0,'Pose',eye(4)),N,1);
        end
    end

    methods (Hidden,Static)
        function obj = loadobj(S)
        % Create empty object
            obj = meshtsdf();

            % Deserialize saved data
            obj.MeshtsdfBuiltin.deserialize(S.MgrData);
        end

        function sFormatted = validateStruct(S,requiredFields,fCreateStruct,fValidateElement,errId)
        %validateStruct Validate and format all elements of struct-array
            N = numel(S);
            sFormatted = fCreateStruct(N);

            if ~isempty(S)
                % Check whether struct-array contains correct fields
                for i = 1:numel(requiredFields)
                    if ~isfield(S,requiredFields{i})
                        errMsg = struct('message',strjoin(["Struct must contain the following fields: ",strjoin(requiredFields,',')]),...
                                        'identifier', ['TemporaryTSDFError:' errId]);
                        error(errMsg);
                    end
                end

                % Validate each element
                for i = 1:N
                    sFormatted(i,1) = fValidateElement(S(i));
                end
            end
        end

        function sFormatted = validateMeshStruct(meshStruct)
        %validateMeshStruct Validate geometry array in struct format
            arguments
                meshStruct (:,1) struct
            end
            fCreateStruct = @(N)meshtsdf.meshStruct(N);
            fValidateElement = @(S)meshtsdf.validateMeshArrayElement(S.ID,S.Pose,S.Vertices,S.Faces);
            requiredFields = {'ID','Pose','Vertices','Faces'};
            sFormatted = meshtsdf.validateStruct(meshStruct,requiredFields,fCreateStruct,fValidateElement,'MissingMeshFields');
        end

        function sFormatted = validatePoseStruct(poseStruct)
        %validatePoseStruct Validate pose array in struct format
            arguments
                poseStruct (:,1) struct
            end
            fCreateStruct = @meshtsdf.poseStruct;
            fValidateElement = @(S)meshtsdf.validatePoseArrayElement(S.ID,S.Pose);
            requiredFields = {'ID','Pose'};
            sFormatted = meshtsdf.validateStruct(poseStruct,requiredFields,fCreateStruct,fValidateElement,'MissingPoseFields');
        end

        function S = validateMeshArrayElement(id,pose,vert,face)
        %validateMeshArrayElement Validate individual mesh struct fields
            arguments
                id (1,1) double {mustBeInteger,mustBePositive}
                pose double {mustBeReal,mustBeFinite,validateattributes(pose,{'numeric'},{'size',[4,4]})}
                vert (:,3) double {mustBeNonempty,mustBeReal,mustBeFinite}
                face {meshtsdf.validateFaces(vert,face)}
            end
            S = struct("ID",id,"Pose",pose,"Vertices",vert,"Faces",face);
        end

        function validateFaces(V,F)
        %validateMeshArrayElement Ensure face indices are valid
            arguments
                V
                F (:,3) double {mustBeInteger,mustBePositive,mustBeNonempty};
            end
            mustBeLessThanOrEqual(F,size(V,1));
        end

        function S = validatePoseArrayElement(id,pose)
        %validatePoseArrayElement Validate individual pose struct fields
            arguments
                id (1,1) {mustBeInteger,mustBePositive}
                pose double {mustBeReal,mustBeFinite,validateattributes(pose,{'numeric'},{'size',[4,4]})}   % Only check for size/type
            end
            S = struct("ID",id,"Pose",pose);
        end
    end

    properties (Hidden)
        %MESHSTRUCT N-element struct-array containing the following fields
        %
        %           ID       : integer-valued scalar identifier.
        %                       (Defaults to 1:N)
        %           Vertices : Nx3 list of vertices w.r.t. the Pose frame
        %           Faces    : Nx3 matrix where each row contains three indices
        %                      corresponding to rows in the Vertices matrix forming
        %                      a triangle
        %           Pose     : The 4x4 transformation from the world frame to the
        %                      frame in which the vertices are defined
        %
        %     NOTE: Each element may contain different number of Vertices/Faces.
        MESHSTRUCT

        %POSESTRUCT N-element struct-array containing the following fields
        %
        %           ID       : integer-valued scalar identifier.
        %                       (Defaults to 1:N)
        %           Pose     : The 4x4 transformation from the world frame to the
        %                      frame in which the vertices are defined
        POSESTRUCT
    end
end
