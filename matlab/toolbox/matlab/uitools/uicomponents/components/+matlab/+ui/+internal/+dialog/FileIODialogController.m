classdef FileIODialogController < matlab.ui.internal.dialog.DialogController
    %FILEIODIALOGCONTROLLER
    % This controller sends data to the view to create and manage
    % file IO dialogs in deployed web environment.

%   Copyright 2024 The MathWorks, Inc.
    
    properties
        ViewDataFields = {'action','title','filter', 'fileName', 'pathName', 'multiselection','callbackChannelID'};
        FileName = {};
        PathName = '';
        FilterIndex = 0;
        FileACKChannelID = '';
        FileIOChannelID = '';
        FileIOChannelSubscription;
        FileId = [];
    end
    
    properties (Access = private)
        TempFileStruct = {};
        Location = '';
        FileCounter = 0;
        TransactionNo = 0;
        FullPath = '';
    end
    
    methods(Access = public)
        function this = FileIODialogController(params)
            validParams = {'Figure','FigureID','Title','Filter','FileName','PathName','MultiSelection','Action','Theme'};
            this@matlab.ui.internal.dialog.DialogController(params, validParams);
            
            % get path for uploading and downloading files in server
            this.Location = matlab.ui.internal.dialog.FileDialogHelper.getDeployedEnvPath();
            
            % get transaction number
            this.TransactionNo = matlab.ui.internal.dialog.FileDialogHelper.getTransactionNumber();
            % create temporary directory for file upload/download
            this.FullPath = fullfile(this.Location, int2str(this.TransactionNo));
            
            this.ViewData.action = this.ModelProperties.Action;
            this.ViewData.title = this.ModelProperties.Title;
            this.ViewData.filter = this.ModelProperties.Filter;
            this.ViewData.fileName = this.ModelProperties.FileName;
            this.ViewData.pathName = this.Location;
            this.ViewData.multiselection = this.ModelProperties.MultiSelection;
            this.ViewData.theme = this.ModelProperties.Theme;
            
            % channelID for communicating from server to client
            this.FileACKChannelID = [this.ChannelID '/FileChunkACK'];
            this.ViewData.fileACKChannelID = this.FileACKChannelID;
            
            % channelID for communicating from client to server
            this.FileIOChannelID = [this.ChannelID '/HandleFileIO'];
            this.ViewData.fileIOChannelID = this.FileIOChannelID;
        end
    end
    
    methods (Access = protected)
        
        % Function that handle events from view based on its type
        function processEventData(this, evd)
            try
                switch evd.eventType
                    case 'handleClose'
                        this.returnEmptyFile();
                        
                    case 'handleGetFile'
                        % check if the directory exists
                        if(~exist(this.FullPath, 'dir'))
                            mkdir(this.FullPath);
                        end
                        
                        % open file and write data
                        if isempty(this.FileId)
                            this.FileId = fopen(fullfile(this.FullPath, evd.data.name), 'a');
                        end
                        fwrite(this.FileId, uint8(evd.data.contents));
                        
                        % send message to view for file chunk acknowledgement
                        this.ViewData.action = 'handleFileChunkACK';
                        this.ViewData.count = evd.data.count;
                        this.ViewData.fileCounter = this.FileCounter;
                        message.publish(this.FileACKChannelID, this.ViewData);
                        
                        if evd.data.count == evd.data.noOfChunks
                            % close file opened for writing
                            fclose(this.FileId);
                            this.FileId = [];
                            
                            % send message to view for closing file input dialog                    
                            this.ViewData.action = 'handleFileCompleteACK';
                            message.publish(this.FileACKChannelID, this.ViewData);
                            
                            % for multi file selection
                            this.FileCounter = this.FileCounter + 1;
                            this.TempFileStruct{end+1} = evd.data.name;
                            fprintf('%s is uploaded successfully\n', evd.data.name);
                        end
                        
                        if this.FileCounter == evd.data.fileCount
                            % reset counter
                            this.FileCounter = 0;
                            % send message to view for closing file input dialog
                            this.ViewData.action = 'closeFileInputDialog';
                            message.publish(this.ChannelID, this.ViewData);
                            
                            % set transaction number
                            matlab.ui.internal.dialog.FileDialogHelper.setTransactionNumber(this.TransactionNo + 1);
                            
                            % update properties to unblock MATLAB
                            this.updatePropertiesAndDestroy(this.FullPath, 1, this.TempFileStruct);
                        end
                        
                    case 'handlePutFile'
                        % check if the directory exists
                        if(~exist(this.FullPath, 'dir'))
                            mkdir(this.FullPath);
                        end
                        
                        fullFileName = fullfile(this.FullPath, evd.data.fileName);
                        
                        % start fileListener and send file to view once its
                        % ready
                        matlab.ui.internal.dialog.FileDialogHelper.fileListener(fullFileName, this.ChannelID);
                        
                        % set transaction number
                        matlab.ui.internal.dialog.FileDialogHelper.setTransactionNumber(this.TransactionNo + 1);
                        fprintf('Starting download for %s\n', evd.data.fileName);
                                                
                        % update properties to unblock MATLAB
                        this.updatePropertiesAndDestroy(this.FullPath, evd.data.filterIndex, evd.data.fileName);
                end                
            catch ME
                if isequal(evd.eventType, 'handleGetFile')
                    if ~isempty(this.FileId) && this.FileId > 0
                        fclose(this.FileId);
                    end
                    this.ViewData.action = 'closeFileInputDialog';               
                    message.publish(this.ChannelID, this.ViewData);
                end
                this.returnEmptyFile();
                
                fprintf(2, 'Error occurred during upload/download for: %s\n%s\n', evd.data.name, ME.message);
            end
        end
        
        % Function to subscribe message with specific FileIOChannelID
        function setupListeners(this)            
            this.FileIOChannelSubscription = message.subscribe(this.FileIOChannelID, @(evd) this.processEventData(evd));
        end
        
        % Function to unsubscribe message of specific ClientChannelID
        function destroyListeners(this)
            destroyListeners@matlab.ui.internal.dialog.DialogController(this);
            
            message.unsubscribe(this.FileIOChannelSubscription);
        end
    
        function handleReload(this, ~)
            this.returnEmptyFile();
        end        
    end
    
    methods(Access = private)
        % Update properties to unblock MATLAB
        function updatePropertiesAndDestroy(this, pathName, filterIndex, fileName)
            this.IsDisplayed = false;
            this.destroyListeners();
            
            % update properties so that MATLAB gets unblocked
            this.PathName = pathName;
            this.FilterIndex = filterIndex;
            this.FileName = fileName;
        end
        
        function returnEmptyFile(this)            
            this.updatePropertiesAndDestroy('', 0, '');
        end
    end
    
end
