function name=prodnum2externalname(prodnum)
name = [];
mustBeScalarOrEmpty(prodnum);
if isempty(prodnum)
    return
end
pcm = matlab.depfun.internal.requirementsConstants.pcm_nv;
prodinfo = pcm.productInfo(prodnum);
if ~isempty(prodinfo)
    name=prodinfo.extPName;
end
