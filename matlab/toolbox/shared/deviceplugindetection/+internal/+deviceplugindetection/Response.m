classdef Response
% Response Enumeration class for device detection handlers responses.
%
%   This class defines an enumerated response to be returned by device
%   plugin detection client subclasses in the handler methods.

% Copyright 2015 The MathWorks, Inc.

enumeration
    % Handled - The client fully handled the event, so stop any further
    %   processing.
    Handled
    % HandledButContinue - The client took some action, but continue
    %   calling to subsequent subclasses.
    HandledButContinue
    % NotHandled - The client took no action on the event.
    NotHandled
end

end
