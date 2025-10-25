classdef ExternalSCMLink< handle
%
%  Utilities for configuring the MATLAB external comparison link
%
%  Before setting up your source control client to use MATLAB for diffs and
%  merges run the following command to display the file paths that need to
%  be entered into your external source control client.
%      comparisons.ExternalSCMLink.setup()
%
%  To retrieve the executable file paths that need to be entered into the
%  external source control client:
%      diffPath = comparisons.ExternalSCMLink.DiffExecutablePath
%      mergePath = comparisons.ExternalSCMLink.MergeExecutablePath
%      autoMergePath = comparisons.ExternalSCMLink.AutoMergeExecutablePath
%
%  To setup the global Git config to use these paths run:
%      comparisons.ExternalSCMLink.setupGitConfig();

 
%   Copyright 2016-2024 The MathWorks, Inc.

    methods
        function out=setup(~) %#ok<STOUT>
        end

        function out=setupGitAutoMergeDriver(~) %#ok<STOUT>
        end

        function out=setupGitConfig(~) %#ok<STOUT>
        end

        function out=setupGitDiffTool(~) %#ok<STOUT>
        end

        function out=setupGitMergeTool(~) %#ok<STOUT>
        end

    end
    properties
        AutoMergeExecutablePath;

        DiffExecutablePath;

        MergeExecutablePath;

    end
end
