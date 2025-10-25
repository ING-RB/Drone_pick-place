classdef factorGraph < nav.algs.internal.InternalAccess
%

%   Copyright 2021-2025 The MathWorks, Inc.

%#codegen

    properties (Access=protected)
        GraphInternal

        NodeID
    end

    properties (Dependent, SetAccess=protected)
        NumNodes

        NumFactors
    end

    methods % getters
        function nn = get.NumNodes(obj)
            %get.NumNodes
            nn = obj.GraphInternal.getNumNodes();
        end

        function nf = get.NumFactors(obj)
            %get.NumFactors
            nf = obj.GraphInternal.getNumFactors();
        end
    end

    methods (Access = {?factorGraph})
        function updateNodeID(obj, nodeID)
            %updateNodeID Update NodeID with largest existing node ID
            if(nodeID>obj.NodeID)
                % only update NodeID when it is smaller than added nodeID
                obj.NodeID = nodeID;
            end
        end
    end
    
    methods
        function obj = factorGraph()

            if coder.target('MATLAB')
                obj.GraphInternal = nav.algs.internal.builtin.FactorGraph;
            else
                obj.GraphInternal = nav.algs.internal.codegen.FactorGraph;
            end
            obj.NodeID = -1;
        end

        function ids = nodeIDs(obj, varargin)
            %

            % Checking the number of input arguments
            narginchk(1,7);

            % Default names for plan method
            defaultNames = { 'NodeType', 'FactorType', 'GroupID'};

            % Default values for plan method
            defaultValues = {'None', 'None', -1};

            % Parsing name-value pairs
            Parser = robotics.core.internal.NameValueParser(defaultNames, defaultValues);
            parse(Parser, varargin{:});

            % Validating string type inputs and assigning input values to the properties
            GroupID = parameterValue(Parser, 'GroupID');
            if GroupID ~= -1
                validateattributes(GroupID, 'numeric', ...
                    {'row', 'integer', 'nonnegative', 'nonsparse'}, 'factorGraph/nodeIDs', 'GroupIDs');
                % Check for duplicate GroupIDs
                coder.internal.errorIf(numel(unique(GroupID(:))) ~= numel(GroupID(:)),...
                    'nav:navalgs:factorgraph:NoDuplicateGroupIDs');
            end
            NodeType = validatestring(parameterValue(Parser, 'NodeType'), {'POSE_SE3', 'POSE_SE2',...
                'VEL3', 'POINT_XY', 'POINT_XYZ', 'IMU_BIAS', 'POSE_SE3_SCALE', 'TRANSFORM_SE3', 'None'}, 'nodeIDs', 'NodeType');
            FactorType = validatestring(parameterValue(Parser, 'FactorType'), {'factorIMU', 'factorTwoPoseSE2',...
                'factorTwoPoseSE3', 'factorTwoPoseSIM3', 'factorPoseSE2AndPointXY', 'factorPoseSE3AndPointXYZ', 'factorIMUBiasPrior',...
                'factorPoseSE3Prior', 'factorVelocity3Prior', 'factorGPS', 'factorCameraSE3AndPointXYZ', 'None'}, 'factorGraph/nodeIDs', 'FactorType');

            ids = obj.GraphInternal.getNodeIDs(int32(GroupID), NodeType, FactorType);
        end
        
        function nID = generateNodeID(obj, N, factorType)       

            narginchk(2, 3);
            if nargin == 2
                validateattributes(N,'numeric',{'integer', 'nonempty', 'positive', 'vector'}, ...
                    'factorGraph/generateNodeID', 'N');
                dim = numel(N);
                if dim==1
                    nID = obj.NodeID + (1:N);
                    obj.NodeID = obj.NodeID+N;
                elseif dim==2
                    nID = obj.NodeID + (1:N(1)*N(2));
                    nID = reshape(nID, [N(2), N(1)]);
                    nID = nID';
                    obj.NodeID = obj.NodeID+N(1)*N(2);
                else 
                    coder.internal.error('nav:navalgs:factorgraph:MismatchedNodeIDDimension');
                end

            else
                validateattributes(N,'numeric',{'integer', 'nonempty', 'positive', 'scalar'}, ...
                    'factorGraph/generateNodeID', 'N');
                validatestring(factorType, {'factorIMU', 'factorGPS', 'factorCameraSE3AndPointXYZ', 'factorTwoPoseSE2',...
                    'factorTwoPoseSE3', 'factorPoseSE2AndPointXY', 'factorPoseSE3AndPointXYZ',...
                    'factorIMUBiasPrior', 'factorPoseSE3Prior', 'factorVelocity3Prior', 'factorTwoPoseSIM3'},...
                    'factorGraph/generateNodeID', 'factorType');
                switch factorType
                    case 'factorIMU'
                        if N>1
                            % factorIMU does not support multiple node ID
                            % pairs for now
                            coder.internal.error('nav:navalgs:factorgraph:TooManyFactorIMU');
                        else
                            nID = obj.NodeID + (1:6);
                            obj.NodeID = obj.NodeID + 6;
                        end

                    case 'factorGPS'
                        if N>1
                            % factorGPS does not support multiple node ID
                            % pairs for now
                            coder.internal.error('nav:navalgs:factorgraph:TooManyFactorGPS');
                        else
                            nID = obj.NodeID + 1;
                            obj.NodeID = obj.NodeID + 1;
                        end

                    case 'factorTwoPoseSE2'
                        nID = repmat(obj.NodeID,N,2);
                        nID(:,1) = nID(:,1) + (1:N)';
                        nID(:,2) = nID(:,2) + (2:N+1)';
                        obj.NodeID = obj.NodeID+N+1;

                    case 'factorTwoPoseSE3'
                        nID = repmat(obj.NodeID,N,2);
                        nID(:,1) = nID(:,1) + (1:N)';
                        nID(:,2) = nID(:,2) + (2:N+1)';
                        obj.NodeID = obj.NodeID+N+1;

                    case 'factorCameraSE3AndPointXYZ'
                        nID = repmat(obj.NodeID,N,2);
                        nID(:,1) = nID(:,1) + ones(N,1);
                        nID(:,2) = nID(:,2) + (2:N+1)';
                        obj.NodeID = obj.NodeID+N+1;

                    case 'factorPoseSE2AndPointXY'
                        nID = repmat(obj.NodeID,N,2);
                        nID(:,1) = nID(:,1) + ones(N,1);
                        nID(:,2) = nID(:,2) + (2:N+1)';
                        obj.NodeID = obj.NodeID+N+1;

                    case 'factorPoseSE3AndPointXYZ'
                        nID = repmat(obj.NodeID,N,2);
                        nID(:,1) = nID(:,1) + ones(N,1);
                        nID(:,2) = nID(:,2) + (2:N+1)';
                        obj.NodeID = obj.NodeID+N+1;

                    case 'factorIMUBiasPrior'
                        nID = obj.NodeID + (1:N)';
                        obj.NodeID = obj.NodeID+N;

                    case 'factorPoseSE3Prior'
                        nID = obj.NodeID + (1:N)';
                        obj.NodeID = obj.NodeID+N;

                    case 'factorVelocity3Prior'
                        nID = obj.NodeID + (1:N)';
                        obj.NodeID = obj.NodeID+N;
                    case 'factorTwoPoseSIM3'
                        nID = repmat(obj.NodeID,N,4);
                        nID(:,1) = nID(:,1) + (1:2:2*N)';
                        nID(:,2) = nID(:,2) + (2:2:2*N+1)';
                        nID(:,3) = nID(:,3) + (3:2:2*(N+1))';
                        nID(:,4) = nID(:,4) + (4:2:2*N+3)';
                        obj.NodeID = nID(end,4);
                end
            end

        end

        function fID = addFactor(obj, factor, groupID)

            fID = -1;

            if nargin == 2
                groupID = -1;
            else
                validateattributes(groupID, 'numeric', ...
                    {'integer', 'nonnegative', 'nonsparse','nonempty'}, 'factorGraph/addFactor', 'groupID');
                if size(groupID,1)>1&&size(groupID,1)~=size(factor.NodeID,1)
                    coder.internal.error('nav:navalgs:factorgraph:MismatchedGroupIDNumber');
                end
            end
            
            if size(groupID,2)==1 && size(factor.NodeID,2)>1
                GroupID = repmat(groupID, 1, 2);
            else
                GroupID = groupID;
            end

            if isa(factor, "factorIMU")
                coder.internal.errorIf(size(GroupID,2)>2, 'nav:navalgs:factorgraph:MismatchedGroupIDDimension');
                if coder.target("MATLAB")
                    fID = obj.GraphInternal.addFactor(factor.createBuiltinObject(),int32(GroupID));
                else
                    fID = obj.GraphInternal.addFactorIMU(factor,int32(GroupID));
                end
                coder.internal.errorIf(fID==-1, 'nav:navalgs:factorgraph:MismatchedNodeType');

            elseif isa(factor,"factorCameraSE3AndPointXYZ")
                coder.internal.errorIf(size(GroupID,2)>2, 'nav:navalgs:factorgraph:MismatchedGroupIDDimension');
                Im = pagectranspose(factor.Information);
                s = factor.SensorTransform.tform';
                Nd = (factor.NodeID)';
                gID = GroupID';

                if strcmp(factor.InternalFactorType, "")
                    % regular projection factor
                    kSize = size(factor.K);
                    if length(kSize)==3
                        kInd = ((0:(kSize(3)-1))*9)';
                        ind1 = 7 + kInd;
                        ind2 = 8 + kInd;
                        ind3 = 1 + kInd;
                        ind4 = 5 + kInd;
                        measurement = [factor.Measurement(:,1)-factor.K(ind1),factor.Measurement(:,2)-factor.K(ind2),factor.K(ind3),factor.K(ind4)]';
                    else
                        measurement = [factor.Measurement(:,1)-factor.K(1,3),factor.Measurement(:,2)-factor.K(2,3),repmat(factor.K(1,1),size(factor.Measurement,1),1),repmat(factor.K(2,2),size(factor.Measurement,1),1)]';
                    end
                    fID = double(obj.GraphInternal.addFactorCameraProjection(convertStringsToChars(factor.FactorType), int32(Nd(:)), ...
                    measurement(:), Im(:), size(Nd,2), int32(gID(:)), s(:)));
                else
                    % distorted projection factor
                    measurement = factor.Measurement';
                    intrinsics = factor.IntrinsicVector';
                    fID = double(obj.GraphInternal.addFactorDistortedCameraProjection(convertStringsToChars(factor.InternalFactorType), int32(Nd(:)), ...
                    measurement(:), Im(:), size(Nd,2), intrinsics(:), s(:), int32(gID(:))));
                end
                
                
            else
                if isa(factor, "nav.algs.internal.factorPoseSE2Prior") || isa(factor, "factorVelocity3Prior") || ...
                    isa(factor, "factorIMUBiasPrior")
                    coder.internal.errorIf(size(GroupID,2)>1, 'nav:navalgs:factorgraph:MismatchedGroupIDDimensionForPrior');
                    measurement = factor.Measurement;
                    Im = pagetranspose(factor.Information);
                
                elseif isa(factor, "factorTwoPoseSE2") || isa(factor, "factorPoseSE2AndPointXY") || ...
                    isa(factor, "factorPoseSE3AndPointXYZ")
                    coder.internal.errorIf(size(GroupID,2)>2, 'nav:navalgs:factorgraph:MismatchedGroupIDDimension');
                    measurement = factor.Measurement;
                    Im = pagetranspose(factor.Information);

                elseif isa(factor, "factorTwoPoseSE3") || isa(factor, "factorPoseSE3Prior")
                    if isa(factor, "factorPoseSE3Prior")
                        coder.internal.errorIf(size(GroupID,2)>1, 'nav:navalgs:factorgraph:MismatchedGroupIDDimensionForPrior');
                    else 
                        coder.internal.errorIf(size(GroupID,2)>2, 'nav:navalgs:factorgraph:MismatchedGroupIDDimension');
                    end
                    measurement = factor.Measurement;
                    % internal API expects SE(3) pose in [x, y, z, qx, qy, qz, qw]
                    measurement = [measurement(:,1:3), measurement(:,5:7), measurement(:,4)]; 
                    Im = pagetranspose(factor.Information);
                elseif isa(factor, "factorTwoPoseSIM3")
                    coder.internal.errorIf(size(GroupID,2)>2, 'nav:navalgs:factorgraph:MismatchedGroupIDDimension');
                    measurement = factor.Measurement;
                    % internal API expects SIM(3) pose in [x, y, z, qx, qy, qz, qw]
                    measurement = [measurement(:,1:3), measurement(:,5:7), measurement(:,4), log(measurement(:,8))]; 
                    Im = pagetranspose(factor.Information);
                elseif isa(factor, "factorGPS")
                    [measurement, information]= factor.factorGraphMeasurements();
                    Im = pagetranspose(information);
                else
                    return;
                end
                Nd = (factor.NodeID)';
                gID = GroupID';
                measurement = measurement';
                fID = double(obj.GraphInternal.addFactorGaussianNoiseModel(convertStringsToChars(factor.FactorType), int32(Nd(:)), ...
                        measurement(:), Im(:), size(Nd,2), int32(gID(:))));
            end
            if(fID(end)==-1)
                % There are invalid nodes
                if coder.target("MATLAB")
                    invalidId = num2cell(fID(1:end-1));
                    requiredType = cell(1,numel(invalidId));
                    curType = cell(1,numel(invalidId));
                    for i=1:numel(invalidId)
                       requiredType{i} = obj.GraphInternal.getNodeType(invalidId{i});
                       curType{i} = factor.nodeType(invalidId{i});
                    end
                    celldata = [invalidId; requiredType; curType];
                    errormsg = sprintf('Factor requires node %d to be type %s, but it exists in the factor graph as type %s.\n', celldata{:});
                    coder.internal.error('nav:navalgs:factorgraph:MismatchedNodeTypeWithID', errormsg);
                else
                    coder.internal.errorIf(fID(end)==-1, 'nav:navalgs:factorgraph:MismatchedNodeType');
                end
            else
                % Factor is successfully added. Update NodeID with largest added node ID
                updateNodeID(obj, max(factor.NodeID(:)));
            end
        end

        function output = nodeState(obj, ids, states)
            
            narginchk(2,3);
            nav.algs.internal.validation.preValidateNodeIDs(ids, 'factorGraph/nodeState', 'id');
            if nargin == 2
                % get
                outputI = obj.GraphInternal.getNodeState(int32(ids));
                if isnan(outputI(end)) && (outputI(end-1)==-1)
                    % There are node IDs not in the factor graph
                    if coder.target("MATLAB")
                        % remove the flag
                        outputI = outputI(1:end-2);
                        invalidId = ids(outputI<0);
                        errormsg = sprintf('%d ', invalidId);
                        coder.internal.error('nav:navalgs:factorgraph:NodeIDNotFoundInFactorGraphWithID', errormsg);
                    else
                        coder.internal.error('nav:navalgs:factorgraph:NodeIDNotFoundInFactorGraph');
                    end
                elseif isnan(outputI(end)) && (outputI(end-1)==-2)
                    % There are nodes with different type
                    type = obj.GraphInternal.getNodeType(ids(1));
                    if coder.target("MATLAB")
                        % remove the flag
                        outputI = outputI(1:end-2);
                        invalidId = ids(outputI<0);
                        errormsg = sprintf('%d ', invalidId);
                        coder.internal.error('nav:navalgs:factorgraph:MismatchedNodeTypeForNodeStateWithID', type, errormsg);
                    else
                        coder.internal.error('nav:navalgs:factorgraph:MismatchedNodeTypeForNodeState');
                    end
                else
                    output = reshape(outputI, [], numel(ids))';
                    % The C++ layer returns the quaternion angle as the last
                    % element. Put the quaternion angle first to match the
                    % MATLAB format.
                    if (strcmp(obj.GraphInternal.getNodeType(ids(1)), 'POSE_SE3') || strcmp(obj.GraphInternal.getNodeType(ids(1)), 'TRANSFORM_SE3')) ...
                            && (size(output,2) == 7)
                        output = [output(:,1:3), output(:,7), output(:,4:6)];
                    elseif strcmp(obj.GraphInternal.getNodeType(ids(1)), 'POSE_SE3_SCALE')
                        output = exp(output(:,1));
                    end
                end
            else
                % set
                validateattributes(states, 'numeric', ...
                    {'2d', 'nrows', numel(ids), 'real', 'nonnan', 'finite','nonempty'}, 'factorGraph/nodeState', 'state');
                output = states;
                % The C++ layer stores the quaternion angle as the last
                % element. Put the quaternion angle last to match the C++
                % format.
                if (size(states,2) == 7) && (strcmp(obj.GraphInternal.getNodeType(ids(1)), 'POSE_SE3') || strcmp(obj.GraphInternal.getNodeType(ids(1)), 'TRANSFORM_SE3'))
                    states = states(:,[1:3,5:7,4]);
                end
                vstate = states';
                status = obj.GraphInternal.setNodeState(int32(ids), vstate(:), int32(size(states,2)));
                if status(end)==-1
                    if coder.target("MATLAB")
                        status = status(1:end-1); % remove the flag
                        % There are node IDs not in the factor graph
                        invalidId = ids(status<0);
                        errormsg = sprintf('%d ', invalidId);
                        coder.internal.error('nav:navalgs:factorgraph:NodeIDNotFoundInFactorGraphWithID', errormsg);
                    else
                        coder.internal.error('nav:navalgs:factorgraph:NodeIDNotFoundInFactorGraph');
                    end
                elseif status(end)==-2
                    status = status(1:end-1); % remove the flag
                    % There are nodes with different types
                    if coder.target("MATLAB")
                        type = obj.GraphInternal.getNodeType(ids(1));
                        invalidId = ids(status<0);
                        errormsg = sprintf('%d ', invalidId);
                        coder.internal.error('nav:navalgs:factorgraph:MismatchedNodeTypeForNodeStateWithID', type, errormsg);
                    else
                        coder.internal.error('nav:navalgs:factorgraph:MismatchedNodeTypeForNodeState');
                    end
                else
                    % Wrong state size for the given node type
                    coder.internal.errorIf(status(end) == -3, 'nav:navalgs:factorgraph:MismatchedNodeStateDimension');
                end
            end
        end

        function fixNode(obj, id, flag)

            narginchk(2,3);
            nav.algs.internal.validation.preValidateNodeIDs(id, 'factorGraph/fixNode', 'id');

            if nargin == 2
                status = obj.GraphInternal.fixNode(int32(id));
            else
                validateattributes(flag, 'logical', {'scalar'}, 'factorGraph/fixNode', 'flag');
                if flag
                    status = obj.GraphInternal.fixNode(int32(id));
                else
                    status = obj.GraphInternal.freeNode(int32(id));
                end
            end
            if status(end) == -1
                if coder.target("MATLAB")
                    status = status(1:end-1); % remove the flag
                    % There are invalid node IDs
                    invalidId = id(status<0);
                    errormsg = sprintf('%d ', invalidId);
                    coder.internal.error('nav:navalgs:factorgraph:NodeIDNotFoundInFactorGraphWithID', errormsg);
                else
                    coder.internal.error('nav:navalgs:factorgraph:NodeIDNotFoundInFactorGraph');
                end
            end 
        end

        function isFixed = isNodeFixed(obj, id)

            validateattributes(id, 'numeric', {'vector', 'integer', 'nonnegative', 'nonsparse', 'nonempty'},...
                'factorGraph/isNodeFixed', 'id');
            status = obj.GraphInternal.isNodeFixed(int32(id));
            if status(end) == -1
                if coder.target("MATLAB")
                    status = status(1:end-1); % remove the flag
                    % There are invalid node IDs
                    invalidId = id(status<0);
                    errormsg = sprintf('%d ', invalidId);
                    coder.internal.error('nav:navalgs:factorgraph:NodeIDNotFoundInFactorGraphWithID', errormsg);
                else
                    coder.internal.error('nav:navalgs:factorgraph:NodeIDNotFoundInFactorGraph');
                end
            else
                isFixed = logical(status);
            end 
        end

        function flag = hasNode(obj, id)

            nav.algs.internal.validation.preValidateNodeID(id, 'factorGraph/hasNode', 'id');
            id = double(id);
            flag = obj.GraphInternal.hasNode(id);
        end

        function type = nodeType(obj, id)

            nav.algs.internal.validation.preValidateNodeID(id, 'factorGraph/nodeType', 'id');
            id = double(id);
            t = obj.GraphInternal.getNodeType(id);
            coder.internal.errorIf(isempty(t), 'nav:navalgs:factorgraph:NodeIDNotFoundInFactorGraph');
            type = string(t);
        end

        function flag = isConnected(obj, ids)

            if nargin == 1
                flag = obj.GraphInternal.isConnected(int32(-1));
            else
                nav.algs.internal.validation.preValidateNodeIDs(ids, 'factorGraph/optimize', 'id');
                if obj.GraphInternal.isPoseNode(int32(ids))
                    % check whether all the nodes are pose nodes
                    flag = obj.GraphInternal.isConnected(int32(ids));
                else
                    coder.internal.error('nav:navalgs:factorgraph:MismatchedPoseNodeType');
                end
            end
        end

        function solnInfo = optimize(obj, varargin)

            narginchk(1,3);
            if nargin == 1
                opts = factorGraphSolverOptions;
                solnInfo = obj.GraphInternal.optimize(opts.toStruct, int32(-1));
            elseif nargin == 2
                if isa(varargin{1},'factorGraphSolverOptions')
                    opts = varargin{1};
                    solnInfo = obj.GraphInternal.optimize(opts.toStruct, int32(-1));
                elseif isa(varargin{1}, 'double') || isa(varargin{1}, 'single')
                    ids = varargin{1};
                    opts = factorGraphSolverOptions;
                    nav.algs.internal.validation.preValidateNodeIDs(ids, 'factorGraph/optimize', 'id');               
                    if obj.GraphInternal.isPoseNode(int32(ids))
                        % check whether all the nodes are pose nodes
                        solnInfo = obj.GraphInternal.optimize(opts.toStruct, int32(ids));
                    else
                        coder.internal.error('nav:navalgs:factorgraph:MismatchedPoseNodeType');
                    end
                else
                    coder.internal.error('nav:navalgs:factorgraph:MismatchedOptimizeInput');
                end
            else
                ids = varargin{1};
                opts = varargin{2};
                validateattributes(opts, {'factorGraphSolverOptions'}, {'scalar', 'nonempty'}, 'factorGraph/optimize', 'opts');
                nav.algs.internal.validation.preValidateNodeIDs(ids, 'factorGraph/optimize', 'id');
                if obj.GraphInternal.isPoseNode(int32(ids))
                    % check whether all the nodes are pose nodes
                    solnInfo = obj.GraphInternal.optimize(opts.toStruct, int32(ids));
                else
                    coder.internal.error('nav:navalgs:factorgraph:MismatchedPoseNodeType');
                end
            end
        end

        function ax = show(obj, varargin)
            %

            [axHandle,isLandmark,isOrientation,isEdge,isLegend,frameSize] = ...
                nav.algs.internal.FactorGraphVisualization.showInputParser(varargin{:});
            ax = nav.algs.internal.FactorGraphVisualization.show(obj, axHandle, ...
                isLandmark, isOrientation, isEdge, isLegend, frameSize);
        end

        function removedNodeIDs = removeFactor(obj, factorIDs)
            %

            narginchk(1,2);
            if nargin == 2
                % Check whether factor IDs are valid
                nav.algs.internal.validation.preValidateFactorIDs(factorIDs, 'factorGraph/removeFactor', 'factorID');
                output = obj.GraphInternal.removeFactor(int32(factorIDs));
                % Check whether all the nodes exist in the factor graph
                if ~isempty(output) && output(end)==-1
                    % There are factor IDs not in the factor graph
                    if coder.target("MATLAB")
                        % remove the flag
                        output = output(1:end-1);
                        invalidId = sort(factorIDs(output<0));
                        errormsg = sprintf('%d ', invalidId);
                        coder.internal.error('nav:navalgs:factorgraph:FactorIDNotFoundInFactorGraphWithID', errormsg);
                    else
                        coder.internal.error('nav:navalgs:factorgraph:FactorIDNotFoundInFactorGraph');
                    end
                else
                    % All factor IDs are valid
                    removedNodeIDs = double(output);
                end
            else
                % Allow removeFactor to accept no given IDs for future
                % extension
                removedNodeIDs = [];
            end
        end

        function [removedNodeIDs, removedFactorIDs] = removeNode(obj, nodeIDs)
            %

            nav.algs.internal.validation.preValidateNodeIDs(nodeIDs, 'factorGraph/removeNode', 'nodeID');
            output = obj.GraphInternal.removeNode(int32(nodeIDs));
            if output(end)==-1
                % There are node IDs not in the factor graph
                if coder.target("MATLAB")
                    % remove the flag
                    output = output(1:end-1);
                    invalidId = sort(nodeIDs(output<0));
                    errormsg = sprintf('%d ', invalidId);
                    coder.internal.error('nav:navalgs:factorgraph:NodeIDNotFoundInFactorGraphWithID', errormsg);
                else
                    coder.internal.error('nav:navalgs:factorgraph:NodeIDNotFoundInFactorGraph');
                end
            else
                % All node IDs are valid
                nodeSize = output(end);
                removedNodeIDs = double(output(1:nodeSize));
                removedFactorIDs = double(output(nodeSize+1:end-1));
            end
        end

        function Covariances = nodeCovariance(obj, ids)
            %

            nav.algs.internal.validation.preValidateNodeIDs(ids, 'factorGraph/nodeCovariance', 'nodeID');
            outputI = obj.GraphInternal.getNodeCovariance(int32(ids));
            if isnan(outputI(end)) && (outputI(end-1)==-1)
                % There are node IDs not in the factor graph
                if coder.target("MATLAB")
                    % remove the flag
                    outputI = outputI(1:end-2);
                    invalidId = ids(outputI<0);
                    errormsg = sprintf('%d ', invalidId);
                    coder.internal.error('nav:navalgs:factorgraph:NodeIDNotFoundInFactorGraphWithID', errormsg);
                else
                    coder.internal.error('nav:navalgs:factorgraph:NodeIDNotFoundInFactorGraph');
                end
            elseif isnan(outputI(end)) && (outputI(end-1)==-2)
                % There are nodes with different types
                type = obj.GraphInternal.getNodeType(ids(1));
                if coder.target("MATLAB")
                    % remove the flag
                    outputI = outputI(1:end-2);
                    invalidId = ids(outputI<0);
                    errormsg = sprintf('%d ', invalidId);
                    coder.internal.error('nav:navalgs:factorgraph:MismatchedNodeTypeForNodeCovarianceWithID', type, errormsg);
                else
                    coder.internal.error('nav:navalgs:factorgraph:MismatchedNodeTypeForNodeCovariance');
                end
            elseif isnan(outputI(end)) && (outputI(end-1)==-3)
                % There are nodes without estimated covariances
                if coder.target("MATLAB")
                    % remove the flag
                    outputI = outputI(1:end-2);
                    invalidId = ids(outputI<0);
                    errormsg = sprintf('%d ', invalidId);
                    coder.internal.error('nav:navalgs:factorgraph:CovarianceNotFoundWithID', errormsg);
                else
                    coder.internal.error('nav:navalgs:factorgraph:CovarianceNotFound');
                end
            else
                covarianceNum = numel(ids);
                dim = sqrt(length(outputI)/covarianceNum);
                Covariances = reshape(outputI,dim,dim,[]);
                if strcmp(obj.nodeType(ids(1)), "POSE_SE3") || strcmp(obj.nodeType(ids(1)), "TRANSFORM_SE3")
                    % POSE_SE3 and TRANSFORM_SE3 node's covariance matrix size = 7*7.
                    % The C++ layer returns the quaternion angle as the last
                    % element. Change the covariance sequence to match the
                    % MATLAB format.
                    cov_new = [Covariances(:,1:3,:), Covariances(:,7,:), Covariances(:,4:6,:)];
                    Covariances = [cov_new(1:3,:,:); cov_new(7,:,:); cov_new(4:6,:,:)];
                end
            end
        end

        function [factorID, marginalizedNodeIDs] = marginalizeFactor(obj, factorIDs)
            %

            narginchk(2,3);
            % Check whether factor IDs are valid
            nav.algs.internal.validation.preValidateFactorIDs(factorIDs, 'factorGraph/marginalizeFactor', 'factorID');
            output = obj.GraphInternal.marginalizeFactor(int32(factorIDs));
            % Check whether all the nodes exist in the factor graph
            if ~isempty(output) && output(end)==-1
                % There are factor IDs not in the factor graph
                if coder.target("MATLAB")
                    % remove the flag
                    output = output(1:end-1);
                    invalidId = sort(factorIDs(output<0));
                    errormsg = sprintf('%d ', invalidId);
                    coder.internal.error('nav:navalgs:factorgraph:FactorIDNotFoundInFactorGraphWithID', errormsg);
                else
                    coder.internal.error('nav:navalgs:factorgraph:FactorIDNotFoundInFactorGraph');
                end
            else
                % All factor IDs are valid
                output = double(output);
                if output(end) == -2
                    coder.internal.error('nav:navalgs:factorgraph:MarginalizeTheLastPoseNode');
                end
                % Check whether other fixed nodes being marginalized
                if output(end) == -3
                    if coder.target("MATLAB")
                        % remove the flag
                        invalidId = sort(output(1:end-1));
                        errormsg = sprintf('%d ', invalidId);
                        coder.internal.error('nav:navalgs:factorgraph:MarginalizeOtherFixedNode', errormsg);
                    else
                        coder.internal.error('nav:navalgs:factorgraph:MarginalizeOtherFixedNode');
                    end
                end
                factorID = output(1);
                marginalizedNodeIDs = output(2:end);
            end
        end

        function [factorID, marginalizedNodeIDs, marginalizedFactorIDs] = marginalizeNode(obj, nodeID)
            %

            nav.algs.internal.validation.preValidateNodeID(nodeID, 'factorGraph/marginalizeNode', 'nodeID');
            if ~hasNode(obj,nodeID)
                coder.internal.error('nav:navalgs:factorgraph:NodeIDNotFoundInFactorGraph');
            end
            if isNodeFixed(obj,nodeID)
                coder.internal.error('nav:navalgs:factorgraph:MarginalizeFixedNode');
            end
            if obj.GraphInternal.isPoseNode(int32(nodeID))
                % check whether all the nodes are pose nodes
                output = obj.GraphInternal.marginalizeNode(int32(nodeID));
            else
                coder.internal.error('nav:navalgs:factorgraph:ExpectedPoseNodeForMarginalization');
            end

            output = double(output);
            if output(end) == -2
                coder.internal.error('nav:navalgs:factorgraph:MarginalizeTheLastPoseNode');
            end
            % Check whether other fixed nodes being marginalized
            if output(end) == -3
                if coder.target("MATLAB")
                    % remove the flag
                    invalidId = sort(output(1:end-1));
                    errormsg = sprintf('%d ', invalidId);
                    coder.internal.error('nav:navalgs:factorgraph:MarginalizeOtherFixedNode', errormsg);
                else
                    coder.internal.error('nav:navalgs:factorgraph:MarginalizeOtherFixedNode');
                end
            end
            nodeSize = output(end);
            factorID = output(1);
            marginalizedNodeIDs = output(2:nodeSize+1);
            marginalizedFactorIDs = output(nodeSize+2:end-1);
        end

    end
end

