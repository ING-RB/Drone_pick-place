% function instanceInfo(p)
% % Used to diagnose instance-specific issues with polarpattern.
% 
% ax = p.hAxes;
% if isempty(ax)
%     idx_ax_str = '[]';
%     ax_str = '[]';
% else
%     idx_ax_str = mat2str(getappdata(ax,'PolariAxesIndex'));
%     ax_str = class(ax);
% end
% 
% if isempty(p.hFigure)
%     fig_str = '[]';
% else
%     fig_str = class(p.hFigure);
% end
% 
% % This is a copy of the 'PolariAxesIndex' appdata value set on the
% % axes itself:
% %    p.pAxesIndex = axesIndex;
% %    setappdata(ax,'PolariAxesIndex',axesIndex);
% idx_obj_str = mat2str(p.pAxesIndex);
% 
% fprintf([ ...
%     '\npolarpattern:\n' ...
%     '  - Figure handle (.hFigure): %s\n', ...
%     '  - Axes handle (.hAxes): %s\n', ...
%     '  - Instance index from axes appdata (''PolariAxesIndex''): %s\n', ...
%     '  - Instance index from object (.pAxesIndex): %s\n'], ...
%     fig_str, ax_str, idx_ax_str, idx_obj_str);
% 
% % [EOF]
