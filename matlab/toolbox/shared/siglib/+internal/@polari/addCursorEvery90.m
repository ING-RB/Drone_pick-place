% function addCursorEvery90(p,datasetIndex)
% % Adds up to four cursors at data points closest to 0, 90, 180
% % and 270 degrees in data-space.  Sets the detail view of these
% % cursors.
% %
% % If the dataset is such that any of these cursors fall on
% % identical data indices, those duplicate cursors are
% % suppressed.
% %
% % Removes current cursors, but leaves peaks if present.
% %
% % If datasetIndex is empty, set marker to Active Trace;
% % otherwise set marker to specified data index.
% 
% %removeAngleMarkers(p);
% removeAllCursors(p,'all'); % all cursors from all datasets
% 
% angles = [0 90 180 270];
% th = getNormalizedAngle(p,angles);
% Nth = numel(th);
% all_idx = zeros(Nth,1); % invalid indices
% for i = 1:Nth
%     % Find data index nearest to specified angle, and use that
%     % as marker location.
%     
%     % Always add marker, even if duplicate:
%     %m_i = i_addCursor(p,[cos(th(i)) sin(th(i))],datasetIndex);
%     
%     % Add marker only if NOT a duplicate data index:
%     %
%     idx = getDataIndexFromPoint(p,[cos(th(i)) sin(th(i))],datasetIndex);
%     if ~isempty(idx) && ~any(idx == all_idx)
%         all_idx(i) = idx;
%         m_i = addCursorAllArgs(p,idx,datasetIndex);
%         m_i.ShowDetail = 1; % angle/mag
%     end
% end
