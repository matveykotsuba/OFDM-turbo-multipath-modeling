function check_project_consistency

    mod_list = {'QPSK', '16QAM', '64QAM'};
    code_rate = 1/2;
    rv = 0;

    fprintf('Checking project consistency...\n');

    for m = 1:length(mod_list)
        mod_type = mod_list{m};
        [tx_signal, info_bits, params] = tx(mod_type, code_rate, rv);

        assert(length(info_bits) == params.tb_len);
        assert(params.rv == rv);
        assert(params.rate_matched_len == params.mod_symbol_len * params.bits_per_symbol);
        assert(iscolumn(tx_signal)&&numel(tx_signal)==params.num_samples);
        assert(params.num_symbols==14&&params.num_samples/params.Fs==1e-3);
        assert(params.pad_symbol_len >= 0);

        [~, h_awgn, ch_awgn, noise_awgn] = channel(tx_signal, 10, 'awgn', params);
        assert(isequal(h_awgn, 1));
        assert(noise_awgn > 0);
        assert(strcmpi(ch_awgn.profile, 'awgn'));

        [~, h_tdl, ch_tdl, noise_tdl] = channel(tx_signal, 10, 'tdl', params, 'TDL-A', 380);
        assert(~isempty(h_tdl));
        assert(noise_tdl > 0);
        assert(strcmpi(ch_tdl.profile, 'TDL-A'));

        fprintf('  %s: OK, G = %d, symbols = %d, OFDM symbols = %d\n', ...
            mod_type, params.rate_matched_len, params.mod_symbol_len, params.num_symbols);
    end

    fprintf('All consistency checks passed.\n');
end
