classdef CollisionGeometryBuildable < coder.ExternalDependency
%This class is for internal use only. It may be removed in the future.

%CollisionGeometryBuildable Class implementing the collision checking and collision geometry methods that are compatible with code generation

% Copyright 2019-2024 The MathWorks, Inc.

%#codegen

% Static methods supporting code generation for CollisionGeometry and checkCollision builtins

    methods(Static)
        function bname = getDescriptiveName(~)
        %getDescriptiveName A descriptive name for the external dependency
            bname = 'CollisionGeometryBuildable';
        end

        function isSupported = isSupportedContext(~)
        %isSupportedContext Determines if code generation is supported for both host and target
        % (portable) code generation.
            isSupported = true;
        end

        function updateBuildInfo(buildInfo, ~)
        %updateBuildInfo Add headers and sources to the build info

        % Include directory of published headers
            apiIncludePaths = fullfile(matlabroot, 'extern', 'include',...
                                       'shared_robotics');

            % libccd root directory containing source and headers
            externalSourcePath = fullfile(matlabroot, 'toolbox', 'shared',...
                                          'robotics', 'externalDependency');


            % API source directory of published headers
            apiSourcePath = fullfile(matlabroot, 'toolbox', 'shared', ...
                                     'robotics', 'robotcore', 'builtins', 'libsrc', 'collisioncodegen');

            % libccd source directory
            ccdSrcPath = fullfile(externalSourcePath, 'libccd', 'src');
            ccdIncludePath = fullfile(ccdSrcPath, 'ccd');
            buildInfo.addIncludePaths({apiIncludePaths, ccdSrcPath, ccdIncludePath});

            buildInfo.addSourcePaths({ccdSrcPath, apiSourcePath});
            %.c files located under src/ccd
            buildInfo.addDefines('ccd_EXPORTS');
            ccdCFiles = dir([ccdSrcPath, '/*.c']);

            %.h files located under src/ccd
            ccdHFiles = dir([ccdSrcPath, '/*.h']);

            %.h files located under src/ccd/include
            ccdIncludeFiles = dir([ccdIncludePath, '/*.h']);

            %.cpp files located under libsrc/collisioncodegen/
            apiCFiles = dir([apiSourcePath, '/collisioncodegen_*.cpp']);

            %.cpp files located under $MATLABROOT/extern/include
            apiHFiles = dir([apiIncludePaths, '/collisioncodegen_*.hpp']);

            sourceFiles = [ccdCFiles; apiCFiles];
            includeFiles = [ccdHFiles; ccdIncludeFiles; apiHFiles];

            arrayfun(@(s)buildInfo.addSourceFiles(s.name), sourceFiles, 'UniformOutput', false);
            arrayfun(@(s)buildInfo.addIncludeFiles(s.name), includeFiles, 'UniformOutput', false);

        end

        function geometryInternal = makeBox(x, y, z)
        %makeBox Codegen-compatible version of robotics.core.internal.CollisionGeometryBase with three inputs
            geometryInternal = robotics.core.internal.coder.CollisionGeometryBuildable.initializeGeometry();
            coder.cinclude('collisioncodegen_api.hpp');
            geometryInternal = coder.ceval('collisioncodegen_makeBox', x, y, z);
        end

        function geometryInternal = makeSphere(r)
        %makeSphere Codegen-compatible version of robotics.core.internal.CollisionGeometryBase with one input
            geometryInternal = robotics.core.internal.coder.CollisionGeometryBuildable.initializeGeometry();
            coder.cinclude('collisioncodegen_api.hpp');
            geometryInternal = coder.ceval('collisioncodegen_makeSphere', r);
        end

        function geometryInternal = makeCylinder(r, h)
        %makeCylinder Codegen-compatible version of robotics.core.internal.CollisionGeometryBase with two inputs
            geometryInternal = robotics.core.internal.coder.CollisionGeometryBuildable.initializeGeometry();
            coder.cinclude('collisioncodegen_api.hpp');
            geometryInternal = coder.ceval('collisioncodegen_makeCylinder', r, h);
        end

        function geometryInternal = makeMesh(vertices, numVertices)
        %makeMesh Codegen-compatible version of robotics.core.internal.CollisionGeometryBase with two inputs
            geometryInternal = robotics.core.internal.coder.CollisionGeometryBuildable.initializeGeometry();
            coder.cinclude('collisioncodegen_api.hpp');
            geometryInternal = coder.ceval('collisioncodegen_makeMesh', vertices, numVertices);
        end

        function geometryInternal = makeCapsule(r, h)
        %makeCylinder Codegen-compatible version of robotics.core.internal.CollisionGeometryBase with two inputs
            geometryInternal = robotics.core.internal.coder.CollisionGeometryBuildable.initializeGeometry();
            coder.cinclude('collisioncodegen_api.hpp');
            geometryInternal = coder.ceval('collisioncodegen_makeCapsule', r, h);
        end

        function numVertices=getNumVertices(geom)
            coder.cinclude('collisioncodegen_api.hpp');
            numVertices=0;
            numVertices=coder.ceval('collisioncodegen_getNumVertices', (geom));
        end

        function x=getX(geom)
            coder.cinclude('collisioncodegen_api.hpp');
            x=0;
            x=coder.ceval('collisioncodegen_getX', (geom));
        end

        function y=getY(geom)
            coder.cinclude('collisioncodegen_api.hpp');
            y=0;
            y=coder.ceval('collisioncodegen_getY', (geom));
        end

        function z=getZ(geom)
            coder.cinclude('collisioncodegen_api.hpp');
            z=0;
            z=coder.ceval('collisioncodegen_getZ', (geom));
        end

        function radius=getRadius(geom)
            coder.cinclude('collisioncodegen_api.hpp');
            radius=0;
            radius=coder.ceval('collisioncodegen_getRadius', (geom));
        end

        function len=getLength(geom)
            coder.cinclude('collisioncodegen_api.hpp');
            len=0;
            len=coder.ceval('collisioncodegen_getLength', (geom));
        end

        function type=getType(geom)
            coder.cinclude('collisioncodegen_api.hpp');
            type_=repmat(' ',1,20);
            len=1;
            len=coder.ceval('collisioncodegen_getType', (geom),coder.ref(type_));
            type=type_(1:len);
        end

        function vertices=getVertices(geom)
            numVertices=robotics.core.internal.coder.CollisionGeometryBuildable.getNumVertices(geom);
            vertices=zeros(numVertices,3);
            coder.ceval('collisioncodegen_getVertices',(geom),coder.ref(vertices));
        end

        function [collisionStatus, separationDist, witnessPts] = ...
                checkCollision(geometryInternal1, position1, quaternion1, ...
                               geometryInternal2, position2, quaternion2, ...
                               needMoreInfo)

        %checkCollision Codegen-compatible version of checkCollision with two inputs

            collisionStatus = 0;
            separationDist = 0;
            p1Vec = zeros(3, 1);
            p2Vec = zeros(3, 1);
            coder.cinclude('collisioncodegen_api.hpp');
            collisionStatus = coder.ceval('collisioncodegen_intersect',...
                                          geometryInternal1, position1, quaternion1, ...
                                          geometryInternal2, position2, quaternion2, ...
                                          needMoreInfo, ...
                                          coder.ref(p1Vec), coder.ref(p2Vec), ...
                                          coder.ref(separationDist));
            witnessPts = [p1Vec, p2Vec];
        end

        function geometryInternal = initializeGeometry()
        %initializeGeometry Internal helper function which declares the type of GeometryInternal.
            geometryInternal = coder.opaquePtr('void', coder.internal.null);
        end

        function destructGeometry(geometryInternal)
            coder.cinclude('collisioncodegen_api.hpp');
            coder.ceval('collisioncodegen_destructGeometry', coder.rref(geometryInternal));
        end

        function copyGeometryInternal=copyGeometry(geometryInternal)
            copyGeometryInternal=robotics.core.internal.coder.CollisionGeometryBuildable.initializeGeometry();
            coder.cinclude('collisioncodegen_api.hpp');
            copyGeometryInternal=coder.ceval('collisioncodegen_copyGeometry', geometryInternal);
        end
    end
end
