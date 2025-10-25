function setDataTips(plot_I)
    % Customize the data tips for the plot object by setting them to the
    % corresponding axes labels
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2023 The MathWorks, Inc.

    % Set from x and y axes labels
    plot_I.DataTipTemplate.DataTipRows(1).Label = plot_I.Parent.XLabel.String;
    plot_I.DataTipTemplate.DataTipRows(2).Label = plot_I.Parent.YLabel.String;

    % Check for z axes label and data
    expNumel = 2;
    if ~isempty(char(plot_I.Parent.ZLabel.String))
        plot_I.DataTipTemplate.DataTipRows(3).Label = plot_I.Parent.ZLabel.String;
        expNumel = 3;
    end

    % Remove any unwanted data tip rows (size, alpha, etc.)
    if numel(plot_I.DataTipTemplate.DataTipRows) > expNumel
        plot_I.DataTipTemplate.DataTipRows(expNumel+1:end) = [];
    end
end
