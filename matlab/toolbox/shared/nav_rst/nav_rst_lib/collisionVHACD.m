function [collisionObjArray, info] = collisionVHACD(inputObj, opts)
%

%   Copyright 2023 The MathWorks, Inc.

    meshData = validateAndParseMeshInput(inputObj);

    if nargin < 2
        optionsStruct = robotics.core.internal.defaultVHACDOpts;
    else
        validateattributes(opts, {'vhacdOptions'}, {'nonempty', 'numel', 1}, 'collisionVHACD', 'opts');
        optionsStruct = robotics.core.internal.VHACDHelpers.readStructFromVHACDOptions(opts);
    end

    % Call the internal API
    if nargout < 2
        decomp = robotics.core.internal.vhacd(meshData,optionsStruct);
    else
        % Only compute the info if requested
        [decomp,info] = robotics.core.internal.vhacd(meshData,optionsStruct);
        info.RawData = cellfun(@(x)(x), {decomp.Hull}, 'UniformOutput', false);
    end

    % Convert the output into a cell array of collision objects
    collisionObjArray = cellfun(@(x)(collisionMesh(x)), {decomp.Hull}, 'UniformOutput', false);

end

function meshData = validateAndParseMeshInput(inputObj)
%validateAndParseMeshInput Validate input and extract mesh data

    validateattributes(inputObj, {'triangulation'}, {'nonempty', 'numel', 1}, 'collisionVHACD', 'inputObj');
    if isa(inputObj, "triangulation")
        meshData = inputObj;
    elseif isstring(inputObj) || ischar(inputObj)
        % TODO: Requires a utility in robotics.manip.* (g2978461)
    end

end
