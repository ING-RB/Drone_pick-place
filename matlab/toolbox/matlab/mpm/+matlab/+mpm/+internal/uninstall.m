%   UNINSTALL Uninstall packages
%   matlab.mpm.internal.uninstall(packageSpecifier1, packageSpecifier2 ...)
%   matlab.mpm.internal.uninstall(option1, option2 ..., ...)
%
%   Uninstalls one or more packages and their unused dependencies. A package
%   cannot be uninstalled while other packages depend on it.
%   Dependency package is considered unused if all 3 conditions below are true:
%      - The package is not on the MATLAB path
%      - There are no other packages depending on the package
%      - The package was initially installed as a dependency (Automatic installation)
%
%   matlab.mpm.internal.uninstall takes following options:
%       -yes     Silently answers yes to all prompts
%       -noDeps  Only removes the specified packages.

%   Copyright 2023 The MathWorks, Inc. Built-in function.
