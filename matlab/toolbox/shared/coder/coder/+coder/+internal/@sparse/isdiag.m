function bool = isdiag(A)
%MATLAB Code Generation Private Method

%   Copyright 2022 The MathWorks, Inc.
%#codegen
for c = 1:A.n
    if (A.colidx(c+1) - A.colidx(c)) > 1
        %too many elements in this column
        bool = false;
        return
    end
    if A.colidx(c) ~= A.colidx(c+1) %else zero column
        if A.rowidx(A.colidx(c)) ~= c
            %not on the diagonal
            bool = false;
            return
        end
    end
end
bool = true;


end