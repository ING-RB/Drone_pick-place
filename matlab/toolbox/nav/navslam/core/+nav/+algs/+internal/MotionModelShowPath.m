classdef MotionModelShowPath
%This class is for internal use only. It may be removed in the future.

%MotionModelShowPath Class containing static utility methods for
%   dealing with plot the path. This complete code has been used by
%   show methods of dubinsPathSegment &
%   reedsSheppPathSegment.

% Copyright 2018-2023 The MathWorks, Inc.

    methods

        function h1 = pathPlot(~, states, axHandle)
        %pathPlot Visualize the forward path

            h1 = plot(axHandle, states(:,1), states(:,2), plannerLineSpec.path{:},'Tag','pathPlotFwd');
        end

        function h1 = reversePathPlot(~, states, axHandle)
        %pathPlot Visualize the reverse path

            h1 = plot(axHandle, states(:,1), states(:,2),plannerLineSpec.reversePath{:},'Tag','pathPlotBck');
        end

        function [h1, h2] = startAndGoalPlot(~, startPose, goalPose, inputparam)
        %startAndGoalPlot Visualize the start and/or goal

            % Disable start position.
            if ~ismember('start',inputparam.positions)
                startPose    = nan(1,3);
            end

            % Disable goal position.
            if ~ismember('goal',inputparam.positions)
                goalPose    = nan(1,3);
            end
           
            axHandle = inputparam.axHandle;
            % Plot Start
            [~,startSpec] = plannerLineSpec.start('MarkerSize',80);
            h1 = scatter(axHandle, startPose(1), startPose(2),startSpec.MarkerSize, 'Marker', startSpec.Marker, 'MarkerFaceColor', ...
                    startSpec.MarkerFaceColor, 'MarkerEdgeColor', startSpec.MarkerEdgeColor, ...
                    'Tag','startEndPoints');

            % Plot Goal
            [~,goalSpec] = plannerLineSpec.goal('MarkerSize',120);
            h2 = scatter(axHandle, goalPose(1),goalPose(2),goalSpec.MarkerSize, 'Marker', goalSpec.Marker, 'MarkerFaceColor', ...
                    goalSpec.MarkerFaceColor, 'MarkerEdgeColor', goalSpec.MarkerEdgeColor, ...
                    'Tag','goalEndPoints');
        end

        function h1 = headingPlot(obj, poses, inputparam)
        %headingPlot Visualize the heading at start, goal or transitions

            if ~ismember('start',inputparam.headings)
                poses(1,:) = nan;
            end

            if ~ismember('transitions',inputparam.headings)
                poses(2:end-1,:) = nan;
            end

            if ~ismember('goal',inputparam.headings)
                poses(end,:) = nan;
            end

            headingLength=inputparam.headingLength;

            % Remove NaNs
            poses = poses(~any(isnan(poses),2),:);

            h1 = obj.drawHeading(inputparam.axHandle, poses(:,1:2),...
                                 robotics.internal.wrapTo2Pi(poses(:,3))',headingLength);
        end
    end

    methods (Access = private)

        function h1 = drawHeading(obj, axHandle, p1, theta,headingLength)
        %drawHeading draw the headingLines

            % legend handle for arrow
            h1 = plot(axHandle, nan, nan, plannerLineSpec.heading{:});

            if isnan(theta)
                return;
            end

            % X & Y data
            X = p1(:,1);
            Y = p1(:,2);

            %check for previous heading lines
            headingLines=findall(axHandle,'Tag','headingLine');
            for i=1:numel(headingLines)
                position=headingLines(i).UserData;
                vertices = nav.algs.internal.MotionModelShowPath.getHeadingLineCoordinates(axHandle,position(1),position(2),position(3),headingLength);
                headingLines(i).XData=vertices(1,:);
                headingLines(i).YData=vertices(2,:);
            end

            for i = 1:numel(X)
                headingLinePlot(obj, axHandle, [X(i) Y(i), theta(i)],headingLength);
            end
        end

        function headingLinePlot(~, axHandle, position,headingLength)
        %headingLinePlot Plots a 'o' marker at the given position
        %with a line segment plotted in the direction of heading
        
            % Get figure handle
            figHandle = get(axHandle,'Parent');

            X=position(1);
            Y=position(2);
            theta=position(3);

            %getting heading  coordinates
            vertices = nav.algs.internal.MotionModelShowPath.getHeadingLineCoordinates(axHandle,X,Y,theta,headingLength);

            % Plot Heading marker
            [~,stateSpec] = plannerLineSpec.heading;
            scatter(X, Y, 'Marker',stateSpec.Marker,'MarkerFaceColor',stateSpec.MarkerFaceColor, ...
               'MarkerEdgeColor',stateSpec.MarkerEdgeColor,'Tag','headingPosition');

            % Plotting orientation of poses
            plot(vertices(1,:), vertices(2,:),plannerLineSpec.heading{:}, ...
               'Tag','headingLine','UserData',[X Y theta]);

            % Block the 3D rotation
            rotate = rotate3d(figHandle);
            rotate.setAllowAxesRotate(axHandle,false);
        end
    end

    methods ( Static )

        function vertices = getHeadingLineCoordinates(ax,X,Y,theta,headingLength)
        %return coordinates of the heading Line
            if headingLength~=0
                %if the headingLength is not set
                %rotation matrix
                R = [cos(theta) -sin(theta); sin(theta) cos(theta)];

                %direction of the arrow
                x1=linspace(0,headingLength,100);
                y1=zeros(numel(x1),1);
                V=[x1' y1];

                %vertices after rotation
                V_rot=R*V';
                vertices=[V_rot(1,:); V_rot(2,:)];
                vertices(1,:)=vertices(1,:)+X;
                vertices(2,:)=vertices(2,:)+Y;
            else
                %return coordinates of the heading Line
                figHandle=get(ax,'Parent');

                pixelInfo = nav.algs.internal.retrieveAdjustedPlotBoxPosition(ax);

                pix=get(figHandle,'Position');
                %get pixel width
                pixWidth=pixelInfo(3)*pix(3);
                %get pixel height
                pixHeight=pixelInfo(4)*pix(4);
                %get axis limits
                limits=axis(ax);
                %get polygon coordinates
                %calculate 1 pixel length in x axis;
                px=(limits(2)-limits(1))/pixWidth;
                py=(limits(4)-limits(3))/pixHeight;
                %calculate the rotation angle in pixel space

                scaledTheta=atan(tan(theta)*px/py);
                %rotation matrix
                R = [cos(scaledTheta) -sin(scaledTheta); sin(scaledTheta) cos(scaledTheta)];

                %direction of the arrow
                if cos(theta)>=0
                    x1=0:0.1:15;
                    y1=zeros(numel(x1),1);
                    V=[x1' y1];
                else
                    x1=0:-0.1:-15;
                    y1=zeros(numel(x1),1);
                    V=[x1' y1];
                end

                %vertices after rotation
                V_rot=R*V';
                vertices=[V_rot(1,:)*px; V_rot(2,:)*py];
                vertices(1,:)=vertices(1,:)+X;
                vertices(2,:)=vertices(2,:)+Y;
            end
        end
    end
end
