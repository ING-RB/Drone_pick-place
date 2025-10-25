function server = create(items, options)
%CREATE create a code analyzer report backend for the input files and
%folders

%   Copyright 2021-2022 The MathWorks, Inc.

    arguments
        items {mustBeNonzeroLengthText} = pwd
        options.IncludeSubfolders logical = true
        options.CodeAnalyzerConfiguration {mustBeNonzeroLengthText, mustBeTextScalar} = "active";
        options.IsDashboard (1,1) logical = false;
        options.IsCompatibilityReport (1,1) logical = false;
    end
    connector.ensureServiceOn;
    source = 'desktop';
    if options.IsDashboard
        source = 'dashboard';
    end
    % create the MessagesModel class in the model and store the file/folder
    % information
    mf0DataModel = mf.zero.Model();
    txn = mf0DataModel.beginTransaction;
    messagesModel = matlab.codeanalyzer.internal.datamodel.MessagesModel(mf0DataModel);
    messagesModel.topFolderOnly = ~options.IncludeSubfolders;
    messagesModel.configuration = matlab.codeanalyzer.internal.resolveConfigurationFilename(options.CodeAnalyzerConfiguration);
    messagesModel.options.add("-includeSuppression");
    resolveInput(messagesModel, items);
    txn.commit;

    mf0StatusModel = mf.zero.Model();
    statusModel = matlab.codeanalyzer.internal.datamodel.StatusModel(mf0StatusModel);
    if nargin == 0
        statusModel.isApp = true;
    end
    if options.IsCompatibilityReport
        statusModel.grouping = "categoryId";
        statusModel.isCompatibilityReport = true;
    end

    server = matlab.codeanalyzerreport.internal.Server(mf0DataModel, messagesModel, mf0StatusModel, statusModel, source);
end



