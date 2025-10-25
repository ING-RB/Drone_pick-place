% This class is unsupported and might change or be removed without notice
% in a future version.

% Extends the ImportToolManager to provide a manager class for importing, by
% opening and managing the JS Import Tool from Matlab.

% Copyright 2019-2024 The MathWorks, Inc.

classdef TextImportToolManager < internal.matlab.importtool.peer.ImportToolManager
    
    properties(Constant)
        TEXT_IMPORT_TYPE = "text";
    end
    
    methods(Static)
        function textITManager = getInstance(varargin)
            import internal.matlab.importtool.peer.TextImportToolManager;
            
            if nargin == 1
                appName = varargin{1};
            else
                appName = "";
            end
            
            textITManager = TextImportToolManager.getSetInstances(appName, []);
        end
        
        function textITManager = getSetInstances(appName, instance)
            import internal.matlab.importtool.peer.TextImportToolManager;
            
            mlock;  % Keep persistent variables until MATLAB exits
            
            persistent textITManagers;
            if isempty(textITManagers)
                textITManagers = containers.Map();
            end
            
            textITManager = [];
            if isKey(textITManagers, appName) && isempty(instance)
                textITManager = textITManagers(appName);
            end
            
            if isempty(textITManager) || ~isvalid(textITManager)
                if isempty(instance)
                    textITManager = TextImportToolManager(appName);
                else
                    textITManager = instance;
                end
                
                textITManagers(char(appName)) = textITManager;
            end
        end
        
        function textImport(filename, debug, varargin)
            import internal.matlab.importtool.peer.TextImportToolManager;
            
            if nargin == 3
                channel = varargin{1};
            else
                channel = TextImportToolManager.DebugChannel;
            end
            
            itm = TextImportToolManager.getInstance(channel);
            itm.initializeAndImportFile(filename, ...
                struct("Debug", debug, ...
                "ImportType", TextImportToolManager.TEXT_IMPORT_TYPE, ...
                "AppName", channel));
        end
        
        function s = getSnc()
            import internal.matlab.importtool.peer.TextImportToolManager;
            
            % Get the nonce to use for the Import Tool.  This needs to be
            % reused for a given page, especially in Matlab Online.
            mlock;
            persistent snc;
            
            if isempty(snc) 
                snc = connector.newNonce;
                message.subscribe("/Import", @(evt) TextImportToolManager.handleMessage(evt), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
            end
            
            s = snc;
        end
        
        function handleMessage(eventData)
            import internal.matlab.importtool.peer.TextImportToolManager;

            if isequal(eventData.importType, TextImportToolManager.TEXT_IMPORT_TYPE)
                textITManager = TextImportToolManager.getInstance(eventData.channel);
                textITManager.initializeAndImportFile(eventData.filename, ...
                    struct("Debug", eventData.debug, ...
                    "ImportType", eventData.importType, ...
                    "AppName", eventData.channel));
            end
        end
    end
   
    methods
        function this = TextImportToolManager(appName)
            this@internal.matlab.importtool.peer.ImportToolManager();
            this.ImportType = this.TEXT_IMPORT_TYPE;
            this.ProgressMessageText = getString(message(...
                "MATLAB:codetools:importtool:ProgressMessageTextFile"));
            this.InitialWidth = 1080;
            this.TitleTag = "MATLAB:codetools:importtool:TextImportTitle";
            this.AppName = appName;
            this.Snc = internal.matlab.importtool.peer.TextImportToolManager.getSnc;
        end
    end

    methods(Access = protected)
        function [c, opts, outputType] = getGeneratedCodeAndOpts(~, vm, excelSelection, outputVarName)
            [opts, dataLines, outputType] = vm.getImportOptions(excelSelection);
            tcg = internal.matlab.importtool.server.TextCodeGenerator(false);
            c = tcg.generateScript(opts, ...
                "Filename", vm.DataModel.FileImporter.FileName, ...
                "DataLines", dataLines, ...
                "VarName", outputVarName, ...
                "OutputType", outputType, ...
                "DefaultTextType", internal.matlab.importtool.server.ImportUtils.getSetTextType);
        end
    end
end
