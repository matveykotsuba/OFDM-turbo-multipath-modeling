function [codedBits, info] = encoder(bits, params)
    assert(numel(bits)==params.tb_len,'Information length does not match frame parameters.');
    if strcmp(params.coding_backend,'manual')
        crcBits=crc24a_encode_manual(bits);
    else
        crcBits=lteCRCEncode(int8(bits(:)),params.crc_poly);
    end
    enabled=~isfield(params,'coding_enabled')||params.coding_enabled;
    if enabled
        if strcmp(params.coding_backend,'manual'),turboBits=turbo_encode_manual(crcBits);
        else,turboBits=lteTurboEncode(crcBits);end
        codedBits=puncture(turboBits,params.rate_matched_len,params.rv,params.coding_backend);
        paddingLength=0;
    else
        turboBits=[];
        paddingLength=params.rate_matched_len-numel(crcBits);
        assert(paddingLength>=0,'Uncoded block does not fit the selected resource allocation.');
        codedBits=[double(crcBits);zeros(paddingLength,1)];
    end
    assert(numel(codedBits)==params.rate_matched_len,'Rate matching length mismatch.');
    if nargout>1,info=struct('enabled',logical(enabled),'crcEnabled',true, ...
        'paddingLength',paddingLength,'crcBits',crcBits,'turboBits',turboBits,'rateMatchedBits',codedBits);end
end
