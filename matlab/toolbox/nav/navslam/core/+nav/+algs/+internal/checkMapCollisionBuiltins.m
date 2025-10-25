classdef checkMapCollisionBuiltins < nav.algs.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

%checkMapCollisionBuiltins Interface to builtins used for checkMapCollision
%
%   This class is a collection of helper methods functions used for
%   interfacing with the
%   collisionmapbuiltins and collisionmapcodegen libraries. Its main
%   purpose is to extract MCOS pointers from MATLAB classes and dispatch
%   function calls when executed in MATLAB or code generation. During
%   MATLAB execution, we send existing MCOS C++ class classes to functions
%   registered under collisionmapbuiltins. During code generation we use a
%   set of codegen-compatible APIs housed in collisionmapcodegen.
%
%   See also nav.algs.internal.coder.checkMapCollisionBuildable

% Copyright 2022-2023 The MathWorks, Inc.

%#codegen

    methods (Static,Hidden)
        % Friend methods for retrieving internal pointers
        function mapPtr = retrieveMapPointer(occMap3D)
        %retrieveMapPointer Extracts MCOS or opaque pointer to C++ tree wrapper object
            if coder.target('MATLAB')
                % During MATLAB, Octree stores the pointer to
                % OctomapWrapperImpl builtin object
                mapPtr = occMap3D.Octree.MCOSObj;
            else
                % During codegen, the octomapcodegen class serves as a
                % wrapper around the C++ OcTree
                mapPtr = occMap3D.Octree.Octomap;
            end
        end

        function [geomPtr, pos, quat] = retrieveGeometryPointer(collisionObject)
        %retrieveGeometryPointer Extracts pointer to C++ geometry
            geomPtr = collisionObject.GeometryInternal;

            % Retrieve position and orientation of geometry
            pos     = collisionObject.Position;
            quat    = collisionObject.Quaternion;
        end
    end
end
