classdef MessageHandler < asyncioimpl.MessageHandler
% MessageHandler Handler for error/warning/trace messages

% Copyright 2017-2024 The MathWorks, Inc.

    methods(Access='public')

        function onError(obj, data)
        % Implementation of asyncioimpl.MessageHandler.onError()
        % DATA is a struct with the following fields:
        %    isAsync: True if error was sent from any thread other
        %             than the main MATLAB thread.
        %    ID: the error ID
        %    Either one of the following:
        %      Args: This field will exist if it is a "new style" error.
        %            It will be a cell array of arguments used to
        %            construct the message object.
        %    OR
        %      Text: This field will exist if it is an "old style" error.
        %            It will be a character array.

        % If the error was asynchronous, close the channel.
        % We do this to avoid flooding the command line with errors
        % that may still occur on the data transfer threads.
            if data.IsAsync
                obj.Channel.close();
            end

            if matlabshared.asyncio.internal.MessageHandler.isOldStyleMessage(data)
                % Old-style warnings use ID and Text.
                error(data.ID, data.Text);
            else
                % New-style warnings use ID and Args to create message.
                me = MException(message(data.ID, data.Args{:}));
                throwAsCaller(me);
            end
        end

        function onWarning(~, data)
        % Implementation of asyncioimpl.MessageHandler.onWarning()
        % DATA is a struct with the following fields:
        %    ID: the warning ID
        %    Either one of the following:
        %      Args: This field will exist if it is a "new style" warning.
        %            It will be a cell array of arguments used to
        %            construct the warning object.
        %    OR
        %      Text: This field will exist if it is an "old style" warning.
        %            It will be a character array.

            prevState = warning('off','backtrace');
            if matlabshared.asyncio.internal.MessageHandler.isOldStyleMessage(data)
                % Old-style warnings use ID and Text.
                warning(data.ID, data.Text);
            else
                % New-style warnings use ID and Args to create message.
                warning(message(data.ID, data.Args{:}));
            end
            warning(prevState);
        end

        function onTrace(obj, data)
        % Implementation of asyncioimpl.MessageHandler.onTrace()
        % DATA is a struct with the following fields:
        %    One of the following:
        %      Format: This field will exist if it is a "new style" trace.
        %              A string to use for a sprintf format.
        %      Args: This field will exist if it is a "new style" trace.
        %            It will be a cell array of arguments used in
        %            sprintf.
        %    OR
        %      Text: This field will exist if it is an "old style" trace.
        %            It will be a character array.

            if obj.Channel.TraceEnabled
                if matlabshared.asyncio.internal.MessageHandler.isOldStyleMessage(data)
                    % Old-style traces use Text.
                    disp(data.Text);
                else
                    % New-style traces use Format and Args
                    disp(sprintf(data.Format, data.Args{:})); %#ok<DSPS>
                end
            end
        end
    end

    methods(Static)
        function oldStyle = isOldStyleMessage(data)
            oldStyle = isfield(data,'Text');
        end
    end

    methods(Static, Hidden)
        function lock()
            mlock;
        end
    end

    properties(WeakHandle, GetAccess='protected', SetAccess=?matlabshared.asyncio.internal.Channel, Transient)
        % The matlabshared.asyncio.internal.Channel for which we are handling messages.
        Channel (1,1) matlabshared.asyncio.internal.Channel
    end
end

% LocalWords:  asyncioimpl
