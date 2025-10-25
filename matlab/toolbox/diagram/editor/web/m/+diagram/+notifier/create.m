function obj = create(diagnostics, optional)
    %% Accepts Message or Exception objects or MessageId
    arguments
        diagnostics {mustBeMessageOrExceptionOrMessageId(diagnostics)};
        optional.messageFills (1,:) {...
            mustFillMessage(diagnostics, optional.messageFills)} = {};
        % Success, Info, Warning, Or Error
        optional.Severity (1,1) diagram.notifier.NotificationSeverity...
            = diagram.notifier.NotificationSeverity.Info;
        optional.uuidTarget (1,:) {mustBeText, mustBeUUIDOrEmpty(optional.uuidTarget)} = "";
        optional.domTarget (1,:) {mustBeText} = "";
        optional.Transient (1,1) logical = true;
        % we are allowing both to be set to false
        optional.UIMode (1,1) logical;
        optional.CommandLineMode (1,1) logical;
        optional.HelpName (1,1) {mustBeText} = "";
        optional.HelpTopicId (1,1) {mustBeText} = "";
    end
    isUserSetOutput = false;
    if isfield(optional, "UIMode") || isfield(optional, "CommandLineMode")
        isUserSetOutput = true;
    end
    if ~isfield(optional, "UIMode")
        optional.UIMode = true;
    end
    if ~isfield(optional, "CommandLineMode")
        optional.CommandLineMode = false;
    end
    if isscalar(string(optional.domTarget))
        optional.domTarget = [string(optional.domTarget)];
    end

    diagObj = createDiagnosticObj(diagnostics, optional.messageFills);
    [msg, category, severity, transient] = getDisplayMessageAndCategory(diagObj, optional.Severity, optional.Transient);
    if optional.uuidTarget == ""
        % do not pass empty uuidTarget
        %obj = diagram.notifier.Notification(string(msg), string(category),...
        obj = diagram.notifier.Notification(msg, category,...
            severity, ...
            optional.domTarget,...
            transient, ...
            optional.UIMode, optional.CommandLineMode, isUserSetOutput,...
            optional.HelpName, optional.HelpTopicId);
    else
        obj = diagram.notifier.Notification(msg, category,...
            severity, ...
            string(optional.uuidTarget), optional.domTarget,...
            transient, ...
            optional.UIMode, optional.CommandLineMode, isUserSetOutput,...
            optional.HelpName, optional.HelpTopicId);
    end
end

function diagObj = createDiagnosticObj(diagnostics, messageFills)
    if isa(diagnostics, "MException") || isa(diagnostics, "message")
        diagObj = diagnostics;
    else
        if ~isempty(messageFills)
            diagObj = makeMessage(diagnostics, messageFills);
        else
            diagObj = makeMessage(diagnostics);
        end
    end
end

function [msg, category, severity, transient] = getDisplayMessageAndCategory(diagObj, severity, transient)
    if isa(diagObj, "MException")
        msg = getReport(diagObj, 'basic');
        category = diagObj.identifier;
        severity = diagram.notifier.NotificationSeverity.Error;
        transient = false;
    elseif isa(diagObj, 'string') || isa(diagObj, 'char')
        % ex, Success
        msg = diagObj;
        category = diagObj;
    else
        msg = diagObj.getString();
        category = diagObj.Identifier;
    end
end

function msg = makeMessage(varargin)
    [varargin{:}] = convertStringsToChars(varargin{:});
    msg = message([varargin{1}], varargin{2:end});
end

%% Validation functions
function mustBeMessageOrExceptionOrMessageId(args)
    if isa(args, "MException") || isa(args, "message")
        return;
    elseif isa(args, "string") || isa(args, 'char')
        try
            % will throw if the string is in a wrong format for a MessageId
            msg = message(args);
            return;
        catch me
            throwAsCaller(me);
            return;
        end
    end
    eidType = 'diagram_editor_registry:General:MustBeMessageExceptionOrMessageId';
    msgType = message(eidType);
    throwAsCaller(MException(eidType,msgType));
end

function mustFillMessage(msg, args)
    if isa(msg,"message") || isa(msg, "MException") || isempty(args)
        return; % Will ignore messageFills
    elseif  ~iscell(args) && ~isa(args, "string") && ~isa(args, 'char')
        eidType = 'diagram_editor_registry:General:MustFillMessageCorrectly';
        msgType = message(eidType);
        throwAsCaller(MException(eidType,msgType));
    end
    try
        if iscell(args)
            msgObj=makeMessage(msg, args{:});
        else
            msgObj=makeMessage(msg, args);
        end
        msgObj.getString;
    catch me
        throwAsCaller(me);
    end
end

function mustNotBeBothFalse(modes)
    if ~(modes(1) || modes(2))
        eidType = 'diagram_editor_registry:General:MustSetOutputMode';
        msgType = message(eidType);
        throwAsCaller(MException(eidType,msgType));
    end
end

function mustBeUUIDOrEmpty(args)
    if isempty(args) || all(args == "")
        return;
    end
    eidType = 'diagram_editor_registry:General:MustSetNotificationTarget';
    msgType = message(eidType);

    function validate(input)
        if ~isUuid(input)
            throwAsCaller(MException(eidType,msgType));
        end
    end
    
    function isvalid = isUuid(uuid)
        isvalid = false;
        if (uuid.strlength ~= 36)
            return;
        end
        % Check if it is a 128-bit UUID
        numBits = numel(regexpi(uuid, '[0-9A-F]')) * 4;
        isvalid = numBits == 128;
    end
    args = string(args);
    arrayfun(@(uuid) validate(uuid), args);
end
