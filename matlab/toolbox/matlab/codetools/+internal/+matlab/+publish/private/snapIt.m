function myFrame = snapIt(f,getframeArgs)
% Bring the figure to the front and snap it.
set(0,'ShowHiddenHandles','on');
figure(f);
drawnow
set(0,'ShowHiddenHandles','off');
drawnow
try
    % Suppress warning thown by getframe for capturing uihtml components
    warnstate = warning('off', 'MATLAB:print:UIHTMLNotCaptured');
    myFrame = getframe(f,getframeArgs{:});
    % Restore the original warning state
    warning(warnstate);
catch e
    % GETFRAME can error if the figure is off the screen.
    warning(e.identifier, '%s', e.message)
    myFrame.cdata = 255*ones(10,10,3,'uint8');
    myFrame.colormap = [];
end
end