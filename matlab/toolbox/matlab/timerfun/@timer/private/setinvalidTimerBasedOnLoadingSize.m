function timerObj = setinvalidTimerBasedOnLoadingSize(B)
%SETINVALIDTIMERBASEDONLOADINGSIZE outputs invalid timer based on the input
% loaderobj B's size information.
% The output size of timerObj is in vector form.
%
%    Copyright 2021 The MathWorks, Inc.

sizeOfObj = assumeSizeOfObj(B);
timerObj(sizeOfObj) = timer;
numElems = sizeOfObj(2);
delete(timerObj(1:numElems));
end

function sizeOfObj = assumeSizeOfObj(B)
if isempty(B.jobject)
    if isfield(B, 'ud') && ~isempty(B.ud)
        sizeOfObj = size(B.ud);
    else
        sizeOfObj = [1 1];
    end
else
    sizeOfObj = size(B.jobject);
end
% List of Timers are assumed to be in vector form. 
% so, ensure no matter whether
%     B.ud - which is in column major orientation
%     B.jobject - which is in row major orientation
% is used, we convert the size to vector form/row-major orientation
if (sizeOfObj(1) > sizeOfObj(2))
    sizeOfObj = fliplr(sizeOfObj);
end

end