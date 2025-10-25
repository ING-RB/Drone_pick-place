%

% Copyright 2018-2022 The MathWorks Inc.

function removeFromMatlabPath(foldersArray)

% Ignore warning if not found in path
w = warning('off','MATLAB:rmpath:DirNotFound');
clean = onCleanup(@()warning(w));

for folder = 1:size(foldersArray,1)
    folderEntry = char(foldersArray(folder, :));
    rmpath(folderEntry);
end
end