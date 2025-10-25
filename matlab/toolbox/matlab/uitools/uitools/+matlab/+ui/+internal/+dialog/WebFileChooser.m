classdef WebFileChooser < matlab.ui.internal.dialog.MATLABBlocker
    % WEBFILECHOOSER. The purpose of
    % this class is to perform additional validations to file dialog functions like
    % uigetfile, uigetdir etc. It also contains logic to block MATLAB when file dialogs are
    % shown.

    % Copyright 2022 The MathWorks, Inc.

    properties(Access = 'private')        
        FileChooserInstance;
    end

    methods
        function obj = WebFileChooser()
            fileChooser = matlab.ui.internal.dialog.FileDialogHelper.setupFileChooser;
            obj.FileChooserInstance = fileChooser();

            obj.FileChooserInstance.addlistener('SelectionComplete', @(s, e) unblockMATLAB(obj));
        end

        function setDialogTitle(obj, title)
            matlab.ui.internal.dialog.FileDialogHelper.validateTitle(title);
            obj.FileChooserInstance.setDialogTitle(title);
        end

        function setMultiSelection(obj, value)
            matlab.ui.internal.dialog.FileDialogHelper.validateMultiSelection(value);
            obj.FileChooserInstance.setMultiSelection(value);
        end

        function setFileName(obj, fname)
            fileName = matlab.ui.internal.dialog.FileDialogHelper.validateFileName(fname);
            obj.FileChooserInstance.setFileName(fileName);
        end

        function setDirectoryWithFileName(obj, pathName)
            directoryPath = matlab.ui.internal.dialog.FileDialogHelper.validatePathName(pathName);
            % Update pathname based on filename given
            [directoryPath, fileName] = matlab.ui.internal.dialog.FileDialogHelper.updatePathName(directoryPath , obj.FileChooserInstance.fileName);
            obj.setDirectory(directoryPath);
            obj.setFileName(fileName);
        end

        function setDirectory(obj, fpath)
            filePath = matlab.ui.internal.dialog.FileDialogHelper.validatePathName(fpath);
            obj.FileChooserInstance.setDirectory(filePath);
        end

        function path = getFilePath(obj, trailingSep)
            arguments
                obj
                trailingSep (1,1) logical = true
            end

            path = obj.FileChooserInstance.getFilePath();

            if (isempty(path))
                path = 0;
            else
                % non-empty path should be a cell arr containing directories of the selected
                % files. Selecting files from multiple directories is not supported.
                if (iscell(path) && length(unique(path)) == 1)
                    path = path{1};
                    % By default, the trailing file separator is added,
                    % unless trailingSep is declared "false", like in uigetdir
                    if (trailingSep && ~isequal(path(end), filesep))
                        path = [path, filesep];
                    end
                end
            end
        end

        function fileName = getFileName(obj)
            fileName = obj.FileChooserInstance.getFileName();
        end

        function filterIndex = getFileTypeFilterIndex(obj)
            filterIndex = obj.FileChooserInstance.getFileTypeFilterIndex();
        end

        function showDialog(obj, fileTypeFilters, dialogType)
            %SHOWDIALOG calls super class methods to show the file dialog.
            %The dialogType arg accepts values 0, 1 or 2. 
            % 0 - open file dialog
            % 1 - save file dialog
            % 2 - open directory dialog
            if (dialogType == 2)
                obj.FileChooserInstance.showOpenDirDialog();
            else
                obj.FileChooserInstance.fileTypeFilters = matlab.ui.internal.dialog.FileDialogHelper.getFileExtensionFiltersWeb(fileTypeFilters, dialogType);
                if (dialogType == 0)
                    obj.FileChooserInstance.showOpenFileDialog();
                elseif (dialogType == 1)
                    obj.FileChooserInstance.showSaveFileDialog();
                end
            end
            obj.blockMATLAB();
            obj.reshowDialogs(dialogType);
        end

        
    end

    methods(Access=private)
        % Function to reshow file dialog when files from multiple paths are
        % selected by user.
        %
        % If multiple files are selected from different folders then show 
        % an error dialog and reshow the open dialog 
        % Applies to libraries on Windows and also applies to List/CoverFlow 
        % view on the Mac dialog - see g803695 for more information
        function reshowDialogs(obj, dialogType)
            if (obj.FileChooserInstance.multiSelection)
                 filepaths = obj.getFilePath;
                 while (iscell(filepaths) && length(unique(filepaths)) >= 2)
                    uiwait(warndlg(getString(message('MATLAB:AbstractFileDialog:MultipleFoldersSelected')), ...
                        getString(message('MATLAB:AbstractFileDialog:InvalidSelection')), ...
                        'modal'));
                    % show dialog based on type
                    if dialogType == 0
                        obj.FileChooserInstance.showOpenFileDialog();
                    else
                        obj.FileChooserInstance.showSaveFileDialog();
                    end
                 end
            end
        end
    end
end