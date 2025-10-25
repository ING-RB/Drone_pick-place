function tf = isBuildFile(fileName)
% @pre fileName is an absolute path
import matlab.buildtool.internal.isFunctionBasedBuildFile;

try
    parseTree = mtree(fileName, "-file");
    builtin("_mcheck", fileName);
    
    [folder,~,ext] = fileparts(fileName);

    tf = isFunctionBasedBuildFile(parseTree) && ...
        ~strcmpi(ext, ".mlx") && ...
        ~contains(folder, filesep() + "@") && ...
        ~contains(folder, filesep() + "+") && ...
        ~endsWith(folder, filesep() + "private");
    
catch
    tf = false;
end
end
