function [v, varargout] = splineEvalNd(breaks, val, coefs, x)
% evaluation on a mesh

%#codegen

nd = length(breaks);

sizec = size(coefs);

varargout{nd+1} = coefs; 
sizev = sizec;
nsizev = zeros(1,nd);
coder.unroll(coder.internal.isConst(nd));
for i = nd:-1:1
    nsizev(i) = length(x{i}(:));
    dd = coder.internal.prodsize(varargout{i+1}, 'below', nd+1); % prod(sizev(1:nd));

    if size(val,i) == 2
        temp = reshape( ppval(mkpp([breaks{i}(1), breaks{i}(end)], reshape(varargout{i+1},dd,2), dd), x{i}), ...
            [sizev(1:nd),nsizev(i)]);
    elseif size(val,i) == 3
        temp = reshape( ppval(mkpp([breaks{i}(1), breaks{i}(end)], reshape(varargout{i+1},dd,3), dd), x{i}), ...
            [sizev(1:nd),nsizev(i)]);
    else
        temp = reshape( ppval(mkpp(breaks{i}, reshape(varargout{i+1},dd*(size(val,i)-1),4), dd), x{i}), ...
            [sizev(1:nd),nsizev(i)]);
    end

    sizev(nd+1) = nsizev(i);
    
    varargout{i} = permute(temp, coder.const([1,nd+1,2:nd])); 
    sizev(2:nd+1) = sizev([nd+1,2:nd]);
end

szOut = output_size(nd, val, x);
v = coder.nullcopy(zeros(szOut, 'like', val));
vcols = sizev(1);
vrows = numel(v)/vcols;
k = 1;
for i = 1:vrows
    for j = 0:vcols-1
        v(i + vrows*j) = varargout{1}(k);
        k = k+1;
    end
end

%--------------------------------------------------------------------------

function sz = output_size(nd, val, x)
coder.inline('always');
sz = size(val);
for k = 1:nd
    sz(k) = numel(x{k});
end
