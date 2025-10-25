%   Copyright 2022 The MathWorks, Inc.
classdef FunctionStruct < matlab.mixin.SetGet
%     FunctionStruct creates an entity which is used to store name, return
%     type and arguments of a given function.
    properties
        Name = '';
        retType = '';
        argTypes = {};
        inpArgs = {};
        retArg = {};
    end

    methods
        function obj = FunctionStruct(name,ret,args)
            %FUNCTIONSTRUCT Construct an instance of this class
            %   Make an object of this class to store the properties of a
            %   parsed function
            obj.Name = name;
            obj.retType = ret;
            obj.argTypes = args;
        end


    end
end

