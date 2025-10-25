%   Copyright 2022 The MathWorks, Inc.
classdef EnumStruct < matlab.mixin.SetGet
%     EnumStruct creates an entity which is used to store name and value of
%     enum property. This is used for parsing the headerfiles.

    properties
        Name = '';
        Values = {};
    end

    methods
        function obj = EnumStruct(name,vals)
            obj.Name = name;
            obj.Values = [obj.Values vals];
        end


    end
end

