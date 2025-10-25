function fileResult = checkNote(fileResult)
    %checkNote: checks the note section of the help text

    %   Copyright 2021-2024 The MathWorks, Inc.

    if fileResult.HelpText == ""
        return;
    end
    if isempty(fileResult.ParsedHelp.Note)
        return;
    end
    fourSpaces = "    ";
    noteHeading = fourSpaces + "Note:";
    fileResult.Results.NoteCorrectFormat = fileResult.ParsedHelp.Note.title == noteHeading;
end
