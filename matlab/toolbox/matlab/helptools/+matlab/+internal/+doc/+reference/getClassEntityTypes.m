function entityTypes = getClassEntityTypes
    import matlab.internal.reference.property.RefEntityType;
    entityTypes = [RefEntityType.Class, RefEntityType.Object, RefEntityType.Sys_Obj, RefEntityType.Properties, RefEntityType.Constructor];
end

% Copyright 2020-2022 The MathWorks, Inc.
