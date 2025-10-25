%

% Copyright 2014-2022 The MathWorks, Inc.
function hasError = printFEMessages(msgs, printWarnings, fileId)
if nargin < 2
    printWarnings = true;
end
if nargin < 3
    fileId = 1;
end

hasError = false;
for iMsg = 1:numel(msgs)
    msg = msgs(iMsg);
    switch msg.kind
        case 'warning'
            if ~printWarnings
                continue
            end
        case {'error', 'fatal'}
            hasError = true;
        otherwise
            continue
    end

    msgText = '';
    if ~isempty(msg.file) && ~strcmp(msg.file, '-')
        msgText = ['"', msg.file, '"'];
    end

    if msg.line > 0
        if ~isempty(msgText)
            msgText = [msgText, ', ']; %#ok<AGROW>
        end
        msgText = sprintf('%sline %d', msgText, msg.line);
    end

    if ~isempty(msgText)
        msgText = [msgText, ': ']; %#ok<AGROW>
    end
    msgText = [msgText, char(msg.kind), ':']; %#ok<AGROW>

    if ~isempty(msg.desc)
        msgText = [msgText, ' ', msg.desc]; %#ok<AGROW>
    end

    if ~isempty(msg.detail)
        msgText = sprintf('%s\n%s', msgText, msg.detail);
    end

    fprintf(fileId, '%s\n', msgText);
end


% LocalWords:  sline
