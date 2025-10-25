function [outStr, found] = help2html(topic,pagetitle,helpCommandOption)
%HELP2HTML Convert M-help to an HTML form.
% 
%   This file is a helper function used by the HelpPopup Java component.  
%   It is unsupported and may change at any time without notice.

%   Copyright 2007-2021 The MathWorks, Inc.
if nargin == 0
    outStr = '';
    found = false;
    return;
end
if nargin < 2
    pagetitle = '';
end
if nargin < 3
    helpCommandOption = '-helpwin';
end
dom = com.mathworks.xml.XMLUtils.createDocument('help-info');
dom.getDomConfig.setParameter('cdata-sections',true);

[helpNode, helpstr, fcnName, found] = help2xml(dom, topic, pagetitle, helpCommandOption);

afterHelp = '';
if found
    % Handle characters that are special to HTML 
    helpstr = matlab.internal.help.fixsymbols(helpstr);

    % Extract the see also and overloaded links from the help text.
    % Since these are already formatted as links, we'll keep them 
    % intact rather than parsing them into XML and transforming
    % them back to HTML.
    helpSections = matlab.internal.help.HelpSections(helpstr, fcnName);    
    types = {'seeAlso', 'note', 'overloaded', 'folders', 'demo'};
    sections = {helpSections.SeeAlso, ...
                helpSections.Note, ...
                helpSections.OverloadedMethods, ...
                helpSections.FoldersNamed, ...
                helpSections.Demo};
    afterHelp = moveToAfterHelp(afterHelp, types, sections);
    
    helpstr = deblank(helpSections.getFullHelpText);
    shortName = regexp(fcnName, '(?<=\W)\w*$', 'match', 'once');
    helpstr = matlab.internal.help.highlightHelp(helpstr, fcnName, shortName, '<span class="helptopic">', '</span>');
elseif strcmp(helpCommandOption, '-doc')
    outStr = '';
    return;
end

addTextNode(dom,dom.getDocumentElement,'css-file', getIncludesFile('includes/product/css/helpwin.css'));
addTextNode(dom,dom.getDocumentElement,'jquery-file', getIncludesFile('includes/product/scripts/jquery/jquery-latest.js'));
addTextNode(dom,dom.getDocumentElement,'helpservices-file', getIncludesFile('includes/shared/scripts/helpservices.js'));

if found
    addAttribute(dom,helpNode,'helpfound','true');
else
    addAttribute(dom,helpNode,'helpfound','false');
    % It's easier to escape the quotes in M than in XSL, so do it here.
    addTextNode(dom,helpNode,'escaped-topic',strrep(fcnName,'''',''''''));
end

% Prepend warning about empty docroot, if we've been called by doc.m
if strcmp(helpCommandOption, '-doc') && ~matlab.internal.help.isDocInstalled
    addAttribute(dom,dom.getDocumentElement,'doc-installed','false');
end

helpCommandOption = char(helpCommandOption);

addTextNode(dom,dom.getDocumentElement,'default-topics-text',getString(message('MATLAB:helpwin:sprintf_DefaultTopics')));
addTextNode(dom,dom.getDocumentElement,'no-help-found',getString(message('MATLAB:helpwin:NoHelpFound', '')));
addTextNode(dom,dom.getDocumentElement,'search-in-documentation',getString(message('MATLAB:helpwin:SearchInDocumentation', sprintf('<b>%s</b>',fcnName))));
addTextNode(dom,dom.getDocumentElement,'help-command-option',helpCommandOption(2:end));
xslfile = fullfile(fileparts(mfilename('fullpath')),'private','helpwin.xsl');
outStr = xslt(dom,xslfile,'-tostring');

% Use HTML entities for non-ASCII characters
helpstr = regexprep(helpstr,'[^\x0-\x7f]','&#x${dec2hex($0)};');
afterHelp = regexprep(afterHelp,'[^\x0-\x7f]','&#x${dec2hex($0)};');
outStr = regexprep(outStr,'\s*(<!--\s*helptext\s*-->)', sprintf('$1%s',regexptranslate('escape',helpstr)));
outStr = regexprep(outStr,'\s*(<!--\s*after help\s*-->)', sprintf('$1%s',regexptranslate('escape',afterHelp)));

%==========================================================================
function afterHelp = moveToAfterHelp(afterHelp, types, sections)
for i = 1:length(types)
    section = sections{i};
    if section.hasValue
        title = section.title;
        if endsWith(title, ':')
            title = title(1:end-1);
        end
        afterHelp = sprintf('%s<!--%s-->', afterHelp, types{i});
        afterHelp = sprintf('%s<div class="footerlinktitle">%s</div>', afterHelp, title);
        afterHelp = sprintf('%s<div class="footerlink">%s</div>', afterHelp, section.helpStr);
        section.clearPart;
    end
end

%==========================================================================
function addTextNode(dom,parent,name,text)
child = dom.createElement(name);
child.appendChild(dom.createTextNode(text));
parent.appendChild(child);

%==========================================================================
function addAttribute(dom,elt,name,text)
att = dom.createAttribute(name);
att.appendChild(dom.createTextNode(text));
elt.getAttributes.setNamedItem(att);

%==========================================================================
function includesFile = getIncludesFile(relativeIncludeFile)
docRoot = com.mathworks.mlwidgets.help.DocCenterDocConfig.getInstance.getDocRoot;
includesFile = char(docRoot.buildGlobalPageUrl(relativeIncludeFile).toString);
