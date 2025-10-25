%PeerUtils
%   Utilities class

% Copyright 2014-2024 The MathWorks, Inc.

classdef PeerUtils < handle

    % constants representing the levels of debugging
    properties (Constant=true)
        NONE = uint64(0);
        PERFORMANCE = uint64(1);
        DEBUG = uint64(2);
        INFO = uint64(4);
    end

    % property to keep track of the current level of debugging
    properties (SetObservable=true, SetAccess='public', GetAccess='public', Dependent=false, Hidden=false)
        Debuglevel = uint64(0);
    end

    properties (SetObservable=true, SetAccess='public', GetAccess='public', Dependent=false, Hidden=false)
        IsPrototype = false;
        IsTestingEnvironment = false;
        FilteringInVEOn = false;
    end
    
    methods
        function storedValue = get.IsPrototype(this)
            storedValue = this.IsPrototype;
        end

        function set.IsPrototype(this, newValue)
            this.IsPrototype = logical(newValue);
        end
    end

    methods(Access='protected')
        function this = PeerUtils()
            this.Debuglevel = uint64(0);
        end
    end

    %PeerUtils Static Utility Methods
    methods(Static, Access='public')
        obj = getInstance();
        formattedSize = getFormattedSize(s);
        formattedClass = formatClass(cdata);
        jsonStr = toJSON(~, varargin);
        jsonStr = escapeJSONValue(strValue);
        debug = isDebug();
        info = isInfo();
        setDebug(value);
        receivedLogMessage(msg);
        setLogLevel(logLevel);
        newLevel = addLogLevel(logLevel);
        newLevel = removeLogLevel(logLevel);
        prototype = isPrototype();
        setPrototype(isPrototype);
        sendPeerEvent(peerNode, eventType, varargin);
        logDebug(peerNode, class, method, message, varargin);
        logMessage(~, class, method, thismessage, logLevel, varargin);
        data = parseStringQuotes(data, classType, classShowsQuotes);
        newVal = removeOuterQuotes(inVal);
        formattedData = escapeSpecialCharsForStrings(data);
        formattedData = escapeSpecialCharsForChars(data);
        formattedData = formatStringClientView(data);
        formattedData = formatStringToServerViewFromClientView(data);
        data = formatGetJSONforCell(rawVal, val);
        setVEFilteringOn(state);
        feature = isVEFilteringOn();
        feature = isTestingOn();
        setTestingOn(state);
        tableMetaData = getTableMetaData(variableValue);
        context = isLiveEditor(usercontext);
        isSortable = checkIsSortable(variableValue, isPreview);
        isFilterable = checkIsFilterable(variableValue, isPreview);
        orig_state = disableWarning();
        resumeWarning(orig_state);
        [quotes, braces_o, braces_c] = getCodegenConstructsForDatatype(datatype);
        cleanFiltNames = getCleanedNamesForCodegen(names, quotes, cClass);
        flag = isStringOrCategoricalLike(cClass);
        flag = isPlainTextType(data);
        s = getSanitizedText(text);
    end
end
