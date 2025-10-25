function th = theta(obj)
%THETA Extract rotation angle
%   TH = THETA(R) extracts the N-by-1 matrix of rotation angles from the
%   rotation array R (with N elements). Each row of TH represents a 2-D
%   rotation angle around the z-axis (in radians).

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    thCol = robotics.internal.rotm2theta(obj.rotm);
    th = reshape(thCol,size(obj));
end
