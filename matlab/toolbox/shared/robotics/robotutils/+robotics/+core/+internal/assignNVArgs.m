function obj = assignNVArgs(obj, nvargs)
%This function is for internal use only. It may be removed in the future.

%ASSIGNNVARGS Assigns NV argument list to object OBJ and returns OBJ

%   Copyright 2023 The MathWorks, Inc.

%#codegen

userProvidedProperties=fieldnames(nvargs);
for i=coder.unroll(1:length(userProvidedProperties))
    obj.(userProvidedProperties{i})=nvargs.(userProvidedProperties{i});
end

end