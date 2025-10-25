% function shortcuts(p) % Vish
% % POLARPATTERN supports keyboard shortcuts to access some options.
% % Shortcuts execute on the selected trace or on other plot
% % elements when the mouse pointer hovers over the axes.
% %           ?  Display keyboard shortcuts
% %           c  Add cursor
% %           k  Display keywords for titles/labels
% %           m  Toggle antenna metrics
% %           s  Toggle angle-span display
% %           +  Increase font size
% %           -  Decrease font size
% %      0 to 9  Show # peaks (+shift applies to all traces)
% %  Left/Right  Rotate axes  (+ctrl for fine steps)
% %     Up/Down  Adjust maximum magnitude
% %              (+shift for minimum, +ctrl for fine steps)
% %      Delete  Remove or hide
% %   Backspace  Remove or hide
% %
% % See also polarpattern, <a href="matlab:help internal.polari/LegendLabels">LegendLabels</a>, <a href="matlab:help internal.polari/formats">formats</a>, <a href="matlab:help internal.polari/multiaxes">multiaxes</a>.
% 
% if nargin > 0
%     showBannerMessage(p,'Keyboard shortcuts shown in the command window.');
% end
% help internal.polari/shortcuts
