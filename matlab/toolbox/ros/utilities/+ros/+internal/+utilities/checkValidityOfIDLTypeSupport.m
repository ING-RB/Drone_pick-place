function isTypeSupportPkg = checkValidityOfIDLTypeSupport(rosTypeSupportCMakeListsPath)
%This function is for internal use only. It may be removed in the future.

%   Copyright 2022 The MathWorks, Inc.

% This utility validates if a package is a ROS IDL Type Support package.
% Any ROS IDL Type Support package with 'rosidl_typesupport_' and contains
% 'ament_index_register_resource("rosidl_typesupport_cpp")' function in their CMakeLists.txt.

filetext = fileread(rosTypeSupportCMakeListsPath);
expr = '[^\n]*ament_index_register_resource("rosidl_typesupport_c[^)]*';
matches = regexp(filetext,expr,'match');
isTypeSupportPkg = false;
if ~isempty(matches)
    isTypeSupportPkg = true;
end
end
