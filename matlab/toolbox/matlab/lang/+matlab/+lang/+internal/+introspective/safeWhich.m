function whichTopic = safeWhich(topic, isCaseSensitive, callingFunction)
    if nargin < 2
        isCaseSensitive = false;
    end

    if nargin < 3
        callingFunction = '';
        resolveFunctionsOffThePath = false;
    else
        resolveFunctionsOffThePath = true;
    end

    warnState = warning('off', 'MATLAB:class:AtFolderPrecedence');
    warnCleanup = onCleanup(@()warning(warnState));
    whichTopic = whichFcn(topic, isCaseSensitive, callingFunction, resolveFunctionsOffThePath);
end

function result = whichFcn(topic, isCaseSensitive, callingFunction, resolveFunctionsOffThePath)
    if callingFunction ~= ""
        result = doWhich(topic, isCaseSensitive, callingFunction, resolveFunctionsOffThePath);
    else
        result = matlab.lang.internal.introspective.cache.lookup(@doWhich, topic, isCaseSensitive, '', resolveFunctionsOffThePath);
    end
end

function whichTopic = doWhich(topic, isCaseSensitive, callingFunction, resolveFunctionsOffThePath)
    [~, name, ext] = fileparts(topic);
    if ext ~= ""
        whichTopic = casedWhich(topic, isCaseSensitive, callingFunction, false);
        if whichTopic == ""
            if resolveFunctionsOffThePath && isfile(topic)
                whichTopic = topic;
            end
        else
            [~, ~, whichExt] = fileparts(whichTopic);
            if ~strcmpi(ext, whichExt)
                whichTopic = '';
            end
        end
    else
        [whichTopic, descriptor] = casedWhich(topic, isCaseSensitive, callingFunction, true);
        [~, whichName, whichExt] = fileparts(whichTopic);
        if ~strcmpi(name, whichName)
            whichTopic = '';
        end
        isPFile = whichExt == ".p";
        if whichTopic == "" || (descriptor ~= "" && (whichExt == ".m" || isPFile)) || whichExt == append(".", mexext)
            dotMTopic = casedWhich(append(topic, '.m'), isCaseSensitive, callingFunction, false);
            if dotMTopic ~= "" && ~(isPFile && strcmp(fileparts(dotMTopic), fileparts(whichTopic)))
                whichTopic = dotMTopic;
            end
        end
    end
end

function [result, descriptor] = casedWhich(topic, isCaseSensitive, callingFunction, ignoreExtension)
    result = '';
    descriptor = '';
    if isempty(regexp(topic, '\)\s*$', 'once'))
        try %#ok<TRYNC> which may throw if topic is unreadable
            if isCaseSensitive

                [oneResult, oneDescriptor] = which(topic);
                [allWhich, allWhichDescriptors] = which(topic, '-all');
                allWhich = [{oneResult}; allWhich];
                allWhichDescriptors = [{oneDescriptor}; allWhichDescriptors];

                % Filter out results that aren't a case match
                generalizeSeparators = regexptranslate('flexible', topic, '\W*');

                if ignoreExtension
                    generalizeSeparators = append(generalizeSeparators, '\.[^.]+$');
                end

                allWhichMatches = regexp(allWhich, append('\<', generalizeSeparators, '$'), 'once');

                filterCells = cellfun('isempty', allWhichMatches);

                allWhich(filterCells) = [];
                allWhichDescriptors(filterCells) = [];

                % if topic is a path with a private function, don't filter out private functions
                if isempty(regexp(topic, '[\\/]', 'once'))
                    filterCells = startsWith(allWhichDescriptors, ["Private", "Shadowed and private"], 'IgnoreCase', true);
                    allWhich(filterCells) = [];
                    allWhichDescriptors(filterCells) = [];
                end

                if ~isempty(allWhich)
                    result = allWhich{1};
                    descriptor = allWhichDescriptors{1};
                end
            elseif contains(topic, filemarker) || (callingFunction == "")
                [result, descriptor] = which(topic);
            else
                [result, descriptor] = which(topic, 'in', callingFunction);
            end
        end
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.

