classdef TrimmedException < MException
    %TRIMMEDEXCEPTION MException that removes App Designer internal frames

    % Copyright 2015-2021 The MathWorks, Inc.

    properties (Access = protected)
        OriginalException
    end

    methods
        function obj = TrimmedException(originalException)

            % Call MException constructor to setup the identifier and
            % message properties
            obj@MException(originalException.identifier, '%s', originalException.message);

            % Update the type to be the same as the input MException. This
            % needs to be done so that getReport() works properly.
            obj.type = originalException.type;

            % Update the cause field to be the same as the input MException
            % This needs to be done so that getReport() works properly.
            for i=1:length(originalException.cause)
                obj = addCause(obj,originalException.cause{i});
            end

            obj.OriginalException = originalException;
        end

        function report = getReport(obj, varargin)
            % STACK = GETREPORT(OBJ, VARARGIN) This method overrides the
            % inherited GETREPORT method from MException.

            % Before returning the report from MException, need to reset
            % the type to that of the original exception so that the report
            % message is correct. This is necessary because the type gets
            % modified when "throw" is executed (g1484207).
            obj.type = obj.OriginalException.type;
            report = getReport@MException(obj, varargin{:});
        end

    end

    methods (Access = protected)
        function stack = getStack(obj)
            % STACK = GETSTACK(OBJ) This method overrides the inherited
            % GETSTACK method from MException. It returns the original
            % stack. It is necessary to override this method so that the
            % method GETREPORT generates the correct message.

            stack = trimStack(obj, obj.OriginalException.stack);

            % Stack should be column vector
            if isrow(stack)
                stack = stack';
            end
        end

        function stack = trimStack(~, stack)
            % STACK = TRIMSTACK(OBJ, STACK) This method trims an
            % MException stack by removing frames that show the inner
            % workings of the callback handling which adds no value.

            appDesignerRoot = ...
                fullfile(matlabroot,'toolbox','matlab','appdesigner','appdesigner');

            % Find and remove all the app designer internal code frames
            % plus all of the frames after the last app designer internal
            % code frame.
            hits = strfind({stack.file}, appDesignerRoot);
            hits = cellfun(@(c)~isempty(c), hits);
            lastHit = find(hits, 1, 'last');
            if ~isempty(lastHit)
                hits(lastHit:end) = true;
            end
            stack(hits) = [];
            
            % Find and remove anonymous call to startupFcn
            % see g1602207
            anonyStartupFcnHit = cellfun(@(c)regexp(c, '^@\(app\)\w*\(app,\s*varargin{:}\)'), ...
                {stack.name}, 'UniformOutput', false);
            anonyStartupFcnHit = cellfun(@(c)~isempty(c), anonyStartupFcnHit);
            stack(anonyStartupFcnHit) = [];
        end
    end

    methods (Access = protected, Static)
        function cleanMessage = cleanMessageForClient(message)
            % Cleans the error message to render properly in the client

            % Escape < and > symbols if they are not used for an anchor
            % tag. The command window only renders html anchor tags and
            % nothing else and so want to have the same behavior in App
            % Designer.

            % First, find the < symbols and look ahead to see if they
            % belong to the opening or closing of an anchor tag. If not,
            % then replace < with &lt;
            cleanMessage = regexprep(message, '<(?!a href=".*"|/a)', '&lt;');
            
            % Second, find the > symbols and look behind to see if they are
            % the opening or closing of an anchor tag. If not, then replace
            % > with &gt;
            cleanMessage = regexprep(cleanMessage, '(?<!<a href=".*"|/a)>', '&gt;');
        end
    end
end
