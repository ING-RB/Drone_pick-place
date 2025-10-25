function [isSeparate, connect] = checkSeparate(leftPoly, rightPoly)
%This function is for internal use only. It may be removed in the future.

%checkSeparate - Check if polyshape `union` thinks two polycells are separate
%   [isSeparate, connect] = checkSeparate(leftPoly, rightPoly) checks if 
%   leftPoly and rightPoly are separate and returns if they should be connected. 
%   If either polyshape is empty, the cells are marked as connected

%   Copyright 2024 The MathWorks, Inc.

%#codegen

    if leftPoly.NumRegions > 0 && rightPoly.NumRegions > 0
        unioned = union(leftPoly, rightPoly);
        isSeparate = unioned.NumRegions > 1 || unioned.NumHoles > 0;
        connect = ~isSeparate;
    else
        % if region disappears, mark as separate but say that they should 
        % be connected. The post-processing step to handle disappearing regions
        % should check the connection again at the end
        isSeparate = true;
        connect = true;
    end
end
