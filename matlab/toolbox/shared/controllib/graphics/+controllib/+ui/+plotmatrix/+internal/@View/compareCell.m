function compareCell(hObj,newValue,argName)
%

%   Copyright 2015-2020 The MathWorks, Inc.

sz1 = cellfun(@size,hObj.(argName),'UniformOutput',false);
sz2 = cellfun(@size,newValue,'UniformOutput',false);
tf = all(cellfun(@isequal,sz1,sz2));
if ~tf
    error(message('Controllib:plotmatrix:WrongNumElement',argName));
end

% check for undefined labels/showgroups, old: {'a','b','undefined'}, new:{'c','d'}
% tf = cellfun(@isequal,sz1,sz2);
% tf_wrong = find(~tf); 
% if any(tf_wrong)
%     if all(hObj.Model.NanGroup(tf_wrong))
%         for i = 1:numel(tf_wrong)            
%             if sz1{tf_wrong(i)}(1)==sz2{tf_wrong(i)}(1) &&...
%                     sz1{tf_wrong(i)}(2)==sz2{tf_wrong(i)}(2)+1
%                 newValue{tf_wrong(i)}(end+1) = hObj.(argName){tf_wrong(i)}(end);
%             else
%                 error(message('Controllib:plotmatrix:WrongNumElement',argName));
%             end
%         end
%     else
%         error(message('Controllib:plotmatrix:WrongNumElement',argName));
%     end
% end
% output = newValue;
end
