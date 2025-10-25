% This class is unsupported and might change or be removed without notice in a
% future version.

% This class is the factory for creating Importer classes per file type

% Copyright 2022 The MathWorks, Inc.

classdef ImporterFactory

    methods(Static)
        function importer = getImporter(varargin)
            dataSource = [];
            importType = [];
            tableIdentifier = [];
            if nargin == 1
                if class(varargin{1}) == "struct"
                    dataSource = varargin{1};
                    if isfield(dataSource, "ImportType")
                        importType = dataSource.ImportType;
                    elseif isfield(dataSource, "Type")
                        importType = dataSource.Type;
                    end

                    if isempty(importType)
                        importType = finfo(char(dataSource.FileName));
                    end
                elseif class(varargin{1}) == "string" || class(varargin{1}) == "char"
                    % Input argument is a file name only
                    filename = varargin{1};
                    importType = finfo(char(filename));
                end
            elseif nargin == 2
                filename = varargin{1};
                importType = varargin{2};
            elseif nargin == 3
                filename = varargin{1};
                importType = varargin{2};
                tableIdentifier = varargin{3};
            end

            if isempty(dataSource)
                dataSource.FileName = filename;
                dataSource.ImportType = importType;
            end

            switch(importType)
                case "spreadsheet"
                    if ~isfield(dataSource, "SheetName") && ~isempty(tableIdentifier)
                        dataSource.SheetName = tableIdentifier;
                    end
                    importer = internal.matlab.importtool.server.SpreadsheetFileImporter(dataSource);

                otherwise
                    importer = internal.matlab.importtool.server.TextFileImporter(dataSource);
            end
        end
    end
end