% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides functionality for Image file import.

% Copyright 2020-2023 The MathWorks, Inc.

classdef ImageImportProvider < matlab.internal.importdata.ImportPreviewProvider
    
    properties
        % Whether the image contains a colormap value
        HasColormap (1,1) logical = false;
        
        % Whether the image contains an alpha value
        HasAlpha (1,1) logical = false;
    end

    properties(Constant, Hidden)
        DATA_VAR_NAME = "cdata";
        COLORMAP_VAR_NAME = "cmap";
        ALPHA_VAR_NAME = "alphadata";
    end
    
    methods
        function this = ImageImportProvider(filename)
            % Create an instance of an ImageImportProvider

            arguments
                filename (1,1) string = "";
            end
            
            this = this@matlab.internal.importdata.ImportPreviewProvider(filename);
            
            this.FileType = "images";
            this.HeaderComment = "% " + gs("CodeCommentImage");
        end

        function lst = getSupportedFileExtensions(~)
            lst = ["png", "tif", "pcx", "xwd", "bmp", "gif"];
        end

        function fileType = getSupportedFileType(~)
            fileType = "im";
        end

        function summary = getTaskSummary(task)
            if isempty(task.Filename) || strlength(task.Filename) == 0
                summary = "";
            else
                [~, file, ext] = fileparts(task.Filename);
                summary = gs("ImageSummary", "`" + file + ext + "`");
            end
        end

        function outputs = getOutputs(task, lhs)
            if task.HasColormap && task.HasAlpha
                outputs = cellstr([task.DATA_VAR_NAME, task.COLORMAP_VAR_NAME, task.ALPHA_VAR_NAME]);
            elseif task.HasColormap
                outputs = cellstr([task.DATA_VAR_NAME, task.COLORMAP_VAR_NAME]);
            elseif task.HasAlpha
                outputs = cellstr([task.DATA_VAR_NAME, task.ALPHA_VAR_NAME]);
            else
                outputs = {lhs};
            end
        end

        function code = generateVisualizationCode(task, lhs)
            code = '';
            if ~isempty(task.ImportDataCheckBox) && isvalid(task.ImportDataCheckBox) && task.ImportDataCheckBox.Value
                removeTickLabels = true;
                if task.HasColormap && task.HasAlpha
                    code = "image(" + task.DATA_VAR_NAME + ");" + newline + "alpha(" + task.ALPHA_VAR_NAME + ");" + newline + "colormap(" + task.COLORMAP_VAR_NAME + ");";
                elseif task.HasColormap
                    % image(cdata) colormap(cmap)
                    code = "image(" + task.DATA_VAR_NAME + ");" + newline + "colormap(" + task.COLORMAP_VAR_NAME + ");";
                elseif task.HasAlpha
                    % imagesc(cdata, "AlphaData", alpha)
                    code = "image(" + task.DATA_VAR_NAME + ");" + newline + "alpha(" + task.ALPHA_VAR_NAME + ");";
                else
                    % imshow(mydata)
                    code = "imshow(" + lhs + ");";
                    removeTickLabels = false;
                end

                if removeTickLabels
                    code = code + newline + "xticklabels({});" + newline + "yticklabels({});";
                end
            end        

            if ~isempty(code)
                code = code + newline + task.getPlotTitleCodeForFilename("ImagePlotTitle");
            end

            code = char(code);
        end
        
        function code = getImportCode(this)           
            % Returns the import code to be executed.  The code will be
            % something like:
            %
            % sample = imread("sample.png");
            % OR
            % [cdata, colormap] = imread("sample.tif");
            
            arguments
                this (1,1) matlab.internal.importdata.ImageImportProvider
            end

            % Reset to defaults
            this.HasAlpha = false;
            this.HasColormap = false;

            try
                st = imfinfo(this.getFullFilename);
            catch
                % Ignore errors when getting the code.  The same errors will appear
                % in the Live Task or when actually imported.
                st = struct("Transparency", '', "ColorType", '', "Colormap", '');
            end
            [~, varName, ext] = fileparts(this.getFullFilename);
            varName = this.getUniqueVarName(varName);
            ext = lower(ext);
            if any(ext == [".tif", ".tiff"])
                % tiff files may have multiple frames.  If imfinfo finds them,
                % and if one has a colormap that isn't empty, then import using
                % multiple output values.
                if length(st) > 1
                    c = {st.Colormap};
                    if any(cellfun(@(x) ~isempty(x), c))
                        this.HasColormap = true;
                    end
                end
            elseif any(ext == ".png") && st.Transparency == "alpha"
                % PNG files may contain an alpha value
                [~, ~, alpha] = imread(this.getFullFilename);
                if ~isempty(alpha)
                    this.HasAlpha = true;
                end
            end
            
            if strcmp(st(1).ColorType, "indexed")
                % Also, if the ColorType is indexed, importing using multiple
                % arguments
                this.HasColormap = true;
                
                if any(ext == ".pcx")
                    % pcx files may or may not have a colormap, need to use imread
                    % to check.
                    [~, colormap] = imread(this.getFullFilename);
                    if isempty(colormap)
                        this.HasColormap = false;
                    end
                end
            end
            
            if this.HasColormap || this.HasAlpha
                % Handle multi-arg import, something like the following:
                % [cdata, colormap] = imread("sample.tif");
                % [cdata, ~, alpha] = imread("sample.png");
                cdataVar = this.getUniqueVarName(this.DATA_VAR_NAME);
                colormapVar = this.getUniqueVarName(this.COLORMAP_VAR_NAME);
                alphaVar = this.getUniqueVarName(this.ALPHA_VAR_NAME);

                if this.HasColormap && this.HasAlpha
                    code = "[" + cdataVar + ", " + colormapVar + ", " + alphaVar + ...
                        "] = imread(""" + this.getFullFilename + """);";
                elseif this.HasColormap
                    code = "[" + cdataVar + ", " + colormapVar + ...
                        "] = imread(""" + this.getFullFilename + """);";
                elseif this.HasAlpha
                    code = "[" + cdataVar + ", ~, " + alphaVar + ...
                        "] = imread(""" + this.getFullFilename + """);";
                end
            else
                % Generate code using the Filename as the varName, like:
                % sample = imread("sample.png");
                code = varName + " = imread(""" + this.getFullFilename + """);";
            end

            this.LastCode = code;
        end
        
        function showPreview(this, parent, vars, ~)
            % Shows the image preview, using the UIImageViewer component
            
            arguments
                this (1,1) matlab.internal.importdata.ImageImportProvider
                parent (1,1) matlab.graphics.Graphics
                vars cell
                ~
            end
            
            try
                if length(vars) == 1
                    % Create the preview for just the color data
                    matlab.internal.datatools.uicomponents.uiimageviewer.UIImageViewer(...
                        "ImageSource", vars{1}, "Parent", parent);
                elseif length(vars) == 2
                    if this.HasColormap
                        % Create the preview for the color data and colormap
                        matlab.internal.datatools.uicomponents.uiimageviewer.UIImageViewer(...
                            "ImageSource", vars{1}, "Colormap", vars{2}, ...
                            "Parent", parent);
                    elseif this.HasAlpha
                        % Create the preview for the color data and alpha
                        matlab.internal.datatools.uicomponents.uiimageviewer.UIImageViewer(...
                            "ImageSource", vars{2}, "Alpha", vars{1}, ...
                            "Parent", parent);
                    end
                else
                    matlab.internal.datatools.uicomponents.uiimageviewer.UIImageViewer(...
                        "ImageSource", vars{1}, "Colormap", vars{2}, ...
                        "Alpha", vars{3}, "Parent", parent);
                end
            catch
                % Show a label with a message if there is an error
                uilabel("Text", gs("PreviewUnavailable"), ...
                    "Parent", parent);
            end
        end
        
        function previewHidden(~)
            % Called when the preview is hidden.  This is a no-op for image
            % preview.
        end
    end
end

function s = gs(msg, varargin)
    if nargin == 1
        s = getString(message("MATLAB:datatools:importdata:" + msg));
    else
        s = getString(message("MATLAB:datatools:importdata:" + msg, varargin{:}));
    end
end

