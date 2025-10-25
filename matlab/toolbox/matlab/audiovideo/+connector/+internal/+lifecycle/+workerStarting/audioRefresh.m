function audioRefresh
    % Subscribe to the audioRefresh channel which indicates if browser
    % refresh has taken place
    message.subscribe('/audio/audioRefresh', ...
        @(msg)audiovideo.internal.audioplayerOnline.audioRefresh());
end