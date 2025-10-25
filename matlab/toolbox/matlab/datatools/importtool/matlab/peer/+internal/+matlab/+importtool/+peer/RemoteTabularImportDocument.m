% This class is unsupported and might change or be removed without notice
% in a future version.

% This class is the Remote Document objet for import.

% Copyright 2022 The MathWorks, Inc.

classdef RemoteTabularImportDocument < internal.matlab.variableeditor.Document

    properties
        DocID;
        Provider;
    end

    methods
        function this = RemoteTabularImportDocument(manager, variable, docID, documentArgs)
            arguments
                manager
                variable
                docID char
                documentArgs.UserContext char = ''
                documentArgs.DisplayFormat = ''
            end
            args = namedargs2cell(documentArgs);
            this = this@internal.matlab.variableeditor.Document(manager, variable.DataModel, variable.ViewModel, args{:});
            this.DocID = docID;
            this.Provider = manager.Provider;
            sheetSize = variable.DataModel.getSheetDimensions();
            fileIdentifier = variable.DataModel.FileImporter;
            documentInfo = struct(...
                "containerType", fileIdentifier.Identifier, ...
                "dataSource", variable.DataSource.FileName,...
                "docID", docID,...
                "size", [sheetSize(2), sheetSize(4)]);

            if strlength(fileIdentifier.TableIdentifier)
                % TODO - change sheetName to tableIdentifier
                documentInfo.sheetName = fileIdentifier.TableIdentifier;
            end
            this.Provider.addDocument(docID, documentInfo);

            this.DataModel = variable.getDataModel();
            this.ViewModel = variable.getViewModel(this);
        end

        function data = variableChanged(~, varargin)
            %no-op
            data = [];
        end

        function handleEventFromClient(this, ~, ed)
            if startsWith(ed.data.type, "set")
                stateSetting = extractAfter(ed.data.type, "set");
                this.ViewModel.DataModel.setState(stateSetting, ed.data);
            end
        end
    end
end
