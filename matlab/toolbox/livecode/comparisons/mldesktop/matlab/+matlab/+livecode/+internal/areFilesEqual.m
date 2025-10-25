function tf = areFilesEqual(first, second)
%areFilesEqual     Determine whether two livecode files are equivalent in a 
%                  way that is consistent with the livecode GUI diff tool.
%                  Returns true if the files are equivalent, false otherwise.
%
%                  Examples:
%
%                  import matlab.livecode.internal.areFilesEqual
%                  tf = areFilesEqual('a.mlx', 'copy_of_a.mlx'); % true
%                  tf = areFilesEqual('a.mlx', 'modified_a.mlx'); % false

% Copyright 2023 The MathWorks, Inc.

    arguments
        first {mustBeTextScalar, mustBeFile}
        second {mustBeTextScalar, mustBeFile}
    end

    tf = matlab.livecode.internal.areFilesEqualImpl(first, second);
end
