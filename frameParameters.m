function params = frameParameters(cfg)
    cfg=config(cfg);mod_type=cfg.modulation;code_rate=cfg.coding.codeRate;rv=cfg.coding.rv;
    coding=struct('backend',cfg.coding.backend,'turbo_num_iter',cfg.coding.turboNumIter);
    persistent lastCfg lastParams;
    if isequal(cfg,lastCfg), params=lastParams; return; end
    params.N = cfg.fftSize;
    params.cp_len = min(cfg.cpLengths); % Minimum CP, retained for metadata.
    params.cp_lengths = cfg.cpLengths;
    params.active_indices = cfg.activeIndices;
    params.active_subcarriers = cfg.activeSubcarriers;
    params.num_active = cfg.numActiveSubcarriers;
    params.dc_index = cfg.dcIndex;
    params.waveform_model = 'lte-normal-cp-numerology-v1';
    params.delta_f = cfg.subcarrierSpacing;

    params.Fs   = params.N * params.delta_f;
    params.Ts   = 1 / params.Fs;
    params.Tu   = 1 / params.delta_f;
    params.Tcp  = params.cp_lengths * params.Ts;
    params.Tsym = params.Tu + params.Tcp;

    switch upper(mod_type)
        case 'QPSK'
            params.M = 4;
            params.bits_per_symbol = 2;
            params.Qm = 2;
            params.mod_str = 'QPSK';
        case '16QAM'
            params.M = 16;
            params.bits_per_symbol = 4;
            params.Qm = 4;
            params.mod_str = '16QAM';
        case '64QAM'
            params.M = 64;
            params.bits_per_symbol = 6;
            params.Qm = 6;
            params.mod_str = '64QAM';
        otherwise
            error('Unsupported modulation type: %s. Use QPSK, 16QAM, or 64QAM.', mod_type);
    end

    params.tb_len = cfg.coding.tbLength;      % useful information bits
    params.crc_poly = cfg.coding.crcPoly;
    params.turbo_num_iter = coding.turbo_num_iter;
    params.coding_backend = coding.backend;
    params.coding_enabled = cfg.coding.enabled;
    params.equalizer_enabled = cfg.receiver.equalizerEnabled;
    params.code_rate_nominal = code_rate;
    params.rv = rv;

    params.enb=cfg.lte.enb;
    params.chs=cfg.lte.chs;
    params.chs.Modulation=params.mod_str;

    params.tb_crc_len=params.tb_len+24;
    if cfg.coding.enabled
        params.coded_len_full=3*(params.tb_crc_len+4);
        target_outlen=round(params.tb_crc_len/code_rate);
        minimum_outlen=0;
    else
        params.coded_len_full=params.tb_crc_len;
        target_outlen=params.tb_crc_len;
        minimum_outlen=params.tb_crc_len;
    end
    [params.prbset,params.pdsch_info,params.actual_code_rate_cb,params.actual_code_rate_tb]= ...
        resourceAllocation(params.enb,params.chs,params.tb_len,params.tb_crc_len,target_outlen,minimum_outlen);
    params.chs.PRBSet=params.prbset;
    params.rate_matched_len=double(params.pdsch_info.G(1));
    params.rate_matched_symbols_per_layer=double(params.pdsch_info.Gd);
    params.coding_padding_len=0;
    if ~cfg.coding.enabled,params.coding_padding_len=params.rate_matched_len-params.tb_crc_len;end
    params.mod_symbol_len=params.rate_matched_len/params.bits_per_symbol;
    assert(params.mod_symbol_len==fix(params.mod_symbol_len),'Invalid modulation length.');
    params.num_symbols=cfg.symbolsPerSubframe;
    params.pad_symbol_len=params.num_symbols*params.num_active-params.mod_symbol_len;
    if params.pad_symbol_len<0,error('project:GridCapacity','QAM sequence exceeds one subframe.');end
    params.num_samples=sum(params.N+params.cp_lengths);
    params.symbol_start_indices=[1;1+cumsum(params.N+params.cp_lengths(1:end-1))];
    params.duration=params.num_samples/params.Fs;
    lastCfg=cfg; lastParams=params;
end
