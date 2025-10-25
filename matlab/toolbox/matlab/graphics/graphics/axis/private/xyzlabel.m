function hh = xyzlabel(labelProp, inputs)

% Parse the inputs and validate the target.
[targets, label, nvPairs] = labelcheck(labelProp, inputs);
label = label{1};

% Chart subclass support
% Invoke xlabel, ylabel, or zlabel method with same number of outputs to defer output arg
% error handling to the method.
if isa(targets,'matlab.graphics.chart.Chart')
    if(nargout == 1)
        hh = feval(lower(labelProp), targets, label, nvPairs{:});
    else
        feval(lower(labelProp), targets, label, nvPairs{:})
    end
    return
end

if isempty(label)
    label = '';
end
appdataName = "MWBYPASS_" + lower(labelProp);
if isscalar(targets) && isappdata(targets,appdataName)
    % Allow Control System Toolbox to overload the xlabel, ylabel, and zlabel command.
    h = mwbypass(targets, appdataName, label, nvPairs{:});
else
    h = reshape([targets.(labelProp)], size(targets));
    if ~isa(targets,'matlab.graphics.layout.Layout')
        set(h,'FontSizeMode','auto',...
            'FontUnitsMode','auto', ...
            'FontWeightMode', 'auto', ...
            'FontAngleMode', 'auto', ...
            'FontNameMode', 'auto', ...
            {'FontWeight_I'},{targets.FontWeight}',...
            {'FontAngle_I'},{targets.FontAngle}',...
            {'FontName_I'},{targets.FontName}');

    end

    try
        set(h, 'String', label, nvPairs{:});
    catch ex
        throw(ex);
    end
end

if nargout > 0
    hh = h;
end
