function figureBecameStable = waitForFigurePositionIsStable(fig)
%
% Note:
%     This function does not guarantee that a figure window will reach a requested size or location.
%
%  Example 1:
%    % After Figure Creation
%     f=figure;
%     ax=axes;
%     matlab.ui.internal.waitForFigurePositionToSettle(f);
%     % Code that requires a stable figure
%
%  Example 2:
%      f=figure;
%    % After changing the Figure position
%      set(f,'Position',[100 100 400 400]);
%      matlab.ui.internal.waitForFigurePositionToSettle(f);
%      get(f,'Position');


%initialize values of maxTimeout and eventTimeOut in seconds
% I chose a max timeout of 5 seconds. I poll for a size or location update
% change for intervals of 0.5s at a time. May need adjustment
constEventTimeOut = 0.5;
maxTimeout = 5;

%Keeps track of how many size/location changed events come in
changeCount = 0;

% Check if the input is a Figure handle
if ~(isequal(class(fig),'matlab.ui.Figure'))
    error('HG:assertFigurePositionIsStable:IncorrectHandle','Input must be a figure')
end

% Attach size and location change listeners
lsnrs(1) = addlistener(fig,'SizeChanged',@eventFired);
lsnrs(2) = addlistener(fig,'LocationChanged',@eventFired);

% delete listeners on exit
oncln = onCleanup(@()delete(lsnrs));

% Initial status set to false to indicate that figure has not settled into
% its final position
status_return = false;

start_time = tic;

% Run polling function within a while loop
while toc(start_time) < maxTimeout
    % repeatedly call polling function to determine if position changed
    % events are still coming in. Run this polling function continuously
    % until we either no longer detect a position changing event within a
    % certain smaller "event timeout" period, or time out of the main
    % polling loop
    status_return = isFigureStable(constEventTimeOut);

    % If the inner polling function returns that the figure has stabilized,
    % we are done and can break out of the loop
    if status_return
        break;
    end
end

drawnow;
figureBecameStable = status_return;

    function eventFired(~,ev)
        % This function is a xallback for events when they get fired. We
        % keep track of count and wait for this count to stabilize which
        % indicates the figure has settled
        changeCount = changeCount + 1;
    end

    % This is the inner polling function of the main while loop
    % This function polls for a position change event. If such an event is
    % received, then we will break out of this polling loop, and re-enter
    % it given we have not timed out yet. If no change has occurred and we
    % have timed out of this polling loop, then the figure Position is
    % assumed to have settled
    function status = isFigureStable(eventTimeOut)
        % Status=true, if no change has occured

        % set status to be true intially, to say that the figure has not
        % settled
        status = true;

        % Keep track of time in this loop
        start_time2 = tic;
        while toc(start_time2) < eventTimeOut
            status = hasChangeOccurred(changeCount);
            % always call drawnow to make sure we have pushed through all system events
            drawnow;

            % if the status is true, that means the figure can not be
            % assumed to have finished resizing. break out of this loop and
            % rerun this polling function assuming we have not timed out
            % yet. If status is false, this suggests the figure may have
            % settled, but we should keep checking until this inner polling
            % function times out to be as sure as possible.
            if status
                break;
            end
        end

        % Flip and return value of "status". The value of status in this
        % function indicates "has the figure continued to receive
        % instructions to change its position?". Inversely, the return
        % value should tell us "has the figure stopped hearing instructions
        % to change/has the figure settled?"
        status = ~status;
        
        % This function below gives us an idea of if the figure has
        % settled. If the change count does not increase over multiple
        % checks, we can assume the figure to have settled
        function status = hasChangeOccurred(initialCount)
            status = changeCount > initialCount;
        end
    end

end