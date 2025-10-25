function [datatype,prototype] = updateDatatype(datatype,matrix,solverID,matstring)
    % helper to get superiorfloat and prototype for data with a new matrix,
    % plus warn if the datatype is different from the matrix.
    if ~strcmp(datatype,class(matrix)) % warn if matrix class doesn't match current datatype
        input1 = "'t0', 'y0', 'f(t0,y0)'";
        input2 = matstring;
        warning(message('MATLAB:odearguments:InconsistentDataType',input1,input2,solverID));
    end
    datatype = superiorfloat(zeros(datatype),matrix);
    prototype = zeros(datatype);
end
%   Copyright 2024 The MathWorks, Inc.