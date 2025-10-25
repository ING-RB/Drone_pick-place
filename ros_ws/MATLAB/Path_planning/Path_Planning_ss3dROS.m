close all
clear all
clc


% PARAMETER
global plot_paths;
plot_paths = false;

% Global variables
global ss;
global omap_inflated;
global pub;


disp('Initialising path planning....');
load("map_inflated.mat");

omap_inflated.FreeThreshold = omap_inflated.OccupiedThreshold;

ss = stateSpaceSE3([0 30; -10 20; 1 5;-1 1;0 0;0 0;-1 1]);

node = ros2node("/matlab_node");

sub = ros2subscriber(node, "/Matlab_path_request", "std_msgs/Float32MultiArray", @callback_path_request);

pub = ros2publisher(node, "/Matlab_path_reply", "std_msgs/Float32MultiArray");
disp('Ready to receive path requests');

%used to keep the service active
while(true)
    pause(1);
end

function callback_path_request(msg)
    global ss;
    global omap_inflated;
    global pub;
            
    disp("Received message:");
    disp(msg.data);
    M = double(reshape(msg.data, 7, length(msg.data)/7).')
    
    answer = ros2message(pub); % get the message type (std_msgs/Float32MultiArray)

    path_reshaped = [];

    for i = 1:2:length(M(:,1))
        ss_tmp=ss;
        disp ('Computing path from:');
        disp(M(i,:));
        disp ('To:');
        disp(M(i+1,:));
        [ss,path] = path_planning(ss_tmp, omap_inflated, M(i,:), M(i+1,:));

        path_reshaped=[path_reshaped, reshape(path.', 1,4000)]; %concatenate waypoints in one row
        disp ('Done');

    end
    answer.data = single(path_reshaped);  % it must be single (float32)
    send(pub, answer);
    disp('Path sent');

end


function [ss,path] = path_planning(ss, omap_inflated, startPose, goalPose)
    global plot_paths;
    
    % Initialize validator
    sv = validatorOccupancyMap3D(ss, ...
         Map = omap_inflated, ...
         ValidationDistance = 0.1);
    
    % Initialize RRT planner
    planner = plannerRRT(ss,sv, ...
              MaxConnectionDistance = 50, ...
              MaxIterations = 10000000, ...
              GoalReachedFcn = @(~,s,g)(norm(s(1:3)-g(1:3))<0.1), ...
              GoalBias = 0.1);
    
    % Search path
    [pthObj,solnInfo] = plan(planner,startPose,goalPose);
    
    % If path is found try to make it shorter
    if (solnInfo.IsPathFound)

        shortenPathObj = shortenpath(pthObj, sv);
        interpolatedPathObj = copy(shortenPathObj);
        interpolate(interpolatedPathObj,1000);
        waypoints = interpolatedPathObj.States;

        if (plot_paths)
            figure()
            show(omap_inflated)
            axis equal
            view([0 90])
            hold on
            % Draw the start pose
            scatter3(startPose(1,1),startPose(1,2),startPose(1,3),"g","filled")
            % Draw the goal pose
            scatter3(goalPose(1,1),goalPose(1,2),goalPose(1,3),"r","filled")
            % Draw the path
            plot3(pthObj.States(:,1),pthObj.States(:,2),pthObj.States(:,3), "r-",LineWidth=2)
            hold off
            
            figure()
            show(omap_inflated)
            axis equal
            view([0 90])
            hold on
            % Draw the start pose
            scatter3(startPose(1,1),startPose(1,2),startPose(1,3),"g","filled")
            % Draw the goal pose
            scatter3(goalPose(1,1),goalPose(1,2),goalPose(1,3),"r","filled")
            % Draw the path
            plot3(shortenPathObj.States(:,1),shortenPathObj.States(:,2),shortenPathObj.States(:,3), "r-",LineWidth=2)
            hold off
        end
        
        % Compute manually the yaw so that the front of the drone is
        % alligned with the path
        x_axis_unit_vector=[1 0];
        yaw=zeros(1000,1);
        for i=1:999
           w= waypoints(i+1,1:2) - waypoints(i,1:2);
           yaw(i)= atan2(det([x_axis_unit_vector;w]), dot(x_axis_unit_vector, w));
        end
        yaw(1000)=yaw(999);
        
        path=zeros(1000,4);
        path(:,1:3) = waypoints(:,1:3);
        path(:,4) = yaw;
        
        % Add -pi/2 to each yaw element of the path because the front of
        % the drone is not alligned with the x-axis
        path(:,4) = path(:,4) - pi/2;
        path(:,4) = wrapToPi(path(:,4));
    end
end