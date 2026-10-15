function coded_bits_rm = puncture(coded_bits_full, outlen, rv, backend)
    if nargin<3||isempty(rv),rv=0;end
    if nargin<4||isempty(backend),cfg=coding_config();backend=cfg.backend;end
    cfg=coding_config(struct('backend',backend));
    if strcmp(cfg.backend,'manual')
        coded_bits_rm=turbo_rate_match_manual(coded_bits_full,outlen,rv);
    else
        coded_bits_rm=lteRateMatchTurbo(double(coded_bits_full(:)),outlen,rv);
    end
end
