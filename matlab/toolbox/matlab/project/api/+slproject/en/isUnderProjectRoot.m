%isUnderProjectRoot  Determine if a file or a folder is under a project root
%    b = slproject.isUnderProjectRoot(f) returns true if the input file or
%    folder is under a project root folder and returns false otherwise. slproject.isUnderProjectRoot returns false if f is a project root folder itself.
%
%    [b, projectRoot] = slproject.isUnderProjectRoot(f) returns the location of the
%    first project root it finds. If the input file and folder is not under a project root, [b, projectRoot] = slproject.isUnderProjectRoot(f) returns an empty string.
%
%    Checking that a file f is part of a project can be a slow operation. Use slproject.isUnderProjectRoot
%    to perform a quick check if a file is under a project root.

 
%  Copyright 2012-2022 The MathWorks, Inc.

