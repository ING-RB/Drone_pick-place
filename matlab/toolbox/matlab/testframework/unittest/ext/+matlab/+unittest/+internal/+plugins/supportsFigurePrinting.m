function bool = supportsFigurePrinting()
%This function is undocumented and may change in a future release.

%Copyright 2016-2020 The MathWorks, Inc.
try
    figureHandle = figure('Visible','off');
    close(figureHandle);
catch ME
	% Handling only the no JVM exception in here, so if there were
	% other failures, with respect to figure generation in no JVM
	% environment, it can be caught.

    if(isequal(ME.identifier, 'MATLAB:HandleGraphics:noJVM'))
        bool = false;
        return;
    end
end
bool = true;
end