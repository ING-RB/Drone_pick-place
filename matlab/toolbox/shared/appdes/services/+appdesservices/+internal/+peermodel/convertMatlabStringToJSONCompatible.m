function jsonCompatible = convertMatlabStringToJSONCompatible(matlabString)
% Currently, the client-side infrastructure(specifically for the TreeNode'
% NodeId usecase for now), requires MATLAB String to be an array on the
% client-side
jsonCompatible = cellstr(matlabString);
end