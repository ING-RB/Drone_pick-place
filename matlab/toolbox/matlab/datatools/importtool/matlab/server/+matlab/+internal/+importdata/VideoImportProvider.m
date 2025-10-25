% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides functionality for video file import.

% Copyright 2020-2023 The MathWorks, Inc.

classdef VideoImportProvider < matlab.internal.importdata.ImportPreviewProvider
    properties(Hidden = true)
        VideoReaderVarName string;
        DataVarName string;
        
        Previewer = [];
    end

    properties(Constant, Hidden)
        VIDEO_READER_VAR_NAME = "v";
    end
    
    methods
        function this = VideoImportProvider(filename)
            % Create an instance of an VideoImportProvider
            
            arguments
                filename (1,1) string = "";
            end
            this = this@matlab.internal.importdata.ImportPreviewProvider(filename);
            
            this.FileType = "video";
            this.HeaderComment = "% " + getString(message("MATLAB:datatools:importdata:CodeCommentVideo"));
        end

        function lst = getSupportedFileExtensions(~)
            lst = ["mp4", "mpg", "avi"];
        end

        function fileType = getSupportedFileType(~)
            fileType = "video";
        end

        function summary = getTaskSummary(task)
            if isempty(task.getFullFilename) || strlength(task.getFullFilename) == 0
                summary = "";
            else
                [~, file, ext] = fileparts(task.getFullFilename);
                summary = getString(message("MATLAB:datatools:importdata:VideoSummary", "`" + file + ext + "`"));
            end
        end

        function outputs = getOutputs(task, lhs)
            outputs = {char(task.VIDEO_READER_VAR_NAME), lhs};
        end

        function code = generateVisualizationCode(task, ~)
            code = '';
            if ~isempty(task.ImportDataCheckBox) && isvalid(task.ImportDataCheckBox) && task.ImportDataCheckBox.Value
                code = "imshow(" + task.VIDEO_READER_VAR_NAME + ".read(1));";
                code = code + newline + task.getPlotTitleCodeForFilename("VideoPlotTitle");
            end

            code = char(code);
        end
        
        function code = getImportCode(this)
            % Returns the import code to be executed.  The code will be
            % something like:
            %
            % v = VideoReader("sample.mp4");
            % sample = read(v);

            arguments
                this (1,1) matlab.internal.importdata.VideoImportProvider
            end
            
            this.VideoReaderVarName = this.getUniqueVarName("v");
            [~, varName, ~] = fileparts(this.getFullFilename);
            this.DataVarName = this.getUniqueVarName(varName);
            code = this.VideoReaderVarName + " = VideoReader(""" + this.getFullFilename + """);";
            
            if isempty(this.SelectedVarNames) || length(this.SelectedVarNames) > 1
                code = code + newline + this.DataVarName + " = read(" + this.VideoReaderVarName + ");";
            end
            this.LastCode = code;
        end
        
        function [varNames, vars] = getVariables(this)
            % Returns the variable names and variables to display in the Import
            % Data window.  Overrides the super class because creation of the
            % actual variables may take a really long time, when all we need is
            % information from the VideoReader to infer the size of the actual
            % data when it would be read into memory.
            
            arguments
                this (1,1) matlab.internal.importdata.VideoImportProvider
            end

            this.getImportCode;
            
            % There will always be two variables, the VideoReader and the data,
            % unless there is an error
            vars = cell(2,1);
            
            % Create the VideoReader
            try
                v = VideoReader(this.getFullFilename);
                vars{1} = v;
            catch
                % Handle errors, and just assume the VideoReader object
                % will be created.  Any generated code will just fail when
                % executed -- but we want to avoid errors just determining
                % the variable names.
                iv = matlab.internal.importdata.ImportVariableSummary;
                iv.Class = "VideoReader";
                vars{1} = iv;
            end
            
            try
                % Use ImportVariableSummary to represent the data which will be
                % imported by the VideoReader, since it can be large and
                % creating it to get its size would delay the dialog display
                iv = matlab.internal.importdata.ImportVariableSummary;
                iv.Dimensions = [v.Height, v.Width, 3, v.NumFrames];
                vars{2} = iv;
                
                varNames = cellstr([this.VideoReaderVarName; this.DataVarName]);
            catch
                % Accessing fields of the VideoReader can fail for some video
                % files, so just show the VideoReader as the variable to import.
                varNames = cellstr(this.VideoReaderVarName);
                vars(2) = [];
            end
        end
        
        function showPreview(this, parent, vars, ~)
            % Shows the image preview, using the UIImageViewer component
            
            arguments
                this (1,1) matlab.internal.importdata.VideoImportProvider 
                parent (1,1) matlab.graphics.Graphics
                vars cell
                ~
            end
            
            try
                if isa(vars{1}, "VideoReader")
                    videoReader = vars{1};
                else
                    videoReader = vars{2};
                end
                
                % Create the preview for the first frame
                this.Previewer = matlab.internal.datatools.uicomponents.uivideopreviewer.UIVideoPreviewer(...
                    "VideoSource", videoReader, "Parent", parent);
            catch
                % Show a label with a message if there is an error
                uilabel("Text", getString(message("MATLAB:datatools:importdata:PreviewUnavailable")), ...
                    "Parent", parent);
            end
        end
        
        function previewHidden(this)
            % Called when the preview is hidden, makes sure that the preview
            % isn't still active
            
            arguments
                this (1,1) matlab.internal.importdata.VideoImportProvider
            end
            
            if ~isempty(this.Previewer)
                this.Previewer.stop();
            end
        end
    end
end
