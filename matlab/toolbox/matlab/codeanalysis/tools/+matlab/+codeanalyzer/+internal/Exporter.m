classdef Exporter
%Exporter   helper class to export codeIssues object to html

%   Copyright 2022-2023 The MathWorks, Inc.

    methods (Static)
        function exportToHtml(issues, folder, options)
            arguments
                issues codeIssues
                folder string % folder name to store the html file
                options.SourceRoot {matlab.codeanalyzer.internal.validateSourceRoot(options.SourceRoot, issues)} = missing
                options.TargetRoot {validateTargetRoot} = "file://"
                options.IncludeLinkToFile (1,1) logical = true
            end
            sourcePath = fullfile(matlabroot, "toolbox/matlab/codeanalysis/analyzerrpt/web/analyzerrpt");

            % create the folder to store the file
            [path, folderName, ~] = fileparts(folder);
            targetPath = fullfile(path, folderName);
            throwOnFailure(@() mkdir(targetPath));

            throwOnFailure(@() mkdir(fullfile(targetPath, "release")));
            throwOnFailure(@() mkdir(fullfile(targetPath, "release", "analyzerrpt-ui")));

            % copy the necessary files form release folder into the new folder.
            throwOnFailure(@() copyfile(fullfile(sourcePath, "release", "bundle.index.js"), fullfile(targetPath, "release"), 'f'));
            throwOnFailure(@() copyfile(fullfile(sourcePath, "release", "analyzerrpt-ui", "dojoConfig-release-global.js"), ...
                fullfile(targetPath, "release", "analyzerrpt-ui"), 'f'));
            throwOnFailure(@() copyfile(fullfile(sourcePath, "release", "index-css.css"), fullfile(targetPath, "release"), 'f'));
            throwOnFailure(@() copyfile(fullfile(sourcePath, "release", "ui"), fullfile(targetPath, "release", "ui"), 'f'));
            throwOnFailure(@() copyfile(fullfile(sourcePath, "index.html"), fullfile(targetPath), 'f'));

            % add the serialized mf0 data into a js file.
            serializer = mf.zero.io.JSONSerializer;
            mf0Data = serializer.serializeToString(issues.modelMessages);
            f = fopen(fullfile(targetPath, "release", "mf0Data.js"), "w");
            fprintf(f, "%s", "mf0Data = ");
            fprintf(f, "%s", mf0Data);
            fprintf(f, "%s", ";");
            fclose(f);

            % add the serialized mf0 status into a js file
            mf0StatusModel = mf.zero.Model();
            statusModel = matlab.codeanalyzer.internal.datamodel.StatusModel(mf0StatusModel);
            statusModel.initialized = true;
            statusModel.numMessages = numel(issues.modelMessages.getActiveMessages());
            statusModel.targetRoot = options.TargetRoot;
            if ismissing(options.SourceRoot)
                statusModel.sourceRoot = '';
            else
                statusModel.sourceRoot = options.SourceRoot;
            end
            if options.IncludeLinkToFile
                statusModel.linkType = 'file';
            else
                statusModel.linkType = 'none';
            end
            mf0Status = serializer.serializeToString(mf0StatusModel);
            f = fopen(fullfile(targetPath, "release", "mf0Status.js"), "w");
            fprintf(f, "%s", "mf0Status = ");
            fprintf(f, "%s", mf0Status);
            fprintf(f, "%s", ";");
            fclose(f);
        end
    end
end

function throwOnFailure(fh)
    [status, msg, msgId] = fh();
    if status ~= 1
        % if fails, throws error
        error(msgId, msg);
    end
end

function validateTargetRoot(targetRoot)
    mustBeTextScalar(targetRoot)

    url = matlab.net.URI(targetRoot);

    % TargetRoot must be http://, https://, file:// or a relative path
    if ~isempty(url.Scheme) && ~matches(url.Scheme, ["http", "https", "file"])
        error(message("MATLAB:codeanalyzer:BeginWithTargetRoot"));
    end
    % TargetRoot must not contains any query or fragment component
    if ~isempty(url.Query) || ~isempty(url.Fragment) 
        error(message("MATLAB:codeanalyzer:TargetRootContent"));
    end
end

