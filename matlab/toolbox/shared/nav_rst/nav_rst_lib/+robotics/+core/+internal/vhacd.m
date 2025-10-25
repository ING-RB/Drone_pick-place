function [decomp,debugData]=vhacd(objMesh,optionsStruct)
% This function is for internal use only, and maybe removed in the future

%decomposeVHACD Compute convex decomposition using V-HACD
%   This method accepts a mesh, represented as a triangulation, and a
%   structure of options. The method computes the decomposition using
%   Voxelized Hierarchical Approximate Convex Decomposition (V-HACD) and
%   returns the resultant array of convex hulls and structure of associated
%   volume information.

%   Copyright 2023 The MathWorks, Inc.

    vertices = objMesh.Points;
    faces = objMesh.ConnectivityList;
    [decomp, numHulls] = robotics.core.internal.computeVHACD(optionsStruct, vertices, faces); %#ok<ASGLU>

    if nargout > 1
        mesh = Geometry.mesh(objMesh);
        srcVolume = Geometry.volume(mesh);
        debugData = struct(...
            'SourceVolume', srcVolume, ...
            'CompositeDecompVolume', sum([decomp.Volume]));
    end

end
