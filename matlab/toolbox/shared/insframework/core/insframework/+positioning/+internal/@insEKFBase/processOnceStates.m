function once = processOnceStates(sensorClasses)
% Create a struct of states from the list of classes CLS. Collect states
% once for each class, not each class instance.

%   Copyright 2021 The MathWorks, Inc.


% Return
%   once - cell array length of cls, each cell is a cell array of
%   fieldnames of states that appear only once


% Extrinsic. No codegen concerns


Nin = numel(sensorClasses);
once = cell(1,Nin);
for ii=1:Nin
    once{ii} = invoke( sensorClasses{ii}, 'commonstates');
end

end


function x = invoke(cls, meth, varargin)
fcn = [cls '.' meth];
x = feval(fcn, varargin{:});
end
