function contents = linkContents(hp, contents, args)
    arguments
        hp;
        contents (1,1) string;
        args.QualifyingPath (1,:) string = "";
        args.QualifyingName (1,1) string = "";
        args.InClass        (1,1) logical = false;
    end
    if ~args.InClass
        helpSections = matlab.internal.help.HelpSections(contents, args.QualifyingName, '', args.InClass);
        hp.linkSeeAlsos(helpSections, args.QualifyingPath, args.QualifyingName, args.InClass);
        contents = helpSections.getFullHelpText;
    end
    replaceList = @(list)hp.hotlinkList(list, args.QualifyingPath, args.QualifyingName, true, args.InClass); %#ok<NASGU>
    contents = regexprep(contents, '^(.*?)([ \t]-[ \t\n])', '${replaceList($1)}$2', 'lineanchors', 'dotexceptnewline');
end

%   Copyright 2024 The MathWorks, Inc.
