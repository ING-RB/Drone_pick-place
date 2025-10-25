function meshStruct = meshStruct(N)
%meshStruct Create varsize-compatible struct for mesh
%
%   MESHSTRUCT = meshtsdf.meshStruct returns a 0x1 mesh
%   struct with required fields
%
%   MESHSTRUCT = meshtsdf.meshStruct(N) Generates an Nx1
%   struct-array with required fields
%
%   See also: meshtsdf/MESHSTRUCT

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen

    arguments
        N (1,1) double {mustBeNonnegative, mustBeInteger} = 0;
    end

    % Create codegen-compatible struct elements
    vsizeMat = zeros(0,3);
    coder.varsize('vsizeMat',[inf 3]);

    % Create default struct type
    meshStruct = repmat(struct('ID',0,'Pose',eye(4),'Vertices',vsizeMat,'Faces',vsizeMat),N,1);
end
