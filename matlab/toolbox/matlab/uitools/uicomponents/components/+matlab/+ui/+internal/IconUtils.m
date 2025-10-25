classdef (Sealed, Abstract) IconUtils < handle
    %ICONUTILS utility function can be used to convert images to a
    %DataURI/URL
    
    % Copyright 2018-2024 The MathWorks, Inc.
    properties(Constant)
        StatusIcon = {'error', 'warning', 'info', 'success', 'question'};
        StatusAndNoneIcon = [matlab.ui.internal.IconUtils.StatusIcon, 'none'];
        ColorPickerIcon = {'fill', 'text', 'line'};
        AxesToolbarIcon = {'brush', 'datacursor','rotate', 'pan', ...
            'zoom', 'zoomin', 'zoomout', 'restoreview', ...
            'stepzoomout', 'stepzoomin', ...
            'save', 'copyimage', 'copyvector',  'export', 'none', ''};

        % The set of all available preset icons
        PresetIcon = [
            matlab.ui.internal.IconUtils.StatusAndNoneIcon, ...
            matlab.ui.internal.IconUtils.ColorPickerIcon, ...
            matlab.ui.internal.IconUtils.AxesToolbarIcon];
    end

    methods(Static)
        
        % Helper function to get a PNG file from CDATA
        function tmpFile = getFileFromCData(cdata, cmap, fformat, opts)
            if nargin < 4
                opts = {};
            end
           
            % write CData/CMap to the specified file format
            if isempty(cmap)
                inputs = {cdata, '', opts{:}};
                tmpFileInputIndex = 2;
                format = fformat;
            else
                inputs = {cdata, cmap, '', opts{:}};
                tmpFileInputIndex = 3;
                format = fformat;
            end

            tmpFile = matlab.ui.internal.IconUtils.safeIMWrite(inputs,tmpFileInputIndex,format);
        end
        
        % Helper function to create a PNG file for the icon
        % Note: Calling function should have their own error handler
        % Input: icon - Icon value to process
        % Output: Full path to a PNG file (in tempdir)
        function PNGFilePath = getPNGFileForView(icon)
            PNGFilePath = '';
            
            [icondata, icontype] = matlab.ui.internal.IconUtils.validateIcon(icon);
            
            if strcmp(icontype, 'cdata')
                PNGFilePath = matlab.ui.internal.IconUtils.getFileFromCData(icondata, [], '.png');
            elseif strcmp(icontype, 'file')
                % Get full pathname if not in pwd.
                fid = fopen(icondata, 'r');
                iconfileName = fopen(fid);
                fclose(fid);
                
                try
                    opts = {};
                    finfo = imfinfo(iconfileName);
                    % Pick the first item in case this is a multi-frame GIF
                    finfo = finfo(1);
                    fformat = lower(finfo.Format);
                    
                    if strcmp(fformat, 'png')
                        PNGFilePath = iconfileName;
                    else
                        if any(strcmp(fformat, {'jpg', 'jpeg'}))
                            % Do a simple imread for JPG format
                            [im, cm] = imread(iconfileName, finfo.Format);
                        elseif strcmp(fformat, 'gif')
                            % Read only first frame for the GIF format
                            [im, cm] = imread(iconfileName, finfo.Format, 1);
                            % Handle transparency, if available in the GIF
                            % file. It is not available in
                            % multi-frame/animated GIFs
                            if isfield(finfo, 'TransparentColor')
                                qv = ones(size(cm, 1), 1);
                                qv(finfo.TransparentColor) = 0;
                                opts = {'Transparency', qv};
                            end
                        end
                        
                        % Protect against a very large icon file by
                        % resizing it to 1024x1024 px max size
                        im_size = size(im);
                        if any(im_size > 2048)
                            % Scale the image back to 1024px max. It is
                            % pretty common nowadays to have large logo
                            % images. So, allow for a higher limit to which
                            % the logo is sent to the image converter
                            % as-is, and gets scaled by the OS. However, if
                            % we are going to do our own resizing, reduce
                            % to a smaller size (1024) so as to make the
                            % image conversion more performant to make up
                            % for the resize cost.
                            final_im_size = 1024;
                            final_im_size_factor = final_im_size/max(im_size);
                            
                            if isempty(cm)
                                im = imresize(im, final_im_size_factor);
                            else
                                [im, cm] = imresize(im, cm, final_im_size_factor);
                            end
                        end
                        
                        PNGFilePath = matlab.ui.internal.IconUtils.getFileFromCData(im, cm, '.png', opts);
                    end
                catch ex
                    throwAsCaller(MException(message('MATLAB:ui:components:invalidIconFormat', ...
                        'png, jpg, jpeg, gif')));
                end
            end
        end
        
        % Helper function to get URL from CDATA
        function iconString = getURLFromCData(cdata)
            alpha = [];            
            % get alpha from cdata used for transparency
            if ndims(cdata)==3 && size(cdata,3)==3
                sz = size(cdata);
                if sz(3) == 3
                    alpha = 255*ones(sz(1),sz(2));
                    if isa(cdata, 'double')
                        % NaN values in a double rgb cdata represent alpha = 0;
                        alpha(isnan(cdata(:,:,1))) = 0;
                    end
                end
            end
            
            %We do not have a user provided bitdepth so uint16 must be
            %processed as png
            isCDataNotJPGCompatible = isa(cdata,'uint16');

            % check if alpha contains zero for NaN
            if any(alpha(:) == 0)
                % create tempfile in png format for image writing with
                % transparency
                format = '.png';
                inputs = {cdata, '', 'Alpha',alpha};
                tmpFileInputIndex = 2;
            elseif isCDataNotJPGCompatible
                %Create png for files that arent transparent and arent compatible with jpg.
                %(NaNs indicate there is transparency and to use png. Otherwiese use
                %jpg for performance)
                format = '.png';
                inputs = {cdata, ''};
                tmpFileInputIndex = 2;
            else
                % create tempfile in jpg format for image writing
                format = '.jpg';
                inputs = {cdata, ''};
                tmpFileInputIndex = 2;
            end
            
            tmpFile = matlab.ui.internal.IconUtils.safeIMWrite(inputs,tmpFileInputIndex,format);

            % get URL for the tmpFile created
            iconString = matlab.ui.internal.URLUtils.getURLToUserFile(tmpFile, false);
        end
        
        % Helper function to process icon for view
        % Note: Calling function should have their own error handler
        % Input: icon - Icon value to process
        %        iconType - type of icon(preset, file, cdata)
        % Output: preset value, URL, URI or ''
        function out = getIconForView(icon,iconType)
            out = '';
            switch (iconType)
                case 'preset'
                    out = icon;
                    if isempty(out)
                        out = 'none';
                    end
                case 'file'
                    % Get full pathname if not in pwd.
                    fid = fopen(icon, 'r');
                    fileName = fopen(fid);
                    fclose(fid);
                    % Get URL for sending to view
                    out = matlab.ui.internal.URLUtils.getURLToUserFile(fileName, false);
                case 'cdata'
                    % Get URL for sending to view
                    out = matlab.ui.internal.IconUtils.getURLFromCData(icon);
                otherwise
                    out = '';
            end
        end
        
        % Function to validate ImageSource/Icon property for Image/uidialogs
        % and Iconable Components.
        % Validation for preset, file and cdata
        % Input: newValue - ImageSource/Icon value to validate
        %        presetIcon - (optional) set of allowed icons
        % Output: newValue - Validated ImageSource/Icon value
        %         iconType - type of image/icon(preset, file, cdata)
        function [newValue, iconType] = validateIcon(newValue,presetIcon)
            % check if the optional presetIcon is provided
            if nargin < 2
                % full set of preset icons
                presetIcon = matlab.ui.internal.IconUtils.PresetIcon;
            end

            % check if the value is char
            isValueChar = ischar(newValue);
            if isValueChar  
                % check whether newValue is in presetIcon
                iconMatched = strmatch(lower(newValue), presetIcon); %#ok<MATCH2>
                
                % get fileparts for file validation
                [pathName,fileName,fileExt] = fileparts(newValue);
            end
            
            % check if the value is empty
            if isValueChar && isempty(newValue)
                newValue = '';
                iconType = '';
            elseif isValueChar && ~isempty(iconMatched)
                newValue = presetIcon{iconMatched};
                if strcmpi(newValue,'none')
                    % none and '' do the same thing.
                    newValue = '';
                end
                iconType = 'preset';
            elseif isValueChar && ~isempty(fileName) && ~isempty(fileExt)
                % check if file has valid file type
                if ismember(lower(fileExt(2:end)), {'svg','png','jpg','jpeg','gif'})
                    % check if file exists in the path
                    if exist(newValue, 'file') == 2
                        % open file for reading
                        fid = fopen(newValue, 'r');
                        if (fid == -1)
                            % Throw error when file cannot be read
                            throwAsCaller(MException(message('MATLAB:ui:components:cannotReadIconFile', ...
                                strcat(fileName,fileExt))));
                        else
                            % Close file opened for reading
                            fclose(fid);
                            iconType = 'file';
                            newValue = [fullfile(pathName,fileName),fileExt];
                        end
                        
                    else
                        % Throw error when file is not in path
                        throwAsCaller(MException(message('MATLAB:ui:components:invalidIconNotInPath', ...
                            strcat(fileName,fileExt))));
                    end
                else
                    % Throw error on invalid file format
                    throwAsCaller(MException(message('MATLAB:ui:components:invalidIconFormat', ...
                        'png, jpg, jpeg, gif, svg')));
                end
            elseif isnumeric(newValue)
                isValidMessage = matlab.ui.internal.IconUtils.isCDataValid(newValue);
                if isempty(isValidMessage)
                        iconType = 'cdata';
                else
                    % Throw error on invalid icon cdata
                    throwAsCaller(MException(message(isValidMessage)));

                end
            else
                % Throw error on invalid Icon
                throwAsCaller(MException(message('MATLAB:ui:components:invalidIconFile')));
            end
        end
        
        % Helper function to create a temp file from a specified extension
        function [tmpFile] = createTempIconFile(varargin)
            persistent tempIconDir

            if nargin == 1
                ext = varargin{1};
                recreateFolder = false;
            elseif nargin == 2
                ext = varargin{1};
                recreateFolder = varargin{2};
            end


            isDeployedEnv = isdeployed && matlab.internal.environment.context.isWebAppServer;
            if isDeployedEnv
                tmpDir = matlab.ui.internal.dialog.FileDialogHelper.getDeployedEnvPath();
            else
                if isempty (tempIconDir) || recreateFolder
                    % create icondir directory under tempdir
                    tempIconDir = fullfile(tempname);
                    [~,~,~] = mkdir(tempIconDir);
                end
                tmpDir = tempIconDir;
            end

            % create tempfile for image writing
            if (nargin < 1)
                ext = '.png';
            end

            tmpFile = fullfile([tempname(tmpDir), ext]);
        end

        function errorMessage = isCDataValid(cdata)
            % Returns empty if the CDATA is valid for an icon/ImageSource
            % returns the specific error message if the CDATA is not valid
            % Early returns are used because the checks are progressively
            % more stringent and should only be checked if they pass the
            % previous check
            errorMessage = '';

            if(ndims(cdata) ~= 3) || (size(cdata,3) ~= 3)
                errorMessage = 'MATLAB:ui:components:invalidIconCData';
                return
            end

            % Imwrite is used to create the image to be placed on the
            % client. For our purposes, imwrite only supports 4 numeric inputs: uint16,
            % uint8, double, and single


            valid = isa(cdata,'double') ||...
                isa(cdata,'single') ||...
                isa(cdata,'uint8') ||...
                isa(cdata,'uint16');
            if ~valid
                errorMessage = 'MATLAB:ui:components:invalidIconCData';
                return
            end


            % Validate that the dataset/image will fit within 32-bit offsets.
            switch (class(cdata))
                case {'uint8'}
                    elementSize = 1;
                case {'uint16'}
                    elementSize = 2;
                case {'single'}
                    elementSize = 4;
                case {'double'}
                    elementSize = 8;
            end
            max32 = double(intmax('uint32'));
            if (any(size(cdata) > max32))
                errorMessage = 'MATLAB:ui:components:invalidIconTooLarge';
                return
            elseif ((numel(cdata) * elementSize) > max32)
                errorMessage = 'MATLAB:ui:components:invalidIconTooLarge';
                return
            end


            % JPG Specific attributes to check
            % Images processed as PNG are both doubles and contain nans.
            % Everything else is a JPG
            isImagePNG = isa(cdata,'double') && any(isnan(cdata(:,:,1)),'all');
            if ~isImagePNG && (any(size(cdata)>65500))
                errorMessage = 'MATLAB:ui:components:invalidIconTooLarge';
                return
            end
        end


        % If Imwrite fails because the temporary directory is not valid,
        % try again with a new temporary directory (see second input to
        % createTempIconFile)
        % This happens mainly in testing where the temp directory is
        % deleted and changed within the same MATLAB session 
        function tmpFile = safeIMWrite(inputs,tmpFileInputIndex,format)
            try
                tmpFile = matlab.ui.internal.IconUtils.createTempIconFile(format, false);
                inputs{tmpFileInputIndex} = tmpFile;
                imwrite(inputs{:});
            catch ex
               if any(strcmp(ex.identifier,{'MATLAB:imagesci:imwrite:fileOpen','MATLAB:imagesci:imwrite:filePathNotFound'}))
                    tmpFile = matlab.ui.internal.IconUtils.createTempIconFile(format, true);
                    inputs{tmpFileInputIndex} = tmpFile;
                    imwrite(inputs{:});
                else 
                    rethrow(ex)
                end
            end
        end
    end
end

