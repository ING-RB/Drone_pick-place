function [outputDir, appName] = getAppOutputFolder(appPath)
    [parentDir, appName, ~] = fileparts(appPath);
    % outputLocation is is path/to/app/appName/app.ctf
    outputDir = fullfile(parentDir, 'release');
end