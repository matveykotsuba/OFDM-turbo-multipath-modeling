function recovered_blocks = depuncture(llr_rate_matched, tb_len, rv, backend)
    if nargin<3||isempty(rv),rv=0;end
    if nargin<4||isempty(backend),cfg=coding_config();backend=cfg.backend;end
    cfg=coding_config(struct('backend',backend));
    if strcmp(cfg.backend,'manual')
        recovered_blocks=turbo_rate_recover_manual(llr_rate_matched,tb_len,rv);
    else
        recovered_blocks=lteRateRecoverTurbo(double(llr_rate_matched(:)),tb_len,rv);
    end
end
