% This class is unsupported and might change or be removed without notice
% in a future version.

% A class defining MATLAB Peer Import Tool

% Copyright 2018-2022 The MathWorks, Inc.

classdef DesktopImportTool < handle

    % Property Definitions:
    properties (Constant)
        ChannelBase = '/ImportTool';
    end

    methods (Access = protected)
        % Constructor
        function this = DesktopImportTool()
            internal.matlab.importtool.peer.PeerImportToolFactory.getInstance();
        end
    end

    % Public Static Methods
    methods (Static, Access = public)
        % getInstance
        function obj = getInstance(varargin)
            mlock; % Keep persistent variables until MATLAB exits
            persistent ImportToolInstance;
            if isempty(ImportToolInstance) || (nargin > 0 && strcmpi(varargin{1}, internal.matlab.importtool.peer.PeerImportToolFactory.ForceNewInstance))
                ImportToolInstance = internal.matlab.importtool.peer.DesktopImportTool();
            end
            obj = ImportToolInstance;
        end

        function startup()
            % Makes sure the ImportToolFactory for the ImportTool exists
            [~] = internal.matlab.importtool.peer.DesktopImportTool.getInstance;
        end

        % Creates Manager instance from PeerImportToolFactory
        function mgr = import(filename, fileType)
            import internal.matlab.importtool.server.ImportUtils;
            import internal.matlab.importtool.peer.DesktopImportTool;
            import internal.matlab.importtool.peer.PeerImportToolFactory;

            if nargin < 1
                error('Please provide a valid data source for import');
            end

            if nargin < 2
                fileType = ImportUtils.getImportType(filename);
            end

            channel = DesktopImportTool.getNextChannel(filename, fileType);
            dataSource = struct("FileName", filename, "ImportType", fileType);
            dataSource.Importer = internal.matlab.importtool.server.ImporterFactory.getImporter(filename, fileType);

            factory = PeerImportToolFactory.getInstance();
            factory.CreateActionsSynchronous = true;
            mgr = factory.createManagerInstance(channel, dataSource);
        end

        function channel = getNextChannel(dataSource, fileType)
            % Returns a char array, which is the channel name to use for the
            % given file name (dataSource)

            arguments
                dataSource char
                fileType char
            end

            [~, fname, ext] = fileparts(dataSource);

            % Use a ReplacementStyle of hex, so that non-English filenames still
            % result in unique channel names.
            nameSpace = matlab.lang.makeUniqueStrings(...
                matlab.lang.makeValidName(fname, "ReplacementStyle", "hex"), ...
                {}, namelengthmax);

            % add 'text' to the end of channel so to fix the problem of
            % two same name files with different type spreadsheet and text
            if strcmp(fileType, 'text')
                channel = [internal.matlab.importtool.peer.DesktopImportTool.ChannelBase ...
                    '_' char(nameSpace) '_' char(strrep(ext, ".", "")) '_' char(fileType)];
            else
                channel = [internal.matlab.importtool.peer.DesktopImportTool.ChannelBase ...
                    '_' char(nameSpace) '_' char(strrep(ext, ".", ""))];
            end
        end
    end
end
