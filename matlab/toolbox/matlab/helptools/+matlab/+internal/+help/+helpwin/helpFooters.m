function [help_footers, help_str] = helpFooters(helpstr, fcnName)
    %

    %   Copyright 2020-2021 The MathWorks, Inc.

    % Copied this code from help2html.m and modifed.
    % Handle characters that are special to HTML
    helpstr = matlab.internal.help.fixsymbols(helpstr);

    % Extract the see also and overloaded links from the help text.
    % Since these are already formatted as links, we'll keep them
    % intact rather than parsing them into XML and transforming
    % them back to HTML.
    helpSections = matlab.internal.help.HelpSections(helpstr, fcnName);
    [helpFooterStruct, helpSections] = afterHelp(helpSections);

    help_str = deblank(helpSections.getFullHelpText);
    help_str = regexprep(help_str,'[^\x0-\x7f]','&#x${dec2hex($0)};');
    shortName = regexp(fcnName, '(?<=\W)\w*$', 'match', 'once');
    help_str = matlab.internal.help.highlightHelp(help_str, fcnName, shortName, '<span class="helptopic">', '</span>');

    help_footers = helpFooterStruct;
end

function [after_help, helpSections ] = afterHelp(helpSections)

    afterHelpStruct = struct('type',{},'title',{},'link',{});

    types = {'seeAlso', 'note', 'overloaded', 'folders', 'demo'};
    sections = {helpSections.SeeAlso, ...
        helpSections.Note, ...
        helpSections.OverloadedMethods, ...
        helpSections.FoldersNamed, ...
        helpSections.Demo};
    for i = 1:length(types)
        section = sections{i};
        if section.hasValue
            title = section.title;
            if endsWith(title, ':')
                title = title(1:end-1);
            end
            x.type = types{i};
            x.title = title;
            % Use HTML entities for non-ASCII characters
            link = section.helpStr;
            link = regexprep(link,'[^\x0-\x7f]','&#x${dec2hex($0)};');
            x.link = link;
            afterHelpStruct(end+1) = x; %#ok<AGROW> 
            section.clearPart;
        end
    end

    after_help = afterHelpStruct;
end
