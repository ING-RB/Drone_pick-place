%   Copyright 2022 The MathWorks, Inc.
classdef StrucStruct < matlab.mixin.SetGet
%     StructStruct creates an entity which is used to store values of a
%     structure.This is used for parsing the headerfiles.
    properties
        Name = '';
        Values = {};
    end

    methods
        function obj = StrucStruct(name,vals)
            %ENUMSTRUCT Construct an instance of this class
            %   Detailed explanation goes here
            obj.Name = name;
            for i=1:length(vals)
                a = vals{i};
                a = strsplit(a,' ');
                obj.Values = [obj.Values a{2}];
            end
        end
    end
end
