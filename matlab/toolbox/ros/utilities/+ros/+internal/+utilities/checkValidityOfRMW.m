function [isRMWImplementation,hasIntrospecTypeSupport] = checkValidityOfRMW(rmwPackageCMakeListsPath, pkgFolderName)
%This function is for internal use only. It may be removed in the future.

%   Copyright 2022-2023 The MathWorks, Inc.

% This utility validates if a package is a RMW implementation.
% Any RMW implementation package starts with 'rmw_' and contains 
% 'register_rmw_implementation' function in their CMakeLists.txt.
% If the 'rosidl_typesupport_introspection' string is present in call to
% function 'register_rmw_implementation', the package depends on dynamic
% typesupport else it depends on static typesupport.

filetext = fileread(rmwPackageCMakeListsPath);
isRMWImplementation = false;
hasIntrospecTypeSupport = false;
if nargin == 2
   % check for package name from CMakeLists.txt and see if it matches with
   % the package folder name.
   rmwPkgName = '[^\n]*project[^)]*';
   isValidPackage = false;
   matches = regexp(filetext,rmwPkgName,'match');
   if ~isempty(matches)
       isValidPackage = contains(matches{1}, pkgFolderName);
   end
   if ~isValidPackage
       return;
   end
end
expr = '[^\n]*register_rmw_implementation[^)]*';
matches = regexp(filetext,expr,'match');
if ~isempty(matches)
    isRMWImplementation = true;
    hasIntrospecTypeSupport = contains(matches{1},'rosidl_typesupport_introspection');
end
end
