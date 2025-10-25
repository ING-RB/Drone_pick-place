function arg = getRunBuildFirstArgument(fullFile)
% fullFile must be the full path to the build file

% Checks if `buildtool` will find the correct location on its own, and
% utilizes `-buildFile` if necessary

fullFolder = fileparts(fullFile);

undercut = false;

f = pwd();
while startsWith(f, fullFolder) && ~strcmp(f, fullFolder)
    if isfile(fullfile(f, "buildfile.m"))
        undercut = true;
        break;
    end

    f = fileparts(f);
end

if ~undercut && startsWith(pwd(), fullFolder)
    arg = "";
else
    arg = "-buildFile " + "'" + strrep(fullFile, "'", "''") + "'";
end
end
