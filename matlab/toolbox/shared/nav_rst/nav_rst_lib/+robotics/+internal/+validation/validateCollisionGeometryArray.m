function isValid = validateCollisionGeometryArray(collisionObjects, fcnName, varName)
%This function is for internal use only. It may be removed in the future.

%validateCollisionGeometryArray Validate the collision mesh cell array input
%   Validate a cell array of collision meshes

%   Copyright 2024 The MathWorks, Inc.

    isValid = true;
    validateattributes(collisionObjects, {'cell'}, {'nonempty'}, fcnName, varName);
    for i = 1:length(collisionObjects)
        if(~isa(collisionObjects{i}, 'robotics.core.internal.CollisionGeometryBase'))
            isValid = false;
            break;
        end
    end

    if ~isValid
        robotics.core.internal.error('vhacd:InvalidMeshArrayError', varName);
    end

end