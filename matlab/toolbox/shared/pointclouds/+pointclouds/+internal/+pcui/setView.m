function setView(viewTag, currentAxes)

% This method implements the plane of the axes that is visualized by the
% HG camera

    switch viewTag
        case 'XZ'
            view(currentAxes,0,0);
        case 'ZX'
            view(currentAxes,180,0);
        case 'YZ'
            view(currentAxes,90,0);
        case 'ZY'
            view(currentAxes,-90,0);
        case 'XY'
            view(currentAxes,0,90);
        case 'YX'
            view(currentAxes,0,-90);
    end
end