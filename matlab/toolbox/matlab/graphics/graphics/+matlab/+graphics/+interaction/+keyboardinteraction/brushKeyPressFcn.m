function keyconsumed = brushKeyPressFcn(ax, evd)
%

%   Copyright 2023 The MathWorks, Inc.

% If the key being pressed corresponds to the delete key, perform the brush and
% return true.
% Else, return false to indicate that the key event was not consumed.
    if strcmp(evd.Key,'delete') 
       localDoBrush(ax);
       keyconsumed = true;
    else
       keyconsumed = false;
    end
   
end

function localDoBrush(ax)
   % Grabs the figure to call isFigureLinked
   es = ancestor(ax,'figure');
   % Set the default value to NaN
   missingValue = NaN;
   % Check if the figure is linked
   if datamanager.isFigureLinked(es)
       internal.matlab.datatoolsservices.executeCmd('matlab.graphics.chart.primitive.brushingUtils.replaceData(gco, NaN)');
   else
       % Determine the type of axis and set the missingValue
       if containsDatetime(ax)
           missingValue = NaT;
       elseif containsCategorical(ax)
           missingValue = categorical(NaN);
       end
       % Call dataEdit to replace the brushed data with missingValue
       datamanager.dataEdit(es, [], [], 'replace', missingValue);
   end
end

function result = containsDatetime(ax)
% Check if the YAxis on the given axis is a datetime ruler
result = isa(ax.YAxis, 'matlab.graphics.axis.decorator.DatetimeRuler');
end

function result = containsCategorical(ax)
% Check if the YAxis on the given axis is a categorical ruler
result = isa(ax.YAxis, 'matlab.graphics.axis.decorator.CategoricalRuler');
end