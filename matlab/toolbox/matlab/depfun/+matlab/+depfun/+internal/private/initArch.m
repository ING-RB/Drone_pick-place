function arch = initArch()

if ~isempty(getenv('MW_TARGET_ARCH'))
    arch = getenv('MW_TARGET_ARCH');
else
    arch = computer('arch');
end

end