classdef HelpCommentsParser < appdesigner.internal.serialization.loader.interface.DecoratorLoader
    %HELPCOMMENTPARSER Parses the help comments text from an MLAPP file
    %   This loader parses the help comments text from an MLAPP file and
    %   adds the summary (H1 line) and detailed description help comments
    %   text to the code data.
    
    % Copyright 2021 - 2022 The MathWorks, Inc.
    
    properties (Access = private)
        AppCode
    end
        
    methods
        function obj = HelpCommentsParser(loader, appCode)
            obj@appdesigner.internal.serialization.loader.interface.DecoratorLoader(loader);
            obj.AppCode = appCode;
        end
        
        function appData = load(obj)
            appData = obj.Loader.load();
            
            appData.code.HelpComments = struct('Summary', '', 'Description', '');
            
            className = appData.code.ClassName;
            
            % Get the help text from the app code
            fullPath = '';
            justH1 = false;
            getFileTextFcn = @(fullPath) obj.AppCode;
            helpStr = matlab.internal.help.getMFileHelpText(fullPath, getFileTextFcn, justH1);
            
            if isempty(helpStr)
                return;
            end
            
            % Remove any trailing whitespace
            helpStr = strip(helpStr, 'right');
            
            helpStr = strsplit(helpStr, newline);
            
            % Remove the first blank space in front of each line
            helpStr = extractAfter(helpStr, 1);
            
            % If the help text doesn't start with the class name then it is
            % not the true app class help text but instead the first found
            % comment file in the app.
            if startsWith(helpStr{1}, upper(className))
                
                % Extract out the summary/H1 line. The summary can wrap
                % onto multiple lines. Once the comment line starts with 3
                % blanks then it is no longer the summary but the
                % description
                summary = removeFirstBlank(obj, strrep(helpStr{1}, upper(className), ''));
                index = 2;
                while(length(helpStr) >= index && ~startsWith(helpStr(index), blanks(3)))
                    summary = [summary ' ' strip(helpStr{index})]; %#ok<AGROW> 
                    index = index + 1;
                end
                appData.code.HelpComments.Summary = summary;
                
                description = helpStr(index:end);
                if ~isempty(description)
                    % Extract the description from the remaining text and
                    % remove the first 3 blank spaces from each line
                    description = extractAfter(helpStr(index:end), 3);
                    description = strjoin(description, newline);
                    
                    appData.code.HelpComments.Description = description;
                end
            end
        end
    end
    
    methods (Access = private)
        function str = removeFirstBlank(~, str)
            
            if ~isempty(str) && startsWith(str, ' ')
                str = extractAfter(str, 1);
            end
        end
    end
end

