close all
clear all
clc

%% Map definition
res = 8;
omap = occupancyMap3D(res);
omap.FreeThreshold = 0.2;
omap.OccupiedThreshold = 0.65;

% Variables initialising
width = zeros(1,19);
length = zeros(1,19);
height = zeros(1,19);
xPosition = zeros(1,19);
yPosition = zeros(1,19);
zPosition = zeros(1,19);

% Walls
width(1) = 0.5;     length(1) = 16;     height(1) = 6;  xPosition(1) = 4;       yPosition(1) = 10;      zPosition(1) = 3;
width(2) = 0.5;     length(2) = 11;     height(2) = 6;  xPosition(2) = 4;       yPosition(2) = -7.5;    zPosition(2) = 3;
width(3) = 19;      length(3) = 0.5;    height(3) = 6;  xPosition(3) = 13.75;   yPosition(3) = -12.75;  zPosition(3) = 3;
width(4) = 19;      length(4) = 0.5;    height(4) = 6;  xPosition(4) = 13.75;   yPosition(4) = 17.75;   zPosition(4) = 3;
width(5) = 0.5;     length(5) = 31;     height(5) = 6;  xPosition(5) = 23;      yPosition(5) = 2.5;     zPosition(5) = 3;
width(6) = 0.5;     length(6) = 7;      height(6) = 6;  xPosition(6) = 10;      yPosition(6) = -9;      zPosition(6) = 3;
width(7) = 8;       length(7) = 0.5;    height(7) = 6;  xPosition(7) = 14.25;   yPosition(7) = -5.75;   zPosition(7) = 3;
width(8) = 14.5;    length(8) = 0.5;    height(8) = 6;  xPosition(8) = 15.5;    yPosition(8) = 7;       zPosition(8) = 3;
width(9) = 0.5;     length(9) = 5;      height(9) = 6;  xPosition(9) = 8.5;     yPosition(9) = 9.75;    zPosition(9) = 3;
width(10) = 0.5;    length(10) = 5;     height(10) = 6; xPosition(10) = 15;     yPosition(10) = 15;     zPosition(10) = 3;

% Columns
width(11) = 0.6;    length(11) = 0.6;     height(11) = 6; xPosition(11) = 8;    yPosition(11) = 4.5;    zPosition(11) = 3;
width(12) = 0.6;    length(12) = 0.6;     height(12) = 6; xPosition(12) = 8;    yPosition(12) = 0.5;    zPosition(12) = 3;
width(13) = 0.6;    length(13) = 0.6;     height(13) = 6; xPosition(13) = 8;    yPosition(13) = -3.5;   zPosition(13) = 3;
width(14) = 0.6;    length(14) = 0.6;     height(14) = 6; xPosition(14) = 12;   yPosition(14) = 4.5;    zPosition(14) = 3;
width(15) = 0.6;    length(15) = 0.6;     height(15) = 6; xPosition(15) = 12;   yPosition(15) = 0.5;    zPosition(15) = 3;
width(16) = 0.6;    length(16) = 0.6;     height(16) = 6; xPosition(16) = 12;   yPosition(16) = -3.5;   zPosition(16) = 3;
width(17) = 0.6;    length(17) = 0.6;     height(17) = 6; xPosition(17) = 16;   yPosition(17) = 4.5;    zPosition(17) = 3;
width(18) = 0.6;    length(18) = 0.6;     height(18) = 6; xPosition(18) = 16;   yPosition(18) = 0.5;    zPosition(18) = 3;
width(19) = 0.6;    length(19) = 0.6;     height(19) = 6; xPosition(19) = 16;   yPosition(19) = -3.5;   zPosition(19) = 3;


% Insert walls into 3D occupancy map
for i = 1:19
    w = width(i); l = length(i); h = height(i);
    x = xPosition(i); y = yPosition(i); z = zPosition(i);

    [xObs, yObs, zObs] = meshgrid( ...
        x - w/2 - 1/res : 1/res : x + w/2 + 1/res, ...
        y - l/2 - 1/res : 1/res : y + l/2 + 1/res, ...
        z - h/2 - 1/res : 1/res : z + h/2 + 1/res);

    xyzObs = [xObs(:) yObs(:) zObs(:)];

    setOccupancy(omap, xyzObs, 1);
end

% Inflate the 3D occupancy WITH 1/resolution to get the real map
inflate(omap, 1/res);

% Visualize map
figure("Name","3D Occupancy Map");
show(omap);
axis equal;
view([0 90]);

% Inflate the 3D occupancy to inflate the real map WITH 40 cm
omap_inflated=omap;
inflate(omap_inflated, 0.4);

% Visualize inflated map
figure("Name","Inflated 3D Occupancy Map");
show(omap_inflated);
axis equal;
view([0 90]);



