%   REPO Manage package repositories
%   R = matlab.mpm.internal.repo(subcommand)
%   R = matlab.mpm.internal.repo(subcommand, repoPath1, repoPath2 ...)
%
%   Manages local repository of packages using the actions specified by subcommand.
%   A local repository is a root folder where each subfolder represents a package.
%
%   matlab.mpm.internal.repo takes following subcommands:
%       list               Displays list of local repositories.
%       add repoPath       Adds the repositories, specified by repoPath, to the list of
%                          local repositories. Additionally, it returns the list of
%                          repositories prior to addition in R.
%       remove repoPath    Removes the repositories, specified by repoPath, from the list
%                          of local repositories.

%   Copyright 2023 The MathWorks, Inc. Built-in function.
