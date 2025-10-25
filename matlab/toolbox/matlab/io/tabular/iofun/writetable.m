function writetable(T,filename,varargin)

import matlab.io.internal.interface.suggestWriteFunctionCorrection
import matlab.io.internal.interface.validators.validateWriteFunctionArgumentOrder
import matlab.io.internal.vfs.validators.validateCloudEnvVariables;
import matlab.internal.datatypes.validateLogical

if nargin == 0
    error(message("MATLAB:minrhs"));
elseif nargin == 1
    tablename = inputname(1);
    if isempty(tablename)
        tablename = "table";
    end
    filename = tablename + ".txt";
end

validateWriteFunctionArgumentOrder(T, filename, "writetable", "table", @istable);

if ~istable(T)
    suggestWriteFunctionCorrection(T, "writetable");
end

[T, filename, varargin{:}] = convertStringsToChars(T,filename,varargin{:});

if isempty(filename) || ~ischar(filename)
    error(message("MATLAB:virtualfileio:path:cellWithEmptyStr","FILENAME"));
end

if ~isfile(filename)
    % Don't try to create files with leading/trailing spaces.
    % If one happens to exist, we should still use that info
    % and not strip the spaces.
    try
        filename = strip(filename);
    catch
        % Let errors pick this up later.
    end
end

% second input is not really optional with NV-pairs.
if nargin > 2 && mod(nargin,2) > 0
    error(message("MATLAB:table:write:NoFileNameWithParams"));
end

