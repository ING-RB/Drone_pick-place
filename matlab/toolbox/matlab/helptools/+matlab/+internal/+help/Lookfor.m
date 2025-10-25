classdef Lookfor < handle
    properties (Access=private)
        wantHyperlinks (1,1) logical;
        lines                string  = strings(0);
    end

    properties (SetAccess=private)
        justH1 (1,1) logical = true;
        topic  (1,1) string  = "";
        refItems             = [];
        refNames     string  = strings(0);
    end

    properties (Dependent)
        numRefItems (1,1) double;
    end

    properties
        collect  (1,1) logical = false;
        informal (1,1) logical = false;
    end

    methods
        function lp = Lookfor(args)
            lp.wantHyperlinks = matlab.internal.display.isHot;

            for arg = args
                switch arg
                case {"/all", "-all"}
                    lp.justH1 = false;
                case "-informal"
                    lp.informal = true;
                case "-hot"
                    lp.wantHyperlinks = true;
                case "-cold"
                    lp.wantHyperlinks = false;
                otherwise
                    if lp.topic == ""
                        lp.topic = arg;
                    else
                        lp.topic = lp.topic + " " + arg;
                    end
                end
            end
        end

        function num = get.numRefItems(lp)
            num = numel(lp.refItems);
        end

        function set.numRefItems(lp, num)
            if lp.numRefItems > num
                lp.refItems(num+1:end) = [];
            end
        end

        function found = doLookfor(lp)
            lp.doReferenceLookup;
            found = ~isempty(lp.refItems);

            lp.processRefItems;

            if lp.informal
                return;
            end

            found = lp.lookInPath || lp.numRefItems;
        end

        function doReferenceLookup(lp)
            request = matlab.internal.reference.api.ReferenceRequest(lp.topic);
            request.EntityCaseSensitivity = matlab.internal.reference.api.EntityCaseSensitivity.Insensitive;
            request.Comparator = matlab.internal.reference.api.comparator.PreferredOrderComparator;
            if lp.informal
                request.Types = getInformalEntityTypes;
            end
            if lp.justH1
                dataRetriver = matlab.internal.reference.api.EntityPurposeDataRetriever(request);
            else
                dataRetriver = matlab.internal.reference.api.AllTextDataRetriever(request);
            end
            lp.refItems = dataRetriver.getReferenceData;
            lp.refNames = strings(size(lp.refItems));
            for i = 1:numel(lp.refItems)
                refItem = lp.refItems(i);
                if ~isempty(refItem.RefEntities)
                    referenceName = matlab.internal.help.getQualifiedNameFromReferenceItem(refItem);
                    if ~lp.informal || ~contains(referenceName, '.') && refItem.DeprecationStatus == "Current"
                        lp.refNames(i) = referenceName;
                    end
                end
            end
            discard = lp.refNames=="";
            lp.refItems(discard)=[];
            lp.refNames(discard)=[];
        end

        function processRefItems(lp)
            for i = 1:numel(lp.refItems)
                refItem = lp.refItems(i);
                if lp.justH1
                    lp.displayH1(lp.refNames(i), refItem.Purpose);
                else
                    helpText = matlab.internal.help.getHelpTextFromReferenceItem(refItem, lp.refNames(i));
                    if ~isempty(refItem.Examples)
                        exampleTitles = join(indent + [refItem.Examples.Title], newline);
                        helpText = append(helpText, newline, exampleTitles);
                    end
                    lp.displayHelpLines(lp.refNames(i), helpText);
                end
            end
        end

        function out = getCollection(lp)
            out = join(lp.lines, newline);
        end
    end

    methods (Access=private)
        function found = lookInPath(lp)
            allFolders = split(string(path), pathsep);
            userFolders = allFolders(~startsWith(allFolders, matlabroot));
            sproot = matlabshared.supportpkg.getSupportPackageRoot;
            if sproot ~= ""
                userFolders = userFolders(~startsWith(userFolders, sproot));
            end
            userFolders = [pwd, userFolders'];
            found = false;
            for userFolder = userFolders
                contents = what(userFolder);
                mFiles = string(contents.m)';
                for mFile = mFiles
                    helpText = help.mFile(char(fullfile(userFolder, mFile)), lp.justH1);
                    if contains(helpText, lp.topic, "IgnoreCase", true)
                        found = true;
                        [~, name] = fileparts(mFile);
                        if lp.justH1
                            h1Line = matlab.internal.help.extractPurposeFromH1(helpText, name);
                            lp.displayH1(name, h1Line);
                        else
                            lp.displayHelpLines(name, helpText);
                        end
                    end
                end
            end
        end

        function displayH1(lp, name, purpose)
            referenceNameLen = strlength(name);
            padLen = max(0, 30-referenceNameLen);
            pad = blanks(padLen);
            [name, purpose] = lp.prepareForDisplay(name, purpose);
            lp.dispOrCollect(append(name, pad, " - ", purpose));
        end

        function displayHelpLines(lp, name, helpText)
            helpLines = splitlines(string(helpText));
            helpLines(~contains(helpLines, lp.topic, "IgnoreCase", true)) = [];
            if ~isempty(helpLines)
                [name, helpLines] = lp.prepareForDisplay(name, helpLines);
                lp.dispOrCollect(name + ":");
                lp.dispOrCollect(join(helpLines, newline) + newline);
            end
        end

        function dispOrCollect(lp, line)
            if lp.collect
                lp.lines(end+1) = line;
            else
                disp(line);
            end
        end

        function [name, text] = prepareForDisplay(lp, name, text)
            if lp.wantHyperlinks
                if matlab.internal.feature('webui')
                    linkName = lp.makeTopicStrong(name);
                else
                    linkName = name;
                end
                name = matlab.internal.help.createMatlabLink("help", name, linkName);
                text = lp.makeTopicStrong(text);
            end
        end

        function lines = makeTopicStrong(lp, lines)
            lines = regexprep(lines, lp.topic, "<strong>$0</strong>", "ignorecase");
        end
    end
end

function entityTypes = getInformalEntityTypes
    import matlab.internal.reference.property.RefEntityType;
    entityTypes = [RefEntityType.Function, RefEntityType.Object, RefEntityType.Live_Editor_Task, RefEntityType.App, RefEntityType.Block];
end

%   Copyright 2023-2024 The MathWorks, Inc.

