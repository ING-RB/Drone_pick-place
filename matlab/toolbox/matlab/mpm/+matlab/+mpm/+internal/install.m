%   INSTALL Install packages
%   matlab.mpm.internal.install(packageSpecifier1, packageSpecifier2 ...)
%   matlab.mpm.internal.install(packageLocation1, packageLocation2 ...)
%   matlab.mpm.internal.install(option1, option2 ..., ...)
%
%   Installs one or more packages, specified as packageSpecifier or packageLocation,
%   as well as their dependencies. packageSpecifier and packageLocation
%   can be mixed in the same install command.
%
%   packageSpecifier - is a string of the form Name[@Version][@ID] where:
%       Name is the name of a package
%       @Version can optionally be added to specify packages with a matching version
%       @ID can optionally be added to specify packages with a particular ID
%     For example, myPackage, myPackage@1.2.3, and
%     myPackage@1.2.3@6b2c2af2-8fff-11ec-b909-0242ac120002 are valid package specifiers.
%
%   packageLocation - is the path to the folder containing the package.
%
%   Each input to install is first resolved as a path in the system. If succeeded,
%   the install will use that as source to copy the package to the install location.
%   Otherwise, the input is interpreted as package specifier and used to search packages from repositories.
%
%   The specified packages are added to the path, while its dependencies are not. You can reinstall an already installed
%   package in order to add it to the path.
%
%   matlab.mpm.internal.install takes following options:
%       -yes                      Silently answers yes to all prompts
%       -destination dstLocation  Installs packages to dstLocation instead of the default install location.

%   Copyright 2023 The MathWorks, Inc. Built-in function.