try
    if nargin < 2 || isempty(filename)
        type = "text";
        tablename = inputname(1);
        if isempty(tablename)
            tablename = class(T);
        end
        filename = tablename +".txt";
        suppliedArgs = {"WriteVariableNames",true,"WriteRowNames",false};
    else
        pnames = {'FileType'};
        dflts =  {   [] };
        [type,supplied,suppliedArgs] = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});
        [~,name,ext] = fileparts(filename);

        isThisAGoogleSheet = matlab.io.internal.common.validators.isGoogleSheet(filename);
        % Don't error for Google Sheets if fileparts is unable to identify name
        if isempty(name) && ~isThisAGoogleSheet
            error(message("MATLAB:table:write:NoFilename"));
        end
        if isThisAGoogleSheet && (~supplied.FileType || (supplied.FileType ...
                && strcmpi(type, "spreadsheet")))
            ext = "";
            type = 'gsheet';
        elseif ~supplied.FileType || (ischar(type) && strcmp(type, "auto"))
            if isempty(ext)
                ext = ".txt";
                filename = filename + ext;
            end
            switch lower(ext)
                case {'.txt' '.dat' '.csv'}, type = 'text';
                case {'.xls' '.xlsx' '.xlsb' '.xlsm' '.xltx' '.xltm'}, type = 'spreadsheet';
                case {'.xml'}, type = 'xml';
                otherwise
                error(message("MATLAB:table:write:UnrecognizedFileExtension",ext));
            end
        elseif ~ischar(type) && ~(isstring(type) && isscalar(type))
            error(message("MATLAB:textio:textio:InvalidStringProperty","FileType"));
        else
            fileTypes = {'text' 'spreadsheet' 'xml'};
            itype = find(strncmpi(type,fileTypes,strlength(type)));
            if isempty(itype)
                error(message("MATLAB:table:write:UnrecognizedFileType",type));
            elseif ~isscalar(itype)
                error(message("MATLAB:table:write:AmbiguousFileType",type));
            end
            type = fileTypes{itype};
            % Add default extension if necessary
            if isempty(ext)
                dfltFileExts = {'.txt' '.xls', '.xml'};
                ext = dfltFileExts{itype};
                filename = [filename ext];
            end
        end
    end

    % check whether URL is valid
    validURL = matlab.io.internal.vfs.validators.isIRI(char(filename));
    if validURL && type~="gsheet"
        % check whether scheme is http/s
        P = matlab.io.internal.filesystem.Path(filename);
        if any(lower(P.Type) == ["http", "https"])
            error(message("MATLAB:virtualfileio:stream:writeNotAllowed"));
        end
    end

    if type == "text" || any(type == ["spreadsheet" "gsheet"])
        % Check WriteMode to determine whether the file should be
        % appended or overwritten
        pnames = {'WriteMode','WriteVariableNames','WriteRowNames'};
        if type == "text"
            dflts =  {'overwrite',true,false};
            validModes = ["overwrite","append"];
        else
            dflts = {'inplace',true,false};  % validation of WriteMode values
            validModes = ["inplace","overwritesheet","append","replacefile"];
        end
        [sharedArgs.WriteMode, sharedArgs.WriteVarNames, sharedArgs.WriteRowNames, ...
            supplied, remainingArgs]...
            = matlab.internal.datatypes.parseArgs(pnames, dflts, suppliedArgs{:});

        sharedArgs.WriteMode = validatestring(sharedArgs.WriteMode,validModes);
        sharedArgs.WriteRowNames = validateLogical(sharedArgs.WriteRowNames, ...
                                                    "WriteRowNames") && ~isempty(T.Properties.RowNames);
        sharedArgs.WriteVarNames = validateLogical(sharedArgs.WriteVarNames, ...
                                                    "WriteVariableNames");

        % Setup LocalToRemote object with a remote folder.
        % check if the file exists remotely, we need to download since we
        % will append to file
        if type == "spreadsheet" && any(sharedArgs.WriteMode == ...
                                        ["inplace", "append", "overwritesheet"])
            try
                remote2Local = matlab.io.internal.vfs.stream.RemoteToLocal(filename);
                tempFile = remote2Local.LocalFileName;
            catch ME
                if contains(ME.identifier,"EnvVariablesNotSet")
                    throwAsCaller(ME);
                elseif ME.identifier == "MATLAB:virtualfileio:stream:unableToOpenStream"
                    throwAsCaller(ME);
                end
                remote2Local = [];
                tempFile = filename;
            end
        end

        if validURL
            % remote write for spreadsheets
            if type == "spreadsheet"
                filenameWithoutPath = matlab.io.internal.vfs.validators.IRIFilename(filename);
                remoteFolder = extractBefore(filename,filenameWithoutPath);
                ext = strfind(filenameWithoutPath,".");
                if ~isempty(ext)
                    index = ext(end)-1;
                    ext = extractAfter(filenameWithoutPath,index);
                    filenameWithoutPath = extractBefore(filenameWithoutPath,index+1);
                end
                ltr = matlab.io.internal.vfs.stream.LocalToRemote(remoteFolder);
                if ~isempty(remote2Local) && any(type == ["spreadsheet","text"])
                    % file exists in remote location, append to file
                    ltr.CurrentLocalFilePath = tempFile;
                    ltr.setRemoteFileName(filenameWithoutPath, ext);
                else
                    % file does not exist in remote location
                    setfilename(ltr,filenameWithoutPath,ext);
                end
                fname = ltr.CurrentLocalFilePath;
                validateRemotePath(ltr);
            else
                % text files now have native cloud access support
                fname = filename;
            end
        elseif matlab.io.internal.vfs.validators.hasIriPrefix(filename) && ~validURL
            % possibly something wrong with the URL such as a malformed Azure
            % URL missing the container@account part
            error(message("MATLAB:virtualfileio:stream:invalidFilename", filename));
        elseif type ~= "gsheet"
            [path, ~, ext] = fileparts(filename);
            if isempty(path)
                % If no path is passed in, we should assume the current
                % directory is the one we are using. Later on, some more general
                % code will look for the existing file, but it does path lookup
                % to match the file name.
                fname = fullfile(pwd,filename);
            else
                % In the case of a full/partial path, no path lookup will
                % happen.
                fname = filename;
            end
        end

        sharedArgs.SuppliedWriteVarNames = supplied.WriteVariableNames;

        switch lower(type)
            case "text"
                matlab.io.text.internal.write.writeTextFile(T, fname, ...
                    sharedArgs,remainingArgs);
            case "spreadsheet"
                matlab.io.spreadsheet.internal.write.writeXLSFile(T, ...
                    fname, ext(2:end), sharedArgs, remainingArgs{:});
            case "gsheet"
                googlesheetID = matlab.io.internal.common.validators.extractGoogleSheetIDFromURL(fname);
                matlab.io.internal.spreadsheet.fileAttributesForGoogleSheet(googlesheetID);

                indexForAutoFitWidth = 0;
                for ii = 1 : 2 : numel(remainingArgs)
                    if startsWith("UseExcel", remainingArgs(ii))
                        if remainingArgs{ii+1}
                            error(message("MATLAB:spreadsheet:gsheet:UseExcelNotAllowed"));
                        end
                    end
                    if startsWith("AutoFitWidth", remainingArgs(ii))
                        indexForAutoFitWidth = ii;
                    end
                end

                remainingArgs{end+1} = "UseExcel";
                remainingArgs{end+1} = 2;

                if ~indexForAutoFitWidth
                    remainingArgs{end+1} = "AutoFitWidth";
                    remainingArgs{end+1} = false;
                end
                matlab.io.spreadsheet.internal.write.writeXLSFile(T, ...
                    googlesheetID, "gsheet", sharedArgs, remainingArgs{:});
            otherwise
                error(message('MATLAB:table:write:UnrecognizedFileType',type));
        end

        if validURL && type == "spreadsheet"
            % upload the file to the remote location
            upload(ltr);
        end
    elseif type == "xml"
        % currently no shared args with text or spreadsheet files, VFS
        % support is implemented in c++
        matlab.io.xml.internal.write.writeTable(T,filename,suppliedArgs);
    end
