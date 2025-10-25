%MAGCAL - Magnetometer calibration coefficients 
%
%   [A,B,EXPMFS] = MAGCAL(D) returns the coefficients needed to correct
%   uncalibrated magnetometer data D. Specify D as an N-by-3 matrix of 
%   [X Y Z] measurements. A is a 3-by-3 matrix which corrects soft-iron
%   effects. B is a 1-by-3 vector which corrects hard-iron effects. EXPMFS
%   is the scalar expected magnetic field strength.
%
%   [A,B,EXPMFS] = MAGCAL(..., FITKIND) constrains A to have the form in
%   FITKIND.  Valid choices for FITKIND are:
%
%     'eye'   - constrains A to be eye(3)
%     'diag'  - constrains A to be diagonal
%     'sym'   - constrains A to be symmetric
%     'auto'  - (default) chooses A among 'eye', 'diag', and 'sym' to give
%               the best fit.
%
%   The data D can be corrected with the 3-by-3 matrix A and the 3-by-1
%   vector B using the equation
%     F = (D-B)*A
%   to produce the N-by-3 matrix F of corrected magnetometer data. The
%   corrected magnetometer data lies on a sphere of radius EXPMFS.
%
%   Example: Correct Data Lying on an Ellipsoid
%       % Generate magnetometer data that lies on an ellipsoid. 
%       c = [-50; 20; 100]; % ellipsoid center
%       r = [30; 20; 50]; % semiaxis radii
%       [x,y,z] = ellipsoid(c(1),c(2),c(3),r(1),r(2),r(3),20);
%       d = [x(:),y(:),z(:)];
%
%       % Correct the magnetometer data so that it lies on a sphere.
%       [A,b,magB] = magcal(d); % calibration coefficients
%       dc = (d-b)*A; % correct data to a sphere
%
%       % Visualize the uncalibrated and calibrated magnetometer data.
%       plot3(x(:),y(:),z(:), 'LineStyle', 'none', 'Marker', 'X', ...
%           'MarkerSize', 8);
%       hold(gca, 'on');
%       grid(gca, 'on');
%       plot3(dc(:,1),dc(:,2),dc(:,3), 'LineStyle', 'none', 'Marker', ...
%           'o', 'MarkerSize', 8, 'MarkerFaceColor', 'r'); 
%       axis equal
%       xlabel('uT');
%       ylabel('uT');
%       xlabel('uT');
%       legend('Uncalibrated Samples', 'Calibrated Samples', ...
%           'Location', 'southoutside');
%       title("Uncalibrated vs Calibrated" + newline + ...
%           "Magnetometer Measurements");
%       hold(gca, 'off');
%
%   See also IMUSENSOR, ALLANVAR, ELLIPSOID

 
% Copyright 2018-2022 The MathWorks, Inc.

