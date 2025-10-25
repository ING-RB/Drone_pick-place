classdef ObjectValueSummary < handle
    % This class is unsupported and might change or be removed without notice in
    % a future version.
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    % This class is used by the Workspace Browser to store information related
    % to objects, which are displayed in the Workspace Browser.  This is done so
    % as not to keep a handle to an object, which can prevent it's cleanup from
    % happening synchronously as expected.
    properties
        DisplayValue;
        DisplayClass;
        DisplayType; % NOTE: For datatypes like gpuArray/distributed, we store underlyingType in order to display specific icons on client
        DisplaySize;
        RawValue; % NOTE: For base datatypes that are objects, we store RawValue as well in order to compute Bytes and other statistics
    end
end
