close all
clear all
clc

load("map_inflated.mat");
omap_inflated.FreeThreshold = omap_inflated.OccupiedThreshold;

ss = stateSpaceSE3([0 30; -10 20; 1 5;-1 1;0 0;0 0;-1 1]);

startPose1 = [0 0 0 1 0 0 0];
goalPose1 = [15 -9 2 0 0 0 1];

startPose2 = [15 -9 2 0 0 0 1];
goalPose2 = [21 11 2 1 0 0 0];
 
 [ss,path1] = path_planning(ss, omap_inflated, startPose1, goalPose1);
 [ss,path2] = path_planning(ss, omap_inflated, startPose2, goalPose2);


disp('preparo i file...')
if exist('path1', 'var') && ~isempty(path1)
    crea_file(path1, 'myFile1.txt')
    disp('file creato');
end
if exist('path2', 'var') && ~isempty(path2)
    crea_file(path2, 'myFile2.txt')
    disp('file creato');
end






function [ss,path] = path_planning(ss, omap_inflated, startPose, goalPose)

    sv = validatorOccupancyMap3D(ss, ...
         Map = omap_inflated, ...
         ValidationDistance = 0.1);
    
    planner = plannerRRT(ss,sv, ...
              MaxConnectionDistance = 50, ...
              MaxIterations = 10000, ...
              GoalReachedFcn = @(~,s,g)(norm(s(1:3)-g(1:3))<1), ...
              GoalBias = 0.1);
    
    [pthObj,solnInfo] = plan(planner,startPose,goalPose);
    
    if (solnInfo.IsPathFound)
        
        figure()
        show(omap_inflated)
        axis equal
        view([0 90])
        hold on
        % Start state
        scatter3(startPose(1,1),startPose(1,2),startPose(1,3),"g","filled")
        % Goal state
        scatter3(goalPose(1,1),goalPose(1,2),goalPose(1,3),"r","filled")
        % Path
        plot3(pthObj.States(:,1),pthObj.States(:,2),pthObj.States(:,3), ...
              "r-",LineWidth=2)
        hold off
        
        shortenPathObj = shortenpath(pthObj, sv);
        interpolatedPathObj = copy(shortenPathObj);
        interpolate(interpolatedPathObj,1000);
        waypoints = interpolatedPathObj.States;
    
    
        figure()
        show(omap_inflated)
        axis equal
        view([0 90])
        hold on
        % Start state
        scatter3(startPose(1,1),startPose(1,2),startPose(1,3),"g","filled")
        % Goal state
        scatter3(goalPose(1,1),goalPose(1,2),goalPose(1,3),"r","filled")
        % Path
        plot3(shortenPathObj.States(:,1),shortenPathObj.States(:,2),shortenPathObj.States(:,3), ...
              "r-",LineWidth=2)
        hold off
        
        %calcolo a mano lo yaw
        versore_asse_x=[1 0];
        yaw=zeros(1000,1);
        for i=1:999
           w= waypoints(i+1,1:2) - waypoints(i,1:2);
           yaw(i)= atan2(det([versore_asse_x;w]), dot(versore_asse_x, w));
        end
        yaw(1000)=yaw(999);

        path=zeros(1000,4);
        path(:,1:3) = waypoints(:,1:3);
        path(:,4) = yaw;
    end

end


function crea_file(path, fileName)
    path(:,4) = path(:,4) - pi/2;
    path(:,4) = wrapToPi(path(:,4));
    save(fileName, 'path', '-ASCII');
end
