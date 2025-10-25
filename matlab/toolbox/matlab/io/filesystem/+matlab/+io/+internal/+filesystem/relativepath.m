%RELATIVEPATH    Returns the relative path between an absolute source and destination path
%   RELPATH = MATLAB.IO.INTERNAL.FILESYSTEM.RELATIVEPATH(SRC, DEST), for a valid source and destination string
%   [RELPATH1, RELPATH2, ...] = MATLAB.IO.INTERNAL.FILESYSTEM.RELATIVEPATH(SRC, [DEST1, DEST2, ...])
%   accepts a vector input for destination, returning the relative path to each element
%
%   SRC can be a scalar char vector or scalar string
%   DEST can be a string array, a character vector, or a cell array of
%   character vectors.
%   
%   Example 
%   -------
%   % Find the relative path between two absolute paths "C:/example/root" and "C:/example/path/to/file"
%   relpath = matlab.io.internal.filesystem.relativepath("C:/example/root", "C:/example/path/to/file")
%   relpath = "../path/to/file"
%
%   See also ISFILE, ISFOLDER, MATLAB.IO.INTERNAL.FILESYSTEM.RESOLVEPATH
% 
%   Note: This function is intended for internal use only and is subject to change at any time

%   Copyright 2021 The MathWorks, Inc.
%   Built-in function
