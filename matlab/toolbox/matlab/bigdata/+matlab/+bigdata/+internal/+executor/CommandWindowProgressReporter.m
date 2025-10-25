%CommandWindowProgressReporter
% Class that prints progress update messages to the command window.
%
% This will print and update in place a progress status line per pass. This
% will also print an overall progress percentage. This will appear as:
%
% Evaluating tall expression using the Local MATLAB Session:
%  - Pass 1 of 3: Completed in 1.2 mins
%  - Pass 2 of 3: 80% complete
% Evaluation 54% complete
%
% In environments that do not support backspace, this will show one line
% per progress update event:
%
% Evaluating tall expression using the Local MATLAB Session:
% - Pass 1 of 2: 0% complete
% - Pass 1 of 2: 50% complete
% - Pass 1 of 2: 75% complete
% - Pass 1 of 2: Completed in 4 sec
% - Pass 2 of 2: 0% complete
% - Pass 2 of 2: 50% complete
% - Pass 2 of 2: 100% complete
% - Pass 2 of 2: Completed in 4 sec
% Evaluation completed in 8 sec

%   Copyright 2016-2023 The MathWorks, Inc.

classdef (Sealed) CommandWindowProgressReporter < matlab.bigdata.internal.executor.ProgressReporter
    properties (Access = private)
        % The number of characters that we need to remove in order to
        % overwrite an existing progress message in the command window.
        NumInPlaceCharacters = 0;
        
        % The number of tasks of the current execution.
        NumTasks
        
        % The number of tasks that require a full pass of the source data.
        NumPasses;
        
        % The number of completed tasks.
        NumCompletedTasks;
        
        % The number of completed passes.
        NumCompletedPasses;
        
        % Whether the current task is a full pass through the underlying
        % data.
        IsFullPass;
        
        % The output of tic at task beginning.
        CurrentPassTic;
        
        % The output of tic at execution beginning.
        OverallTic;
        
        % Stores the previous progress value which is used to determine
        % whether to update the execution progress report.
        PreviousProgressValue;
    end
    
    properties (GetAccess = private, SetAccess = immutable)
        % Logical flag specifying if this object should use in-place logic.
        % This exists to disable progress reporting on the same line for
        % environments that do not support backspace.
        UseInplace (1,1) logical = true;
    end
    
    properties (Constant)
        % This class considers tasks that do a full pass of the underlying
        % data to be more costly than tasks that do not. This constant
        % is for the purposes of the overall percentage, it specifies how
        % many ordinary tasks that a a full pass task is equivalent to.
        PassProgressWeight = 10;
    end
    
    methods
        function obj = CommandWindowProgressReporter(useInplace)
            % Construct a CommandWindowProgressReporter. This exposes the
            % useInplace property for testing purposes.
            if nargin
                obj.UseInplace = useInplace;
            else
                obj.UseInplace = ...
                    ~isdeployed ...
                    && iIsLocalCommandWindow() ...
                    && ~feature('isdmlworker');
            end
        end
        
        function startOfExecution(obj, name, numTasks, numPasses)
            obj.NumInPlaceCharacters = 0;
            obj.NumTasks = numTasks;
            obj.NumPasses = numPasses;
            obj.NumCompletedTasks = 0;
            obj.NumCompletedPasses = 0;
            obj.IsFullPass = false;
            obj.OverallTic = tic;
            
            % We don't append a newline character to the header as one will
            % be appended by the footer.
            fprintf('%s', getString(message('MATLAB:bigdata:executor:ProgressBegin', name)));
            if obj.UseInplace
                obj.addFooter();
            else
                fprintf('\n');
            end
        end
        
        function startOfNextTask(obj, isFullPass)
            obj.IsFullPass = isFullPass;
            obj.CurrentPassTic = tic;
            obj.PreviousProgressValue = -inf;
            obj.progress(0);
        end
        
        function progress(obj, progressValue)
            if progressValue <= obj.PreviousProgressValue
                return;
            end
            
            newText = obj.generateOverallProgressString(progressValue);
            if obj.IsFullPass
                newText = {obj.generatePassProgressString(progressValue), newText};
                newText(newText == "") = [];
                newText = strjoin(newText, newline);
            end
            
            obj.updateInplaceText(newText);
            obj.PreviousProgressValue = progressValue;
        end
        
        function endOfTask(obj)
            if obj.IsFullPass
                % We want to leave each pass progress line once
                % completed.
                obj.updateInplaceTextAndFix(obj.generatePassCompleteString());
                
                obj.NumCompletedPasses = obj.NumCompletedPasses + 1;
            end
            obj.NumCompletedTasks = obj.NumCompletedTasks + 1;
            obj.addFooter();
        end
        
        function endOfExecution(obj)
            obj.updateInplaceTextAndFix(obj.generateOverallCompleteString());
        end
    end
    
    methods (Access = private)
        % Add the footer to the progress update in-between tasks. This is
        % not necessary during tasks because task update includes this
        % string already.
        function addFooter(obj)
            obj.updateInplaceText(obj.generateOverallProgressString(0));
        end
        
        % Update the in-place text to the new text. All future updates will
        % overwrite the text from this call.
        function updateInplaceText(obj, newText)
            if obj.UseInplace
                % We do the entire update with a single fprintf as this
                % prevents flickering.
                %
                % Additionally, sprintf is used to preformat the string prior to the call to fprintf.
                % This ensures that the entire string is displayed at one time. See g1893220 for more details
                fprintf('%s', sprintf([repmat('\b', 1, obj.NumInPlaceCharacters), '\n%s'], newText));
                obj.NumInPlaceCharacters = numel(newText) + 1;
            elseif ~isempty(newText)
                % Write the new text on a new line when deployed so that
                % control characters do not appear in the output.
                fprintf('%s\n', newText);
            end
        end
        
        % Update the in-place text to the new text and then convert the
        % in-place text to be permanent. All future updates will appear
        % below the text from this call.
        function updateInplaceTextAndFix(obj, newText)
            if obj.UseInplace
                obj.updateInplaceText(sprintf('%s\n', newText));
                % Note inplace part of the text is set to just the newline
                % character. This is so that, if a user enters a command midway
                % through tall gather, progress reporting jumps to the next new
                % line.
                obj.NumInPlaceCharacters = 1;
            elseif ~isempty(newText)
                fprintf('%s\n', newText);
            end
        end
        
        % Generate a progress line for a pass in progress.
        function text = generatePassProgressString(obj, progressValue)
            if isnan(obj.NumPasses)
                text = getString(message('MATLAB:bigdata:executor:ProgressPassUpdate', ...
                    obj.NumCompletedPasses + 1, sprintf('%.0f', progressValue * 100)));
            else
                text = getString(message('MATLAB:bigdata:executor:ProgressPassWithNumPassesUpdate', ...
                    obj.NumCompletedPasses + 1, obj.NumPasses, sprintf('%.0f', progressValue * 100)));
            end
        end
        
        % Generate a progress line for a pass in progress.
        function text = generatePassCompleteString(obj)
            numSeconds = toc(obj.CurrentPassTic);
            if isnan(obj.NumPasses)
                text = getString(message('MATLAB:bigdata:executor:ProgressPassComplete', ...
                    obj.NumCompletedPasses + 1, matlab.bigdata.internal.util.generateTimeString(numSeconds)));
            else
                text = getString(message('MATLAB:bigdata:executor:ProgressPassWithNumPassesComplete', ...
                    obj.NumCompletedPasses + 1, obj.NumPasses, matlab.bigdata.internal.util.generateTimeString(numSeconds)));
            end
        end
        
        % Generate the overall completion line while execution in is progress.
        function text = generateOverallProgressString(obj, progressValue)
            if ~obj.UseInplace || isnan(obj.NumPasses) || isnan(obj.NumTasks)
                text = '';
                return;
            end
            
            currentTaskProgressWeight = 1;
            if obj.IsFullPass
                currentTaskProgressWeight = obj.PassProgressWeight;
            end
            
            weightedProgress = obj.NumCompletedTasks + obj.NumCompletedPasses * (obj.PassProgressWeight - 1) + progressValue * currentTaskProgressWeight;
            weightedTotal = obj.NumTasks + (obj.PassProgressWeight - 1) * obj.NumPasses;
            overallProgress = weightedProgress / weightedTotal;
            if isnan(overallProgress)
                overallProgress = 0;
            end
            
            text = getString(message('MATLAB:bigdata:executor:ProgressOverallUpdate', ...
                sprintf('%.0f', overallProgress * 100)));
            text = [text newline];
        end
        
        % Generate the overall completion line when execution is finished
        function text = generateOverallCompleteString(obj)
            numSeconds = toc(obj.OverallTic);
            text = getString(message('MATLAB:bigdata:executor:ProgressOverallComplete', ...
                matlab.bigdata.internal.util.generateTimeString(numSeconds)));
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tf = iIsLocalCommandWindow()
% Is the Command Window part of the MATLAB Desktop, or remote to the
% process?
import matlab.internal.capability.Capability
tf = Capability.isSupported(Capability.LocalClient);
end
