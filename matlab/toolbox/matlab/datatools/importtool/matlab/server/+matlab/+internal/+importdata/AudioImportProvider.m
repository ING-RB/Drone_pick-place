% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides functionality for Audio file import.

% Copyright 2020-2023 The MathWorks, Inc.

classdef AudioImportProvider < matlab.internal.importdata.ImportPreviewProvider
    
    properties(Hidden = true)
        Previewer = [];
    end

    properties(Constant, Hidden)
        DATA_VAR_NAME = "data";
        SAMPLE_RATE_VAR_NAME = "fs";
    end
    
    methods
        function this = AudioImportProvider(filename)
            % Create an instance of an AudioImportProvider

            arguments
                filename (1,1) string = "";
            end
            
            this = this@matlab.internal.importdata.ImportPreviewProvider(filename);
            
            this.FileType = "audio";
            this.HeaderComment = "% " + getString(message("MATLAB:datatools:importdata:CodeCommentAudio"));
        end

        function lst = getSupportedFileExtensions(~)
            lst = ["mp3", "au"];
        end

        function fileType = getSupportedFileType(~)
            fileType = "audio";
        end

        function summary = getTaskSummary(task)
            if isempty(task.Filename) || strlength(task.Filename) == 0
                summary = "";
            else
                [~, file, ext] = fileparts(task.Filename);
                summary = getString(message("MATLAB:datatools:importdata:AudioSummary", "`" + file + ext + "`"));
            end
        end

        function outputs = getOutputs(task, ~)
            outputs = cellstr([task.DATA_VAR_NAME, task.SAMPLE_RATE_VAR_NAME]);
        end

        function code = generateVisualizationCode(task, ~)
            code = '';
            if ~isempty(task.ImportDataCheckBox) && isvalid(task.ImportDataCheckBox) && task.ImportDataCheckBox.Value
                % Don't set DisplayName.  Since audio data is likely a Nx2
                % array, setting DisplayName results in the legend showing
                % "audio data" for both lines.  With it not set, it shows
                % the default which is data1 and data2.  (The alternative
                % is to separate into different plot commands, with a 'hold
                % on', but this just complicates the code).
                code = "plot(" + task.DATA_VAR_NAME + ", ""LineWidth"", 1.5);";
                code = code + newline + task.getPlotTitleCodeForFilename("AudioPlotTitle");
                code = code + newline + "legend;";
            end

            code = char(code);
        end
        
        function code = getImportCode(this)
            % Returns the import code to be executed.  The code will be
            % something like:
            % [data, fs] = audioread("sample.mp3");

            arguments
                this (1,1) matlab.internal.importdata.AudioImportProvider
            end
            
            dataVar = this.getUniqueVarName(this.DATA_VAR_NAME);
            fsVar = this.getUniqueVarName(this.SAMPLE_RATE_VAR_NAME);
            code = "[" + dataVar + ", " + fsVar + ...
                "] = audioread(""" + this.getFullFilename + """);";
            this.LastCode = code;
        end
        
        function showPreview(this, parent, vars, ~)
            % Shows the audio preview, using the UIAudioPlayer component
            
            arguments
                this (1,1) matlab.internal.importdata.AudioImportProvider %#ok<*INUSA>
                parent (1,1) matlab.graphics.Graphics
                vars cell
                ~
            end
            
            try
                % Create the preview for the audio data and sample rate
                this.Previewer = matlab.internal.datatools.uicomponents.uiaudioplayer.UIAudioPlayer(...
                    "AudioSource", vars{1}, "SampleRate", vars{2}, ...
                    "Parent", parent);
            catch
                % Show a label with a message if there is an error
                uilabel("Text", getString(message("MATLAB:datatools:importdata:PreviewUnavailable")), ...
                    "Parent", parent);
            end
        end
        
        function previewHidden(this)
            % Called when the preview is hidden, makes sure that the player
            % isn't still active

            arguments
                this (1,1) matlab.internal.importdata.AudioImportProvider
            end
            
            if ~isempty(this.Previewer)
                this.Previewer.stop();
            end
        end
    end
end
