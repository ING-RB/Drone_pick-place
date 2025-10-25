function brushkeypress(es,ed)

% Copyright 2008-2022 The MathWorks, Inc.

% Key hit callback for MATLAB figures when brushing mode is active.

% Note that we do not need key listeners for undo, redo, or ctrl-c since
% those events are handled by the corresponding menu accelerators.


if strcmp(ed.Key,'delete')
    if datamanager.isFigureLinked(es)
        internal.matlab.datatoolsservices.executeCmd('matlab.graphics.chart.primitive.brushingUtils.replaceData(gco,NaN)');
    else
        datamanager.dataEdit(es,[],[],'replace',NaN);
    end
end



