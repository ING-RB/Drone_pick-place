function [metaClass, classError] = getMetaClass(className)
    try
        metaClass = meta.class.fromName(className);
        classError = false;
    catch
        metaClass = [];
        classError = true;
    end
end

%   Copyright 2021 The MathWorks, Inc.
