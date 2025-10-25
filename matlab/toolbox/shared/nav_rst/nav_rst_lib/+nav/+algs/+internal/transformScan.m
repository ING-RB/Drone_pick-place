function transScan = transformScan(scan, pose)
%This function is for internal use only. It may be removed in the future.

%TRANSFORMSCAN Transform laser scan based on relative pose
%   This function is internal (with no validation) and is called by
%   transformScan and lidarScan/transformScan.
%
%   See also transformScan, lidarScan/transformScan.

%   Copyright 2017-2019 The MathWorks, Inc.

%#codegen

% Create rotation matrix
    theta = pose(3);
    rotm = [cos(theta) -sin(theta);
            sin(theta) cos(theta)];

    % Create 2D homogeneous transform
    trvec = [pose(1); pose(2)];
    tform = [rotm, trvec
             0 0 1];

    % Create homogeneous points
    if scan.Count > 0
        cart = scan.Cartesian;
        homScanPoints = cart2hom(cart);

        % Apply homogeneous transformation
        transformedPoints = homScanPoints * tform';

        % Extract Cartesian points. Since we know that there is no scaling, simply
        % extract x and y values (rather than going through hom2cart).
        % Return transformed polar angles and ranges
        [tAngles, tRanges] = cart2pol(transformedPoints(:,1), transformedPoints(:,2));
    else
        tRanges = [];
        tAngles = [];
    end

    transScan = lidarScan(tRanges, tAngles);

end
