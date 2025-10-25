% function peaksIdx = peaks3D(p,datasetIndex,NPeaksOverride)
% % Determine 3D peak locations as an Nx2 matrix of indices.
% %
% % Used for peak markers, and also for antenna lobe computation.
% % Antenna needs all peaks, so there is an override for that.
% %
% % peaksIdx is [angIdx magIdx],
% %    which is [colIdx rowIdx] or [x y]
% 
% % We assume there is only one dataset when dealing with
% % intensity matrix (3D data):
% assert(isempty(datasetIndex) || (datasetIndex == 1))
% 
% pdata = getDataset(p,datasetIndex);
% im = pdata.intensity;
% 
% im_max = max(im(:));
% im_min = min(im(:));
% im = uint16((im-im_min)./(im_max-im_min) .* 65535);
% 
% % Precondition data for peak detection
% % - pad columns using overlap to "wrap around circle"
% % - repeat 20% of the angle span on each end
% % - only do if dataset angles are contiguous at endpoints
% Nc = size(im,2); % # angles / columns
% if ~pdata.angGapAtEnd
%     No = min(3,Nc); % wrap 3 columns on each side, or fewer
%     if No > 0
%         % Pad matrix columns
%         im = [im(:,end-No+1:end) im im(:,1:No)];
%     end
% else
%     No = 0; % no overlap padding
% end
% 
% % Compute peaks
% args2 = getPeaksArgs3D(p,im);
% peaksIdx = internal.findpeaks2d(im,args2{:});
% 
% % Reorder peak indices according to descending data intensity.
% % continuing to use our padded matrix:
% %
% % sub2ind takes ROW,COL indices, in that order - same as MATLAB
% linidx = sub2ind(size(im),peaksIdx(:,1),peaksIdx(:,2));
% [~,pkIdx] = sort(im(linidx),'descend');
% peaksIdx = peaksIdx(pkIdx,:);
% 
% % Only retain highest peaks:
% if nargin > 2
%     Npeaks = NPeaksOverride;
% else
%     Npeaks = p.pPeaks(datasetIndex);
% end
% if ~isinf(Npeaks)
%     % Retain the smaller of:
%     %  - requested # of peaks
%     %  - actual peaks found
%     NpksKeep = min(Npeaks, size(peaksIdx,1));
%     peaksIdx = peaksIdx(1:NpksKeep,:);
% end
% 
% % At this point, peaksIdx is [row col] indices ... not the
% % usual order for images.
% %
% % Adjust peak indices to account for columns that were
% % temporarily added, and remove any peaks found in those
% % temporary columns.  These indices work with pdata.intensity,
% % and not with "im" above.
% peaksIdx(:,2) = peaksIdx(:,2) - No;
% cols = peaksIdx(:,2); % get column indices
% peaksIdx(cols < 1 | cols > Nc, :) = [];
% 
% % Now ensure peaksIdx returns
% %   [angIdx magIdx] or [colIdx rowIdx],
% % which is the fliplr of what we have:
% peaksIdx = fliplr(peaksIdx);
