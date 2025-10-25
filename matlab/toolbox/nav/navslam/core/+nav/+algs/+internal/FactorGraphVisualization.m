classdef(Hidden) FactorGraphVisualization < nav.algs.internal.InternalAccess & ...
        factorGraph
%This class is for internal use only. It may be removed in the future.

%   Copyright 2023 The MathWorks, Inc.

    %FACTORGRAPHVISUALIZATION Plot factor graph
   
    properties (Constant)
        %Landmark threshold for a dense graph
        LandmarkThreshold = 100

        %Landmark size for a sparse graph
        LandmarkSparseSize = 60

        %Landmark size for a dense graph
        LandmarkDenseSize = 10

        %Landmark alpha for a dense graph
        LandmarkDenseAlpha = 0.5
    end

    methods (Static)
        function [axHandle,isLandmark,isOrientation,isEdge,isLegend,frameSize] = showInputParser(nvPairs)

            arguments
                nvPairs.Parent (1,1) {mustBeA(nvPairs.Parent, {'matlab.graphics.axis.Axes', 'matlab.graphics.GraphicsPlaceholder'})} = matlab.graphics.GraphicsPlaceholder
                nvPairs.Landmark (1,:) matlab.lang.OnOffSwitchState = 'on'
                nvPairs.Orientation (1,:) matlab.lang.OnOffSwitchState = 'off'
                nvPairs.Edge (1,:) char {mustBeMember(nvPairs.Edge, {'pose-edge', 'off'})} = 'pose-edge'
                nvPairs.Legend (1,:) matlab.lang.OnOffSwitchState = 'off'
                nvPairs.OrientationFrameSize (1,1) {mustBeNumeric, mustBePositive, mustBeReal} = 0.2
            end

            if ~coder.target('MATLAB')
                % Always throw error when calling show in generated code
                coder.internal.error('nav:navalgs:occgridcommon:GraphicsSupportCodegen','show');
            end

            axHandle = nvPairs.Parent;
            isLandmark = nvPairs.Landmark;
            isOrientation = nvPairs.Orientation;
            isEdge = nvPairs.Edge;
            isLegend = nvPairs.Legend;
            frameSize = nvPairs.OrientationFrameSize;
            
        end

        function axHandle = show(obj, axHandle, isLandmark, isOrientation, isEdge, isLegend, frameSize)
            %show Show the factor graph
            if isa(axHandle, 'matlab.graphics.GraphicsPlaceholder')
                axHandle = newplot;
                isNewPlot = 1;
            else
                isNewPlot = 0;
            end

            if obj.NumFactors  == 0
                return;
            end

            hold(axHandle, 'on');

            PoseSE2IDs = nodeIDs(obj,"NodeType","POSE_SE2");
            PoseSE3IDs = nodeIDs(obj,"NodeType","POSE_SE3");
            PointXYIDs = nodeIDs(obj,"NodeType","POINT_XY");
            PointXYZIDs = nodeIDs(obj,"NodeType","POINT_XYZ");

            % Get colors
            [~,stateSpec] = plannerLineSpec.start;
            poseColor = stateSpec.MarkerFaceColor; 
            [~,pathSpec] = plannerLineSpec.path;
            edgeColor = pathSpec.MarkerFaceColor; 
            [~,lkSpec] = plannerLineSpec.landmark;
            landmarkColor = lkSpec.MarkerFaceColor;

            [PoseSE2Handle, TwoPoseSE2EdgeHandle] = nav.algs.internal.FactorGraphVisualization.showPoseSE2(obj, ...
                axHandle, PoseSE2IDs, isOrientation, isEdge, poseColor, edgeColor, frameSize);
            [PoseSE3Handle, TwoPoseSE3EdgeHandle, IMUEdgeHandle] = nav.algs.internal.FactorGraphVisualization.showPoseSE3(obj,...
                axHandle, PoseSE3IDs, isOrientation, isEdge, poseColor, edgeColor, frameSize);

            PointXYHandle = nav.algs.internal.FactorGraphVisualization.showPointXY(obj, axHandle, PointXYIDs, landmarkColor, isLandmark);
            PointXYZHandle = nav.algs.internal.FactorGraphVisualization.showPointXYZ(obj, axHandle, PointXYZIDs, landmarkColor, isLandmark);

            if isNewPlot
                if ~isempty(PoseSE3IDs)
                    % Set 3D view angle if it is a new plot
                    view(axHandle,-30,45);
                end
            end

            nav.algs.internal.FactorGraphVisualization.showLegend(axHandle, isLegend,...
                PoseSE3Handle, PoseSE2Handle, TwoPoseSE3EdgeHandle, IMUEdgeHandle, TwoPoseSE2EdgeHandle,...
                PointXYHandle, PointXYZHandle);

            hold(axHandle, 'off');
        end

        function [PoseSE2Handle, TwoPoseSE2EdgeHandle] = showPoseSE2(obj, axHandle, poseID, isOrientation, isEdge, poseColor, edgeColor, frameSize)
            % Show SE2 pose nodes
            PoseSE2Handle = [];
            TwoPoseSE2EdgeHandle = [];
            if ~isempty(poseID)
                PoseSE2States = nodeState(obj,poseID)';

                PoseSE2Handle = findobj(axHandle,'Tag','PoseSE2');
                
                if ~isempty(PoseSE2Handle)
                    PoseSE2Handle.XData = PoseSE2States(1,:);
                    PoseSE2Handle.YData = PoseSE2States(2,:);
                else
                    PoseSE2Handle = plot(axHandle, PoseSE2States(1,:), PoseSE2States(2,:), 'o', 'MarkerSize', 4, 'Color', poseColor,...
                        'Tag', 'PoseSE2');
                end
                
                if strcmp(isOrientation, 'on')
                    % Draw orientation frames
                    posese2 = PoseSE2States';
                    % Delete existing frames
                    previousOrientation = findobj(axHandle,'Tag','PoseSE2OrientationFG');
                    delete(previousOrientation);
                    previousChildren = axHandle.Children;
                    plotTransforms(se2(posese2,"xytheta"),"Parent",axHandle,"FrameSize",frameSize);
                    currentChildren = axHandle.Children;
                    newOrientation = setdiff(currentChildren, previousChildren);
                    for i = 1:length(newOrientation)
                        newOrientation(i).Tag = 'PoseSE2OrientationFG';
                    end
                    grid(axHandle,"off")
                else
                    % Clear existing orientation frames
                    currentOrientation = findobj(axHandle,'Tag','PoseSE2OrientationFG');
                    delete(currentOrientation);
                end

                if strcmp(isEdge, 'pose-edge')
                    % Draw edges
                    % Get TwoPoseSE2 Edges. O is the index for
                    % factorTwoPoseSE2
                    edges = nav.algs.internal.FactorGraphVisualization.getEdge(obj,...
                        nav.algs.internal.FactorTypeEnum.Two_SE2_F);
                    [~, loc] = ismember(edges,poseID);
                    edgeStates = PoseSE2States(:, loc);
                    xData = edgeStates(1,:);
                    yData = edgeStates(2,:);
                    % Insert NaN between each pairs
                    numPairs = size(xData,2)/2;
                    xPairData = reshape(xData, 2, numPairs);
                    xPlotData = [xPairData; NaN(1,numPairs)];
                    xPlotData = xPlotData(:).';
                    yPairData = reshape(yData, 2, numPairs);
                    yPlotData = [yPairData; NaN(1,numPairs)];
                    yPlotData = yPlotData(:).';

                    TwoPoseSE2EdgeHandle = findobj(axHandle,'Tag','TwoPoseSE2Edge');
                    if ~isempty(TwoPoseSE2EdgeHandle)
                        TwoPoseSE2EdgeHandle.XData = xPlotData;
                        TwoPoseSE2EdgeHandle.YData = yPlotData;
                    else
                        TwoPoseSE2EdgeHandle = plot(axHandle, xPlotData, yPlotData, '-', 'color', edgeColor, ...
                            'Tag', 'TwoPoseSE2Edge');
                    end
                else
                    if ~isempty(TwoPoseSE2EdgeHandle)
                        TwoPoseSE2EdgeHandle.XData = [];
                        TwoPoseSE2EdgeHandle.YData = [];
                    end
                end
            end
        end

        function [PoseSE3Handle, TwoPoseSE3EdgeHandle, IMUEdgeHandle] = showPoseSE3(obj, axHandle, poseID, isOrientation, isEdge, poseColor, edgeColor, frameSize)
            % Show SE3 pose nodes
            PoseSE3Handle = [];
            TwoPoseSE3EdgeHandle = [];
            IMUEdgeHandle = [];
            if ~isempty(poseID)
                PoseSE3States = nodeState(obj,poseID);

                PoseSE3Handle = findobj(axHandle,'Tag','PoseSE3');

                if ~isempty(PoseSE3Handle)
                    PoseSE3Handle.XData = PoseSE3States(:,1);
                    PoseSE3Handle.YData = PoseSE3States(:,2);
                    PoseSE3Handle.ZData = PoseSE3States(:,3);
                else
                    PoseSE3Handle = plot3(axHandle, PoseSE3States(:,1), PoseSE3States(:,2), PoseSE3States(:,3),...
                        'o', 'MarkerSize', 4, 'Color', poseColor, 'Tag', 'PoseSE3');
                end

                if strcmp(isOrientation, 'on')
                    % Draw frames
                    trans = PoseSE3States(:, 1:3);
                    rot = PoseSE3States(:, 4:7);
                    % Delete existing frames
                    previousOrientation = findobj(axHandle,'Tag','PoseSE3OrientationFG');
                    delete(previousOrientation);
                    previousChildren = axHandle.Children;
                    plotTransforms(trans,rot,"Parent",axHandle,"FrameSize",frameSize);
                    currentChildren = axHandle.Children;
                    newOrientation = setdiff(currentChildren, previousChildren);
                    for i = 1:length(newOrientation)
                        newOrientation(i).Tag = 'PoseSE3OrientationFG';
                    end
                else
                    % Clear existing orientation frames
                    currentOrientation = findobj(axHandle,'Tag','PoseSE3OrientationFG');
                    delete(currentOrientation);
                end

                if strcmp(isEdge, 'pose-edge')
                    % Draw edges
                    PoseSE3States = PoseSE3States';
                    % Get TwoPoseSE3 Edges. 1 is the index for
                    % factorTwoPoseSE3
                    PoseEdges = nav.algs.internal.FactorGraphVisualization.getEdge(obj,...
                        nav.algs.internal.FactorTypeEnum.Two_SE3_F);
                    [~, loc] = ismember(PoseEdges,poseID);
                    PoseEdgeStates = PoseSE3States(:, loc);
                    xData = PoseEdgeStates(1,:);
                    yData = PoseEdgeStates(2,:);
                    zData = PoseEdgeStates(3,:);

                    numPairs = size(xData,2)/2;
                    xPairData = reshape(xData, 2, numPairs);
                    xPlotData = [xPairData; NaN(1,numPairs)];
                    xPlotData = xPlotData(:).';
                    yPairData = reshape(yData, 2, numPairs);
                    yPlotData = [yPairData; NaN(1,numPairs)];
                    yPlotData = yPlotData(:).';
                    zPairData = reshape(zData, 2, numPairs);
                    zPlotData = [zPairData; NaN(1,numPairs)];
                    zPlotData = zPlotData(:).';

                    TwoPoseSE3EdgeHandle = findobj(axHandle,'Tag','TwoPoseSE3Edge');
                    if ~isempty(TwoPoseSE3EdgeHandle)
                        TwoPoseSE3EdgeHandle.XData = xPlotData;
                        TwoPoseSE3EdgeHandle.YData = yPlotData;
                        TwoPoseSE3EdgeHandle.ZData = zPlotData;
                    else
                        TwoPoseSE3EdgeHandle = plot3(axHandle, xPlotData, yPlotData, zPlotData, '-', 'color', edgeColor, ...
                            'Tag', 'TwoPoseSE3Edge');
                    end

                    % Get IMU Edges. 4 is the index for factorIMU
                    IMUEdges = nav.algs.internal.FactorGraphVisualization.getEdge(obj,...
                        nav.algs.internal.FactorTypeEnum.IMU_F);
                    % Get PoseSE3 nodes only
                    IMUEdges = IMUEdges(1:3:end);
                    [~, loc] = ismember(IMUEdges,poseID);
                    IMUEdgeStates = PoseSE3States(:, loc);
                    xData = IMUEdgeStates(1,:);
                    yData = IMUEdgeStates(2,:);
                    zData = IMUEdgeStates(3,:);

                    numPairs = size(xData,2)/2;
                    xPairData = reshape(xData, 2, numPairs);
                    xPlotData = [xPairData; NaN(1,numPairs)];
                    xPlotData = xPlotData(:).';
                    yPairData = reshape(yData, 2, numPairs);
                    yPlotData = [yPairData; NaN(1,numPairs)];
                    yPlotData = yPlotData(:).';
                    zPairData = reshape(zData, 2, numPairs);
                    zPlotData = [zPairData; NaN(1,numPairs)];
                    zPlotData = zPlotData(:).';

                    IMUEdgeHandle = findobj(axHandle,'Tag','IMUEdge');
                    if ~isempty(IMUEdgeHandle)
                        IMUEdgeHandle.XData = xPlotData;
                        IMUEdgeHandle.YData = yPlotData;
                        IMUEdgeHandle.ZData = zPlotData;
                    else
                        IMUEdgeHandle = plot3(axHandle, xPlotData, yPlotData, zPlotData, '-', 'color', edgeColor, ...
                            'Tag', 'IMUEdge');
                    end
                else
                    TwoPoseSE3EdgeHandle = findobj(axHandle,'Tag','TwoPoseSE3Edge');
                    if ~isempty(TwoPoseSE3EdgeHandle)
                        TwoPoseSE3EdgeHandle.XData = [];
                        TwoPoseSE3EdgeHandle.YData = [];
                        TwoPoseSE3EdgeHandle.ZData = [];
                    end
                    IMUEdgeHandle = findobj(axHandle,'Tag','IMUEdge');
                    if ~isempty(IMUEdgeHandle)
                        IMUEdgeHandle.XData = [];
                        IMUEdgeHandle.YData = [];
                        IMUEdgeHandle.ZData = [];
                    end
                end
            end
        end

        function PointXYHandle = showPointXY(obj, axHandle, pointID, landmarkColor, isLandmark)
            % Show XY point nodes
            PointXYHandle = [];
            if ~isempty(pointID)
                PointXYStates = nodeState(obj,pointID)';
                PointXYHandle = findobj(axHandle,'Tag','PointXY');

                if ~isempty(PointXYHandle)
                    % PointXYHandle exists
                    if strcmp(isLandmark, 'on')
                        % Update data
                        PointXYHandle.XData = PointXYStates(1,:);
                        PointXYHandle.YData = PointXYStates(2,:);
                    else
                        % Clear data
                        PointXYHandle.XData = [];
                        PointXYHandle.YData = [];
                    end
                else
                    if strcmp(isLandmark, 'on')
                        if size(PointXYStates,2)<nav.algs.internal.FactorGraphVisualization.LandmarkThreshold
                            % Sparse graph
                            PointXYHandle = scatter(axHandle, PointXYStates(1,:), PointXYStates(2,:), ...
                                'SizeData', nav.algs.internal.FactorGraphVisualization.LandmarkSparseSize, ...
                                'Marker', '.', 'MarkerEdgeColor', landmarkColor, 'MarkerFaceColor', landmarkColor, ...
                                'Tag', 'PointXY');
                        else
                            % Dense graph
                            PointXYHandle = scatter(axHandle, PointXYStates(1,:), PointXYStates(2,:), ...
                                'SizeData', nav.algs.internal.FactorGraphVisualization.LandmarkDenseSize, ...
                                'Marker', '.', 'MarkerEdgeColor', landmarkColor, 'MarkerFaceColor', landmarkColor, ...
                                'MarkerFaceAlpha', nav.algs.internal.FactorGraphVisualization.LandmarkDenseAlpha, ...
                                'MarkerEdgeAlpha', nav.algs.internal.FactorGraphVisualization.LandmarkDenseAlpha, ...
                                'Tag', 'PointXY');
                        end
                    end
                end
            end
        end

        function PointXYZHandle = showPointXYZ(obj, axHandle, pointID, landmarkColor, isLandmark)
            % Show XY point nodes
            PointXYZHandle = [];
            if ~isempty(pointID)
                PointXYZStates = nodeState(obj,pointID)';
                PointXYZHandle = findobj(axHandle,'Tag','PointXYZ');

                if ~isempty(PointXYZHandle)
                    if strcmp(isLandmark, 'on')
                        PointXYZHandle.XData = PointXYZStates(1,:);
                        PointXYZHandle.YData = PointXYZStates(2,:);
                        PointXYZHandle.ZData = PointXYZStates(3,:);
                    else
                        PointXYZHandle.XData = [];
                        PointXYZHandle.YData = [];
                        PointXYZHandle.ZData = [];
                    end
                else
                    if strcmp(isLandmark, 'on')
                        if size(PointXYZStates,2)<nav.algs.internal.FactorGraphVisualization.LandmarkThreshold
                            % Sparse graph
                            PointXYZHandle = scatter3(axHandle, PointXYZStates(1,:), PointXYZStates(2,:), PointXYZStates(3,:), ...
                                'SizeData', nav.algs.internal.FactorGraphVisualization.LandmarkSparseSize, ...
                                'Marker', '.', 'MarkerEdgeColor', landmarkColor, 'MarkerFaceColor', landmarkColor,...
                                'Tag', 'PointXYZ');
                        else
                            % Dense graph
                            PointXYZHandle = scatter3(axHandle, PointXYZStates(1,:), PointXYZStates(2,:), PointXYZStates(3,:), ...
                                'SizeData', nav.algs.internal.FactorGraphVisualization.LandmarkDenseSize, ...
                                'Marker', '.', 'MarkerEdgeColor', landmarkColor, 'MarkerFaceColor', landmarkColor, ...
                                'MarkerFaceAlpha', nav.algs.internal.FactorGraphVisualization.LandmarkDenseAlpha, ...
                                'MarkerEdgeAlpha', nav.algs.internal.FactorGraphVisualization.LandmarkDenseAlpha, ...
                                'Tag', 'PointXYZ');
                        end
                    end
                end
            end
        end

        function edgeIDs = getEdge(obj,edgeType)
            edgeIDs = obj.GraphInternal.getEdge(double(edgeType));
        end

        function showLegend(axHandle, isLegend,PoseSE3Handle, PoseSE2Handle, TwoPoseSE3EdgeHandle,...
                IMUEdgeHandle, TwoPoseSE2EdgeHandle, PointXYHandle, PointXYZHandle)
            if strcmp(isLegend, 'on')
                % Since we are not differentiate different types of nodes
                % or edges for now, we will only show the legend once for
                % each group (pose node, landmark, edge).
                HandleSet = [];
                NameSet = {};
                if ~isempty(PoseSE3Handle)&&~isempty(PoseSE3Handle.XData)
                    HandleSet = [HandleSet PoseSE3Handle];
                    NameSet{end+1} = 'Pose Node';
                elseif ~isempty(PoseSE2Handle)&&~isempty(PoseSE2Handle.XData)
                    HandleSet = [HandleSet PoseSE2Handle];
                    NameSet{end+1} = 'Pose Node';
                end
                if ~isempty(TwoPoseSE3EdgeHandle)&&~isempty(TwoPoseSE3EdgeHandle.XData)
                    HandleSet = [HandleSet TwoPoseSE3EdgeHandle];
                    NameSet{end+1} = 'Pose Edge';
                elseif ~isempty(IMUEdgeHandle)&&~isempty(IMUEdgeHandle.XData)
                    HandleSet = [HandleSet IMUEdgeHandle];
                    NameSet{end+1} = 'Pose Edge';
                elseif ~isempty(TwoPoseSE2EdgeHandle)&&~isempty(TwoPoseSE2EdgeHandle.XData)
                    HandleSet = [HandleSet TwoPoseSE2EdgeHandle];
                    NameSet{end+1} = 'Pose Edge';
                end
                if ~isempty(PointXYHandle)&&~isempty(PointXYHandle.XData)
                    HandleSet = [HandleSet PointXYHandle];
                    NameSet{end+1} = 'Landmark Node';
                elseif ~isempty(PointXYZHandle)&&~isempty(PointXYZHandle.XData)
                    HandleSet = [HandleSet PointXYZHandle];
                    NameSet{end+1} = 'Landmark Node';
                end
                legend(axHandle,HandleSet,NameSet)
            end
        end
    end
    
end

