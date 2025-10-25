function newCdata = createRemovedCData(h,keepflag)
% This undocumented function may be removed in a future release.

% Copyright 2021-22 The MathWorks, Inc.

% Compute the result of the property "CData removing brushed data 
% from a graphic object. The following parameter is returned:
% newCdata - Updated CData matrix/array with removedPoints deleted from original 
% CData matrix which can be passed to "set" on the
% graphic object to set the CData.
%
    
    originalCdata = h.CData;
    newCdata = originalCdata;
    originalDataSize = numel(h.BrushData);
    if keepflag
        cdataKeepIds = logical(h.BrushData);
    else
        cdataKeepIds = ~logical(h.BrushData);
    end

    [nRowsCdata,nColsCdata] = size(h.CData);

    % If all cdata to keep or Cdata is numeric or CData 1x3 rgb values
    if all(cdataKeepIds) || numel(h.CData) == 1 || (numel(originalCdata) == 3 && originalDataSize ~= 3)
        newCdata = originalCdata;
        return
    end

    if originalDataSize ~= 3  % rgb size = 3
        % CData could be 1xn, nx1, nx3. 
        % If Cdata is 1xn with Ydata of size n (Values refer to colormap)
        if nColsCdata == originalDataSize
            newCdata = originalCdata(cdataKeepIds);
            % If Cdata is nx1 (colormap) or nx3 (rgb values) array 
            % when Ydata of size n 
        elseif nRowsCdata == originalDataSize
            newCdata = originalCdata(cdataKeepIds,:);
        end
    else
        % CData could be 3x1 (always treated from colormap), 1x3 (rgb) or 3x3 (n x rgb) 
        % CData of size 3x1 or 3x3 ie rgb for each data point
        if nRowsCdata == 3
            newCdata = originalCdata(cdataKeepIds,:);
        else
            % If nRowsCdata ~= 3, it has to be 1x3 rgb array (CData values
            % constrainted)
            newCdata = originalCdata;
        end
    end
end