catch ME
    msgid = ME.identifier;
    if exist("fname", "var")
        S = matlab.io.internal.filesystem.Path(fname);
    else
        S = matlab.io.internal.filesystem.Path(filename);
        fname = filename;
    end

    if strcmp(msgid, "MATLAB:fileparts:MustBeChar")
        throwAsCaller(MException(message("MATLAB:virtualfileio:path:cellWithEmptyStr","FILENAME")));
    elseif matches(msgid, ["MATLAB:FileIO:InvalidRemoteLocation", ...
            "MATLAB:FileIO:InvalidURLScheme", "MATLAB:virtualfileio:stream:unableToOpenStream"])
        error(message("MATLAB:virtualfileio:stream:CannotFindLocation", fname, S.Parent));
    elseif matches(msgid,["MATLAB:virtualfileio:stream:permissionDenied","MATLAB:virtualfileio:stream:fileNotFound"])
        % Provides a better error message if the reason the file was
        % not found due to invalid env variables.
        matlab.io.internal.vfs.validators.validateCloudEnvVariables(fname);
        throw(ME)
    elseif strcmp(msgid, "MATLAB:FileIO:HadoopNotInitialized")
        ME = MException("MATLAB:virtualfileio:hadooploader:hadoopNotFound", ...
                        "Hadoop credentials not found.");
        error(matlab.io.internal.vfs.util.convertStreamException(ME, fname));
    elseif strcmp(msgid, "MATLAB:badfid_mx")
        error(message("MATLAB:fopen:InvalidFileLocation"));
    elseif strcmp(msgid, "MATLAB:TooManyInputs")
        % TODO: Remove once writetable param parsing code is checked in
        error(message("MATLAB:table:parseArgs:BadParamName", ME.ArgumentName));
    elseif strcmp(msgid, "MATLAB:validation:IncompatibleSize")
        % TODO: Remove once writetable param parsing code is checked in
        error(message("MATLAB:table:InvalidLogicalVal", ME.ArgumentName));
    elseif exist("ltr","var")
        error(matlab.io.internal.vfs.util.convertStreamException(ME, remoteFolder));
    else
        throw(ME);
    end
end

% Copyright 2012-2024 The MathWorks, Inc.
