%RESOLVEPATH Returns the absolute path for the input
%   PATH = MATLAB.IO.INTERNAL.FILESYSTEM.RESOLVEPATH(INPUT), for a
%   valid input
%
%   INPUT can be a string array, a character vector, or a cell array of
%   character vectors. An absolute path is returned for non-existent local
%   filesystem paths.
%
%   Example
%   -------
%   % Find the absolute path for "temp.txt" when pwd is "C:/example/path/to/file"
%   resolvedPath = matlab.io.internal.filesystem.resolvePath("temp.txt")
%   resolvedPath = "C:/example/path/to/file/temp.txt"
%
%   See also MATLAB.IO.INTERNAL.FILESYSTEM.RELATIVEPATH
%
%   Note: This function is intended for internal use only and is subject to change at any time

%   Copyright 2023 The MathWorks, Inc.
%   Built-in function
