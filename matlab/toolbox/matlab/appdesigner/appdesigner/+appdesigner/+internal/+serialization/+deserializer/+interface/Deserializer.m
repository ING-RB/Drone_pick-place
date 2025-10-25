classdef Deserializer < handle
    %DESERIALIZER Interface class for app deserialization

    properties (Access=protected)
        Validators
    end

    methods (Abstract)
        getAppData(obj);
        getAppCodeData(obj);
        getAppMetadata(obj);
    end
end