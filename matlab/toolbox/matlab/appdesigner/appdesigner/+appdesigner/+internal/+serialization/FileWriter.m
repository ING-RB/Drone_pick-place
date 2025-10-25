classdef FileWriter < handle
    %FILEWRITER Create a file writer for AppDesigner files
    %
    %   obj = FileWriter(FILENAME) constructs a FileWriter object to write
    %   AppDesigner specific files.
    %
    % Methods:
    %   writeMLAPPFile          - Writes a MLAPP file with the AppDesigner
    %                             specific information, metadata, and
    %                             MATLAB code text
    %   writeAppScreenshot      - Appends the file with app screenshot
    %
    %   copyAppFromFile          - Copies the the specified app file
    %
    %   The following methods are not recommended and should be avoided
    %   going forward.  Use 'writeMLAPPFile' to write the full file
    %   in one go instead.
    %
    %   writeMATLABCodeText     - Creates the file and writes the MATLAB
    %   code to the file
    %   writeAppDesignerData    - Appends the file with the AppDesigner
    %                             specific information
    %
    %   writeAppMetadata        - Appends the file with metadata for the
    %                             app (Name, Summary, Description,
    %                             ScreenshotMode, MLAPPVersion,
    %                             MATLABRelease, MinimumSupportedMATLABRelease)
    %
    % Properties:
    %   FileName            - String specifying path and name of file
    %   DefaultExtension   - Extension of AppDesigner files
    %
    % Example:
    %
    %   % Create FileWriter object
    %   fileWriter = FileWriter('myApp.mlapp');
    %
    %   % Write MATLAB code, app data, and metadata to the file
    %   writeMLAPPFile(fileWriter, matlabCodeText, appDataToSerialize, appMetadata)

    % Copyright 2013-2024 The MathWorks, Inc.

    properties (Access = private)
        DefaultExtension = '.mlapp';
    end

    properties
        FileName;
    end

    methods

        function obj = FileWriter(fileName)
            narginchk(1, 1);
            validateattributes(fileName, ...
                {'char'}, ...
                {});
            obj.FileName = fileName;
            obj.validateFileExtensionForWrite();
            obj.validateFileName();
        end

        function createOrOverwriteTargetFile(obj)
            % CREATEOROVERWRITETARGETFILE creates or overwrites a MLAPP OPC
            % package at the target location.

            [~, name, ext] = fileparts(obj.FileName);

            % Validate basic features of file location
            obj.validateFileExtensionForWrite();
            obj.validateFileForWrite();
            obj.validateFolderForWrite();

            try
                % Create the file from scratch or overwrite the existing
                % file at the passed location
                appdesigner.internal.serialization.initializeEmptyFile(...
                    obj.FileName);
            catch me
                error(message('MATLAB:appdesigner:appdesigner:SaveFailed', [name, ext]));
            end

            % Check if file was created
            if exist(obj.FileName, 'file') ~= 2, ...
                error(message('MATLAB:appdesigner:appdesigner:SaveFailed', [name, ext]));
            end
        end

        function writeAppDesignerDataVersion1(obj, matlabCodeText, appData, appMetadata)
            % WRITEAPPDESIGNERDATAVERSION1 This function writes the
            % version 1 format of one AppData object to the mat file.
            % appData - the App Designer data to serialize
            % matlabCodeText - the code to serialize
            % appMetadata - the MLAPP-file metadata to write

            [~, name, ext] = fileparts(obj.FileName);

            % Data will be saved using MATLAB to a temporary file, then
            % written to the AppDesigner from that file

            tempMATFileLocation = [tempname, '.mat'];

            % Save the data to a temporary .mat file
            save(tempMATFileLocation,'appData');

            % The temporary file will need to be deleted after read
            c = onCleanup(@()delete(tempMATFileLocation));

            % Check basic features of file location
            obj.validateFileExtensionForWrite();
            obj.validateFileForWrite();
            obj.validateFolderForWrite();

            % write contents of mat file into MLAPP file
            try
                appdesigner.internal.serialization.writeAppToFile(...
                    obj.FileName, tempMATFileLocation, matlabCodeText, appMetadata);
            catch me
                error(message('MATLAB:appdesigner:appdesigner:SaveFailedAppData', [name, ext]));
            end
        end

         function writeMLAPPFile(obj, matlabCodeText, appDataToSerialize, appMetadata)
            % WRITEMLAPPFILE writes the full MLAPP file from its parts.
            % These parts are:
            %   - matlabCodeText: the full code of the app class, to be
            %   executed when the app runs
            %   - appDataToSerialize: App Designer's specific data to
            %     write.  This consists of three parts:
            %       components - a structure with the following fields:
            %         UIFigure, Groups
            %       code - a structure of code related data with the
            %         following fields: ClassName, Callbacks,
            %           StartupCallback, EditableSectionCode
            %       appData - the legacy App Designer data to serialize.
            %         This must be called appData for forward compatibility
            %  - metadata: the information specific to the MLAPP file, such
            %    as its file format, the MinimumSupportedMATLABRelease,
            %    etc.  For more info see
            %    appdesigner.internal.model.MetadataModel

            [~, name, ext] = fileparts(obj.FileName);

            % Data will be saved using MATLAB to a temporary file, then
            % written to the AppDesigner from that file

            tempMATFileLocation = [tempname, '.mat'];

            % Save the data to a temporary .mat file
            % the fields in the 'appDataToSerialize' structure will be the
            % variables in the mat file
            % note: you will get a warning if Figure.Visible is set to
            % 'on', it must be set to 'off'.
            save(tempMATFileLocation,'-struct','appDataToSerialize');

            % The temporary file will need to be deleted after read
            c = onCleanup(@()delete(tempMATFileLocation));

            % Check basic features of file location
            obj.validateFileExtensionForWrite();
            obj.validateFileForWrite();
            obj.validateFolderForWrite();

            % write contents of mat file into MLAPP file
            try
                appdesigner.internal.serialization.writeAppToFile(obj.FileName, tempMATFileLocation, matlabCodeText, appMetadata);
                % Notify the Path Manager that the file has been saved to
                % disk and its contents may be updated.
                fschange(obj.FileName);
                rehash;

            catch me
                error(message('MATLAB:appdesigner:appdesigner:SaveFailedAppData', [name, ext]));
            end

            % Check if file was created
            if exist(obj.FileName, 'file') ~= 2, ...
                error(message('MATLAB:appdesigner:appdesigner:SaveFailed', [name, ext]));
            end
        end

        function writeAppCodeData(obj, matlabCodeText, appDataToSerialize, appMetadata)
            % WRITEAPPCODEDATA writes the MLAPP file from its parts.
            % Note: Do not support version 1 MLAPP file
            % These parts are:
            %   - matlabCodeText: the full code of the app class, to be
            %   executed when the app runs
            %   - appDataToSerialize: App Designer's specific data to
            %     write.  This consists of one part:
            %       code - a structure of code related data with the
            %         following fields: ClassName, Callbacks,
            %           StartupCallback, EditableSectionCode
            %  - metadata: the information specific to the MLAPP file, such
            %    as its file format, the MinimumSupportedMATLABRelease,
            %    etc.  For more info see
            %    appdesigner.internal.model.MetadataModel

            import appdesigner.internal.serialization.app.AppVersion;

            [~, name, ext] = fileparts(obj.FileName);


            % Data will be saved using MATLAB to a temporary file, then
            % written to the AppDesigner from that file

            % Exact mat file to a temporary file from MLAPP file
            [tempMATFileLocation, cleanupObj] = appdesigner.internal.serialization.util.extractMATFile(obj.FileName);

            % writeAppCodeData are only used by mlapp merge tool which currently only support merge 
            % user editable code for current MATLAB release.  So no need support writing code data 
            % for version 1 MLAPP file.
            % Check if the file was version 1 file which is not supported to write code data only
            mlappVersion = appdesigner.internal.serialization.util.inferMLAPPVersion(tempMATFileLocation);
            if mlappVersion == AppVersion.MLAPPVersionOne
                error(message('MATLAB:appdesigner:appdesigner:SaveFailedAppData', [name, ext]));
            end

            % Save the app code data to a temporary .mat file with append to override code data
            save(tempMATFileLocation,'-struct','appDataToSerialize','-append');

            % Check basic features of file location
            obj.validateFileExtensionForWrite();
            obj.validateFileForWrite();
            obj.validateFolderForWrite();

            % write contents of mat file into MLAPP file
            try
                appdesigner.internal.serialization.writeAppToFile(obj.FileName, tempMATFileLocation, matlabCodeText, appMetadata);
                % Notify the Path Manager that the file has been saved to
                % disk and its contents may be updated.
                fschange(obj.FileName);
                rehash;

            catch me
                error(message('MATLAB:appdesigner:appdesigner:SaveFailedAppData', [name, ext]));
            end

            % Check if file was created
            if exist(obj.FileName, 'file') ~= 2, ...
                error(message('MATLAB:appdesigner:appdesigner:SaveFailed', [name, ext]));
            end
        end

        function  writeAppScreenshot(obj, screenshot)
            % WRITEAPPSCREENSHOT writes the app's screenshot
            %   screenshot - cdata (3D RGB) matrix | file path to image
            %                of format: 'png', 'jpg', 'jpeg', or 'gif'

            [~, name, ext] = fileparts(obj.FileName);

            % Validate basic features of file location
            obj.validateFileExtensionForWrite();
            obj.validateFileForWrite();
            obj.validateFolderForWrite();

            imageFormat = 'png';
            if isempty(screenshot)
                error(message('MATLAB:appdesigner:appdesigner:SaveFailedAppScreenShot', [name, ext]));
            end

            try
                % Convert to uint8 byte array
                if ischar(screenshot)
                    % screenshot is full file path to image
                    [bytes, imageFormat] = appdesigner.internal.application.ImageUtils.getBytesFromImageFile(screenshot);
                else
                    dataSize = size(screenshot);
                    if numel(dataSize) == 3
                        % screenshot is cdata (3d RGB) matrix
                        bytes = appdesigner.internal.application.ImageUtils.getBytesFromCDataRGB(screenshot, imageFormat);
                    else
                        % it's already uint8 byte array
                        bytes = screenshot;
                    end
                end

                % Try to write screenshot to file.
                % Call to builtin function.
                appdesigner.internal.serialization.setAppScreenshot(obj.FileName, bytes, imageFormat);
            catch me
                error(message('MATLAB:appdesigner:appdesigner:SaveFailedAppScreenShot', [name, ext]));
            end
        end

        function copyAppFromFile(obj, copyFromFullFileName)
            % COPYAPPFROMFILE - copies the app file from the specified file
            %
            % Note that this does NOT update the class name in the code for
            % the new file to match the copy to filename. It performs a
            % naive, straight copy. Also, the copy will be writable even if
            % the original is not so that a save can be performed on top of
            % the copy.

            obj.validateFileForWrite();
            obj.validateFolderForWrite();

            try
                % Use 'f' mode to force saving since MATLAB fileattrib will
                % regard the folder as read-only wrongly. See g1748019 and
                % g779540 for more information
                copyfile(copyFromFullFileName, obj.FileName, 'f');

                % Make file writable after performing the copy so that it
                % can be saved on top of if necssary.
                fileattrib(obj.FileName,'+w')
            catch exception
                if  ~exist(copyFromFullFileName, 'file')
                    error(message('MATLAB:appdesigner:appdesigner:MissingFile', copyFromFullFileName));
                else
                    throwAsCaller(exception);
                end
            end
        end

    end

    methods (Access = private)

        function obj = validateFileName(obj)
            % this function validates the file name is a valid variable
            % name
            [~, appName] = fileparts(obj.FileName);

            if ~isvarname(appName)
                error(message('MATLAB:appdesigner:appdesigner:FileNameFailsIsVarName', appName, namelengthmax));
            end
        end

        function obj = validateFileExtensionForWrite(obj)
            % This function confirms that the file extension is consistent
            % with the default

            obj.FileName = ...
                appdesigner.internal.serialization.util.appendFileExtensionIfNeeded(obj.FileName);
            appdesigner.internal.serialization.util.validateAppFileExtension(obj.FileName);
        end

        function obj = validateFileForWrite(obj)
            [~, name, ext] = fileparts(obj.FileName);

            % Check if file already exists and is readonly
            % Using fileattrib instead of exists because exists has issues
            % with case sensitivity on linux (see g1527720)
            [success, fileAttributes] = fileattrib(obj.FileName);
            if success
                if ~fileAttributes.UserWrite
                    error(message('MATLAB:appdesigner:appdesigner:ReadOnlyFile', [name, ext]));
                end
            end
        end

        function obj = validateFolderForWrite(obj)
            path = fileparts(obj.FileName);

            % Assert that the path exists
            [success, ~] = fileattrib(path);
            if ~success
                error(message('MATLAB:appdesigner:appdesigner:NotWritableLocation', obj.FileName));
            end


            % create a random folder name so no existing folders are affected
            randomNumber = floor(rand*1e12);
            testDirPrefix = 'appDesignerTempData_';
            testDir = [testDirPrefix, num2str(randomNumber)];
            while exist(testDir, 'dir')
                % The folder name should not match an existing folder
                % in the directory
                randomNumber = randomNumber + 1;
                testDir = [testDirPrefix, num2str(randomNumber)];
            end

            % Attempt to write a folder in the save location
            [isWritable,~,~] = mkdir(path, testDir);
            if ~isWritable
                error(message('MATLAB:appdesigner:appdesigner:NotWritableLocation', obj.FileName));
            end

            [status,~,~] = rmdir(fullfile(path, testDir), "s");
            if status ~=1
                warning(['Temporary folder %s could not be ', ...
                    'deleted.  Please delete manually.'], ...
                    fullfile(path, testDir) )
            end
        end
    end

    methods (Static, Access = private)
        function correctVersion = validateVersion(version)
            % Ensure that version is a string and matches the correct format.
            pattern = '^[0-9]+\.[0-9]+';

            if ~ischar(version) || isempty(regexp(version, pattern, 'ONCE'))
                correctVersion = '1.0';
            else
                correctVersion = version;
            end
        end
    end

    % Not recommended, do not use to write a full MLAPP file.  These
    % methods can be used in the case where only one piece of the MLAPP
    % file should be written.
    methods
         function writeMATLABCodeText(obj, matlabCode)
            % WRITEMATLABCODETEXT writes MATLAB code and stores it in the
            % AppDesigner file as a string
            % matlabcode - MATLAB code to write to the AppDesigner file

            [~, name, ext] = fileparts(obj.FileName);

            % Validate basic features of file location
            obj.validateFileExtensionForWrite();
            obj.validateFileForWrite();
            obj.validateFolderForWrite();

            % Create file and write MATLAB code to file
            try
                appdesigner.internal.serialization.setMATLABCodeText(obj.FileName, matlabCode);

                % Notify the Path Manager that the file has been saved to
                % disk and its contents may be updated.
                fschange(obj.FileName);
                rehash;
            catch me
                error(message('MATLAB:appdesigner:appdesigner:SaveFailedMATLABCode', [name, ext]));
            end

            % Check if file was created
            if exist(obj.FileName, 'file') ~= 2, ...
                error(message('MATLAB:appdesigner:appdesigner:SaveFailed', [name, ext]));
            end

         end

         function writeAppMetadata(obj, metadata)
             % WRITEAPPMETADATA writes the metadata about the app
             %   metadata - struct with metadata to write to the app. Fields
             %              include:
             %                Name - char vector name of the app
             %                Author - char vector author of the app
             %                Version - char vector version of the app
             %                Summary - char vector summary of the app
             %                Description - char vector description of app
             %                ScreenshotMode - 'auto' | 'manual' - signifies
             %                   if the user has manually selected screenshot
             %                MLAPPVersion - '1' (for 16a-17b), '2' (for 18a+)
             %                MATLABRelease - Rxxxx(a|b) release of MATLAB
             %                MinimumSupportedMATLABRelease - 'R2016a'
             %                  (for 16a-17b), 'R2018a' (for 18a+)
             %
             %               All fields are optional. Only writes/overrrides
             %               the app metadata of the fields specified.

             [~, name, ext] = fileparts(obj.FileName);

             % Validate basic features of file location
             obj.validateFileExtensionForWrite();
             obj.validateFileForWrite();
             obj.validateFolderForWrite();

             try
                 if isfield(metadata, 'Version')
                     metadata.Version = obj.validateVersion(metadata.Version);
                 end

                 % Call to builtin function
                 appdesigner.internal.serialization.setAppMetadata(obj.FileName, metadata);
             catch me
                 error(message('MATLAB:appdesigner:appdesigner:SaveFailedAppMetaData', [name, ext]));
             end
         end

         function writeAppDesignerData(obj, appDataToSerialize)
             % WRITEAPPDESIGNERDATA writes the AppDesigner specific data
             % from  AppDesigner
             % components - a structure with the following fields: UIFigure, Groups
             % code - a structure of code related data with the following
             % fields: ClassName, Callbacks, StartupCallback,
             % EditableSectionCode
             % appData - the legacy App Designer data to serialize.  This
             % must be called appData for forwards compatibility

             [~, name, ext] = fileparts(obj.FileName);

             % Data will be saved using MATLAB to a temporary file, then
             % written to the AppDesigner from that file

             tempMATFileLocation = [tempname, '.mat'];

             % Save the data to a temporary .mat file
             % the fields in the 'appDataToSerialize' structure will be the
             % variables in the mat file
             save(tempMATFileLocation,'-struct','appDataToSerialize');

             % The temporary file will need to be deleted after read
             c = onCleanup(@()delete(tempMATFileLocation));

             % Check basic features of file location
             obj.validateFileExtensionForWrite();
             obj.validateFileForWrite();
             obj.validateFolderForWrite();

             % write contents of mat file into MLAPP file
             try
                 appdesigner.internal.serialization.setAppDataFromMATFile(obj.FileName, tempMATFileLocation);
             catch me
                 error(message('MATLAB:appdesigner:appdesigner:SaveFailedAppData', [name, ext]));
             end
        end
    end
end
