function [info_bits, crc_error] = decoder(llr, params)
    assert(numel(llr)==params.rate_matched_len,'LLR length does not match frame parameters.');
    validateattributes(llr,{'numeric'},{'real','finite','vector'});
    llr=double(llr(:));
    enabled=~isfield(params,'coding_enabled')||params.coding_enabled;
    if ~enabled
        assert(numel(llr)>=params.tb_crc_len,'Uncoded LLR block is too short.');
        block=int8(llr(1:params.tb_crc_len)>0);
    elseif strcmp(params.coding_backend,'manual')
        recovered=turbo_rate_recover_manual(llr,params.tb_len,params.rv);
        block=turbo_decode_manual(recovered{1},params.turbo_num_iter);
    else
        recovered=lteRateRecoverTurbo(double(llr(:)),params.tb_len,params.rv);
        block=lteTurboDecode(recovered{1},params.turbo_num_iter);
    end
    if strcmp(params.coding_backend,'manual')
        [info_bits,crc_error]=crc24a_decode_manual(block);
    else
        [info_bits,crc_error]=lteCRCDecode(block,params.crc_poly);
    end
    info_bits=int8(info_bits(:));
end
