function out = openprj(filename)
    %OPENPRJ opens a MATLAB Compiler, MATLAB Coder project or MATLAB Project.
    %
    %   OPENPRJ(FILENAME) opens the MATLAB Compiler, MATLAB Coder project or
    %   MATLAB Project. If FILENAME is not a valid project file then it is
    %   opened in the MATLAB Editor.
    %
    %   See also DEPLOYTOOL, MCC, MBUILD, CODER, OPENPROJECT

    %   Copyright 2006-2024 The MathWorks, Inc.

    out = [];

    % Try handling as a legacy Coder or Deployment PRJ
    % "Filename" is a misnomer as it's guaranteed to be called with an 
    % absolute path by the OPEN function.
    try
        [wasHandled, bubbledException] = handleAsLegacyCoderAndDeployment(filename);
    catch e % Internal bug, pretend nothing happened and defer to MATLAB Project
        wasHandled = false;
        bubbledException = [];
    end
    if ~isempty(bubbledException)
        % Positive ID as a Coder/Deployment PRJ but deemed untreatable
        bubbledException.throwAsCaller();
    elseif wasHandled
        return
    end

    % Try opening as a MATLAB Project if it is available
    try
        valid = i_openMATLABProject(filename);
        if valid
            matlab.project.show();
            matlab.internal.project.view.showWelcomeGuide(fileparts(filename));
            return
        end
    catch exception
        if exception.identifier == "MATLAB:project:api:LoadFail"
            error('MATLAB:open:openFailure','%s', exception.message)
        end
    end

    % We do not have a product installed that uses this .prj file, so treat it
    % like a third-party file.
    edit(filename);

end

function [handled, bubbledException] = handleAsLegacyCoderAndDeployment(filePath)
    % Introspect the PRJ and extract the target key. If the target key
    % identfies as Coder-facing, handle it internally and signal.
    [handled, bubbledException, targetKey] = coderapp.internal.matlab.openPrjHelper(filePath);
    if handled
        return % Handled using Coder-specific code path
    elseif targetKey == ""
        return % Structural mismatch to Coder and Deployment format PRJs
    end

    % Non-Coder so it must be Deployment, change as needed for Java Transition
    [config, fileWarnings, unsupportedFeatureWarnings] = matlab.internal.deployment.createProjectModelFromPRJ(filePath);

    % If the config is empty, an error was already presented in the
    % previous call
    if ~isempty(config)
        matlab.internal.deployment.guide.launchSetupGuideFromUpgrade(config.ProfileDisplayName, filePath, fileWarnings, unsupportedFeatureWarnings)
        matlab.internal.deployment.openConfigDocument(config);
    end

    handled = true;
end
        
function valid = i_openMATLABProject(filename)
    % Do not use an import here because MATLAB will fail to parse the entire file
    % when the imported class doesn't exist (i.e. slproject not installed)
    valid = matlab.internal.project.util.PathUtils.loadProjectForOpenPRJ(filename);
end
