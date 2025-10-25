classdef FileInformation
    %FileInformation Stores information and test results for a file
    %   The result class will store the filename, help text, any errors,
    %   and all test results from auditing the file's help
    %   FileInformation Properties:
    %   FileName    - Path to the file
    %   HelpText    - Raw help text of the file
    %   HotHelp     - Hotlinked help of the file
    %   HelpError   - Errors that occurred while auditing the file
    %   Reference   - Reference page information for the file
    %   The remaining properties are results from tests -- the property
    %   will hold the value of true for passed, false for failed, empty for
    %   not applicable or missing section

    %   Copyright 2021-2023 The MathWorks, Inc.

    properties(Constant)
        MaxLineLength   = 75
        MaxNumLines     = 40
        MinSeeAlsoItems = 2
        MaxSeeAlsoItems = 7
        Tab             = char(9)
    end

    %Properties storing information about the help text
    properties
        HelpProcess  % The help process
        ParsedHelp   %The HelpSections for the file
        HelpText     % The raw help text of the file
        Reference    % Reference information for the file
        Results      % Results of the file
    end

    %Properties storing information about file path
    properties
        FileName     % The file name
        FunctionName % The function name
        PathName     % The filepath
        Extension    % The extension
        InClass      % Whether or not file is in class
        HelpError    % Errors that occurred while auditing the file
    end

    methods
        function obj = FileInformation(fileName)
            %FileInformation Gathers information about the file
            %   A = FileInformation(A)
            if iscell(fileName)
                fileName = fileName{1};
            end
            obj.FileName = convertStringsToChars(fileName);
            obj.HelpProcess = matlab.internal.help.helpProcess(1, 2, {'-helpwin', obj.FileName});
            try
                obj.HelpProcess.getHelpText;
                obj.HelpError = false;
            catch
                obj.HelpError = true;
            end
            obj.HelpText = obj.HelpProcess.helpStr;
            obj = obj.setFileParts(obj.HelpProcess); %sets function name, class name, etc
            obj.ParsedHelp = matlab.internal.help.HelpSections(obj.HelpText, obj.FunctionName);
            obj.Results = matlab.internal.help.audit.FileResult();
        end
    end

    methods
        obj = checkCopyright(obj)
        obj = checkLines(obj)
        obj = checkTabs(obj)
        obj = checkH1(obj)
        obj = checkHref(obj)
        obj = checkSeeAlso(obj)
        obj = checkNote(obj)
        obj = checkRefPage(obj)
        obj = setFileParts(obj, hp)
    end
end

