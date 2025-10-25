classdef CollisionGeometryBuildableFunctional < coder.ExternalDependency
%This class is for internal use only. It may be removed in the future.

%CollisionGeometryBuildableFunctional Codegen artifacts for object free collision checking

% Copyright 2024 The MathWorks, Inc.

%#codegen

% Static methods supporting code generation for CollisionGeometry and checkCollision builtins

    properties(Constant)
        %DEFAULT_MAX_NUM_VERT Default maximum number of vertices in geometry struct
        DEFAULT_MAX_NUM_VERT=1e4
    end

    methods(Static)
        function bname = getDescriptiveName(~)
        %getDescriptiveName A descriptive name for the external dependency
            bname = 'CollisionGeometryBuildableFunctional';
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
            apiSpecificIncludePaths= fullfile(matlabroot, 'extern', 'include',...
                                       'shared_robotics','collfcncodegen');

            % libccd root directory containing source and headers
            externalSourcePath = fullfile(matlabroot, 'toolbox', 'shared',...
                                          'robotics', 'externalDependency');


            % API source directory of published headers
            apiSourcePath = fullfile(matlabroot, 'toolbox', 'shared', ...
                                     'robotics', 'robotcore', 'builtins', 'libsrc', 'collisioncodegen');
            apiSpecificSourcePath = fullfile(matlabroot, 'toolbox', 'shared', ...
                                     'robotics', 'robotcore', 'builtins', 'libsrc', 'collisionfcncodegen');

            % libccd source directory
            ccdSrcPath = fullfile(externalSourcePath, 'libccd', 'src');
            ccdIncludePath = fullfile(ccdSrcPath, 'ccd');
            buildInfo.addIncludePaths({apiIncludePaths, apiSpecificIncludePaths, ccdSrcPath, ccdIncludePath});

            buildInfo.addSourcePaths({ccdSrcPath, apiSpecificSourcePath, apiSourcePath});
            %.c files located under src/ccd
            buildInfo.addDefines('ccd_EXPORTS');
            ccdCFiles = dir([ccdSrcPath, '/*.c']);

            %.h files located under src/ccd
            ccdHFiles = dir([ccdSrcPath, '/*.h']);

            %.h files located under src/ccd/include
            ccdIncludeFiles = dir([ccdIncludePath, '/*.h']);

            %.c/.cpp files located under libsrc/collisioncodegen/
            apiCFiles = dir([apiSourcePath, '/collisioncodegen_*.c*']);
            apiSpecificCFiles = dir([apiSpecificSourcePath, '/collisioncodegen_*.c*']);

            %.h/.hpp files located under $MATLABROOT/extern/include
            apiHFiles = dir([apiIncludePaths, '/collisioncodegen_*.h*']);
            apiSpecificHFiles = dir([apiSpecificIncludePaths, '/collisioncodegen_*.h*']);

            sourceFiles = [ccdCFiles; apiSpecificCFiles; apiCFiles];
            includeFiles = [ccdHFiles; ccdIncludeFiles; apiSpecificHFiles; apiHFiles];

            arrayfun(@(s)buildInfo.addSourceFiles(s.name), sourceFiles, 'UniformOutput', false);
            arrayfun(@(s)buildInfo.addIncludeFiles(s.name), includeFiles, 'UniformOutput', false);
        end


        function [collisionStatus,separationDist,witnessPts]=intersect(geom1,geom2,needMoreInfo)
        %intersect Codegen-compatible version of intersect with two inputs
        %    During codegen, capture information about the entry point
        %    geometry arguments into an externally defined struct and
        %    explicitly pass vertices to the intersect API as MATLAB Coder
        %    could potentially reuse buffers to store them, and passing
        %    addresses of the buffer will lead to the intersect API reading
        %    the same vertices in case the geometries are meshes. For
        %    meshes, under the hood, collisioncodegen_intersect2 will assign
        %    vertices arguments to respective geometry structs.
            collisionStatus = int8(0);
            separationDist = 0;
            p1Vec = zeros(3, 1);
            p2Vec = zeros(3, 1);
            coder.cinclude('collisioncodegen_functional_api.hpp');
            vert1=geom1.m_Vertices;
            vert2=geom2.m_Vertices;
            geom1struct=fromMLToCollStruct(geom1);
            geom2struct=fromMLToCollStruct(geom2);
            collisionStatus = coder.ceval('collisioncodegen_intersect2',...
                                          coder.rref(geom1struct), ...
                                          coder.rref(vert1), ...
                                          coder.rref(geom2struct), ...
                                          coder.rref(vert2), ...
                                          needMoreInfo, ...
                                          coder.ref(p1Vec), coder.ref(p2Vec), ...
                                          coder.ref(separationDist));
            witnessPts = [p1Vec, p2Vec];
        end

        function geomstruct=createGeometryStruct(usecstruct,maxnumvert)
        %createGeometryStruct Create a collision geometry struct
        %   Create a collision geometry struct which captures the type of
        %   the convex geometry, its pose, and its dimensions. This struct
        %   can be reused for any type of convex geometry. For example, a
        %   collision geometry struct representing an axis aligned box
        %   still has information about radius and height!
        %
        %   GEOMSTRUCT=createGeometryStruct() creates a geometry struct
        %   with fields:
        %       - m_Type: An integer constant (acing like an enum) denoting
        %                 type of the geometry
        %       - m_X: Size of the X dimension of a box
        %       - m_Y: Size of the Y dimension of a box
        %       - m_Z: Size of the Z dimension of a box
        %       - m_Radius: Radius of a capsule or a cylinder
        %       - m_Height: Height of a capsule or a cylinder
        %       - m_Vertices: Vertices corresponding to a collision mesh
        %       - m_NumVertices: Number of vertices. For fixed-sized
        %                        buffers m_Vertices this field value keeps
        %                        track of number of vertices in the buffer.
        %       - m_Position: Position of the geometry in the world frame
        %       - m_Quaternion: Quaternion representing orientation of the
        %                       geometry in the world frame
        %
        %   _=createGeometryStruct(USECSTRUCT) creates a geometry struct
        %   with a definition provided in a custom header file if
        %   USECSTRUCT is logical true. If USECSTRUCT is false, the
        %   generated type of the struct in code generated from MATLAB code
        %   is defined by MATLAB Coder itself.
        %
        %   _=createGeometryStruct(_,MAXNUMVERT) creates a geometry struct
        %   with a maximum number of vertices MAXNUMVERT. By default,
        %   MAXNUMVERT is 10e3. Note that when USECSTRUCT is true, no
        %   buffer is allocated in the output struct, and hence, this value
        %   is not used.
            arguments
                usecstruct=false
                maxnumvert=robotics.core.internal.coder.CollisionGeometryBuildableFunctional.DEFAULT_MAX_NUM_VERT
            end

            % If an external header defines this struct, match the
            % definition of the m_Vertices field as real64_T*.
            if(coder.const(usecstruct))
                vert=coder.opaque('real64_T*','NULL');
            else

                % If no external headers are used, and MATLAB Coder is
                % responsible for generating a type from the output struct
                % (say, via coder.typeof), allocate a flattened buffer to store
                % 3 dimensional maximum number of vertices.
                vert=zeros(1,3*maxnumvert);
            end
            geomstruct=struct(...
                "m_Type",uint8(0),...
                "m_X",0,...
                "m_Y",0,...
                "m_Z",0,...
                "m_Radius",0,...
                "m_Height",0,...
                "m_Vertices",vert,...
                "m_NumVertices",uint32(0),...
                "m_Position",zeros(1,3),...
                "m_Quaternion",[1,zeros(1,3)]);
            if(coder.const(usecstruct))
                coder.cstructname(geomstruct,'CollisionGeometryStruct','extern','HeaderFile','collisioncodegen_functional_api.hpp');
            end
        end
    end
end

function geomstruct=fromMLToCollStruct(geom)
%fromMLToCollStruct Convert MATLAB Coder generated type to externally defined struct type
    geomstruct=...
        robotics.core.internal.coder.CollisionGeometryBuildableFunctional.createGeometryStruct(true);
    fnames=fieldnames(geomstruct);
    for i=coder.unroll(1:length(fnames))
        if(~strcmp(fnames{i},'m_Vertices'))
            geomstruct.(fnames{i})=geom.(fnames{i});
        end
    end
end
