function showUpperTrianglePlots(hObj)
%

%   Copyright 2015-2020 The MathWorks, Inc.

if hObj.ShowView
    ag = hObj.Axes;
    nr = hObj.Model.NumRows;
    if ~hObj.ShowUpperTrianglePlots
        for i = 1:nr
            ag.AxesVisibility(i,i+1:end) = {'off'};
        end
    else
        for i = 1:nr
            ag.AxesVisibility(i,i+1:end) = {'on'};
        end
    end
end
end
