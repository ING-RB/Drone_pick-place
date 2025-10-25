function focus = adjustInvalidFocus(focus)
arguments
    focus (1,2) double
end

% Checks if focus is a non-increasing 2 element vector
if focus(1) == focus(2)
    if focus(1) == 0
        % If focus is [0 0], adjust to [-1 1]
        focus(1) = -1;
        focus(2) = 1;
    else
        % If focus is [2 2], adjust to [2 - 2/10, 2 + 2/10]
        focus(1) = focus(1) - 0.1*abs(focus(1));
        focus(2) = focus(2) + 0.1*abs(focus(2));
    end
end

% ---- This following piece of code adjusted Inf and NaN values in focus,
% but doesn't seem to be used anymore ---- 
%
% if any(isinf([focus{:}])) ||
% any(isnan([focus{:}]))
%     isInvalid = cellfun(@(x) isinf(x) | isnan(x), focus, UniformOutput=false);
%     for kr = 1:size(focus,1)
%         for kc = 1:size(focus,2)
%             % Check lower limit
%             if isInvalid{kr,kc}(1)
%                 idx = find(cellfun(@(x) ~x(1),isInvalid(kr,:)),1);
%                 focus{kr,kc}(1) = focus{kr,idx}(1);
%             end
%             % Check upper limit
%             if isInvalid{kr,kc}(2)
%                 idx = find(cellfun(@(x) ~x(2),isInvalid(kr,:)),1);
%                 focus{kr,kc}(2) = focus{kr,idx}(2);
%             end
%         end
%     end
% end


end