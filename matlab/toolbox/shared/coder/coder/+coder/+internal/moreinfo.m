function varargout = moreinfo(msgid, varargin, args)
    %CODER.INTERNAL.MOREINFO - Get a link to more information for a message ID.
    %
    %   Map-files contain topics that link to HTML files produced by doc
    %   writers.  Doc writers add the topics as string to the XML from which
    %   the HTML documentation is produced.
    %
    %   You can use the helpview command with a MAP file and a topic to display
    %   the appropriate HTML.  Some of the HTML files are shipped as compressed
    %   ZIP-files in JAR files.  I am not sure how this mechanism works.
    %
    %   MOREINFO(MSGID) returns a link to more information for msgID. Returns
    %   '' if no additional information exists.  A link is a string containing
    %   an appropriate <a href=...> ... </a>.  For testing purposes the magic
    %   msgid 'Magic:Cookie:Link' will return a non-empty link.
    %
    %   MOREINFO('-topic',MSGID) returns the MAP-file topic for MSGID.
    %
    %   MOREINFO('-msgid',topic) returns the MSGID associated with topic if
    %   any. Return '' if this TOPIC is syntactically invalid.  This reverse
    %   lookup is useful for testing.
    %
    %   MOREINFO('-maps') return the cellarray of MAP files in which we look for
    %   topics. (Needed to test that MAP files are valid.)
    %
    %   [MAPFILE, TOPIC] = MOREINFO('-lookup',MSGID) returns the name of the
    %   MAPFILE and topic within that MAPFILE that was found.
    %
    %   MOREINFO('-open',MSGID) attempts to open the more-info topic associated
    %   with the given MSGID if it exists and is resolvable.

    %   Copyright 2010-2024 The MathWorks, Inc.

    arguments
        msgid
    end
    arguments(Repeating)
        varargin
    end
    arguments
        args.OutputStyle {mustBeMember(args.OutputStyle, {'auto', 'hyperlink', 'command'})} = 'hyperlink'
    end

    if ~usejava('jvm') || isdeployed()
        varargout = {'', ''};
        return
    end

    switch msgid
        case '-topic'
            narginchk(2, 2);
            varargout{1} = msgid2topic(varargin{1});
        case '-msgid'
            narginchk(2, 2);
            varargout{1} = topic2msgid(varargin{1});
        case '-lookup'
            narginchk(2, 2);
            [varargout{1:2}] = lookup(varargin{1});
        case '-maps'
            assert(nargin==1);
            varargout{1} = getMaps();
        case '-open'
            narginchk(2, 2);
            varargout{1} = invokeHelpView(varargin{1});
        otherwise
            narginchk(1, 3);
            varargout{1} = createHelpCommandOrHyperlink(msgid, args.OutputStyle);
    end
end

% =========================================================================
function topic = msgid2topic(msgid)
    % This is a syntactic conversion before we do the lookup to see if the
    % topic exists in any of our MAP files.
    %
    %  MAP-file topics may only contain the characters [a-zA-Z0-9_].  This
    %  conversion tries to create a probabilistically unique bijection between
    %  message IDs and topics.
    %
    %  Replace
    %      : with _
    %      _ with uUu
    %
    %  We use the quixotic uUu because it shouldn't show up in message ids by
    %  itself, although nothing guarantees that.

    topic = ['msginfo_' regexprep(msgid, {'_' ':'}, {'uUu' '_'})];
end

% =========================================================================
function msgid = topic2msgid(topic)
    % Must be the inverse of msgid2topic.
    % This function does a purely syntactic check on purpose.  This is used for
    % testing and should NOT check the existence of the msg id!
    %
    % See comments in msgid2topic for explanation of mapping.

    tokens = regexp(topic, 'msginfo_([\w_]+)', 'tokens');
    if ~isscalar(tokens) || ~isscalar(tokens{1})
        msgid='';
    else
        msgid = tokens{1}{1};
        msgid = regexprep(msgid, {'_' 'uUu'}, {':' '_'});
    end
end

% =========================================================================
function maps = getMaps
    maps = ["coder", "ecoder", "stateflow", "simulink", "fixedpoint", "gpucoder"];
end

% =========================================================================
function [mapfile,topic] = lookup(msgid)
if msgid == "Magic:Cookie:Link"
    mapfile = 'MagicMap';
    topic = 'msginfo_Magic_Cookie_Link';
    return

end

persistent maps;

if isempty(maps)
    mapfiles = getMaps();
    maps = arrayfun(@matlab.internal.doc.csh.DocPageTopicMap,mapfiles);
    assert(~isempty(maps), "Maps shouldn't be empty")
end

topic = msgid2topic(msgid);

for i = 1:numel(maps)
    map = maps(i);
    if map.topicExists(topic)
        mapfile = char(map.getId());
        return
    end
end

mapfile = '';
topic = '';

end

% =========================================================================
function opened = invokeHelpView(msgid)
    opened = false;
    [mapfile, topic] = lookup(msgid);
    if ~isempty(mapfile) && ~isempty(topic)
        helpview(mapfile, topic);
        opened = true;
    end
end

% =========================================================================
function link = createHelpCommandOrHyperlink(msgid, outputStyle)
    [mapfile, topic] = lookup(msgid);
    if isempty(mapfile)
        link = '';
    else
        msg = message('Coder:common:MoreInfo');

        % This use of help!view is sanctioned and okay.  It should not use
        % emlhelp.  We do this strange formatting of the string to prevent
        % test failures relating to using help!view in our MATLAB code.
        % (Normally not allowed).
        if strcmp(outputStyle, 'hyperlink')
            link = getHyperlink(mapfile, topic, msg);
        elseif strcmp(outputStyle, 'command')
            link = getCommand(mapfile, topic);
        else % 'auto'
            if matlab.internal.display.isHot
                link = getHyperlink(mapfile, topic, msg);
            else
                link = getCommand(mapfile, topic);
            end
        end
    end
end

function hyperlink = getHyperlink(mapfile, topic, msg)
    hyperlink = sprintf('<a href="matlab:helpview(''%s'',''%s'');">%s</a>', ...
        mapfile, topic, msg.getString());
end
function command = getCommand(mapfile, topic)
    command = sprintf('helpview(''%s'',''%s'');', ...
        mapfile, topic);
end

% LocalWords:  MAPFILE
