function removeFromMatlabPath(foldersArray)
% removeFromMatlabPath Removes folders from path ignoring the warnings if
% folder does not exist

% Copyright 2020-2022 The MathWorks Inc.

% Ignore warning if not found in path
w = warning('off','MATLAB:rmpath:DirNotFound');
clean = onCleanup(@()warning(w));

for folder = 1:size(foldersArray,1)
    folderEntry = char(foldersArray(folder, :));
    rmpath(folderEntry);
end
end