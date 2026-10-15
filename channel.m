function [signal, info, stats, noisePower] = channel(txSignal, cfg, varargin)
    if isstruct(cfg)
        cfg=config(cfg);
        if isempty(varargin)
            p=frameParameters(cfg);
            grid=ofdmDemodulate(txSignal,p);symbols=reshape(grid.',[],1);
            p.mod_symbol_power=mean(abs(symbols(1:p.mod_symbol_len)).^2);
        else
            p=varargin{1};
        end
        [signal,h,stats,noisePower]=applyChannel(txSignal,cfg.channel.snrDb,cfg.channel.type,p,cfg.channel.profile,cfg.channel.delaySpreadNs);
        info=struct('type',cfg.channel.type,'h',h,'stats',stats,'noisePower',noisePower,'cfg',cfg.channel);
    else
        [signal,info,stats,noisePower]=applyChannel(txSignal,cfg,varargin{:});
    end
end
function [rx_signal, h, ch_stats, noise_power] = applyChannel(tx_signal, snr_db, channel_type, params, tdl_profile, delay_spread_ns)


    if nargin < 5 || isempty(tdl_profile)
        tdl_profile = 'TDL-A';
    end

    if nargin < 6 || isempty(delay_spread_ns)
        delay_spread_ns = 30;
    end


    tx_vector = reshape(tx_signal.', [], 1);


    tx_power = mean(abs(tx_vector).^2);

    switch upper(channel_type)

        case 'AWGN'
            h = 1;
            channel_output = tx_vector;

            ch_stats = struct();
            ch_stats.case_name = 'awgn';
            ch_stats.profile = 'awgn';
            ch_stats.delay_spread_ns = 0;
            ch_stats.delay_samples = 0;
            ch_stats.delay_sec = 0;
            ch_stats.powers_db = 0;
            ch_stats.tau_mean = 0;
            ch_stats.tau_rms = 0;
            ch_stats.max_delay = 0;
            ch_stats.tau_mean_target = 0;
            ch_stats.tau_rms_target = 0;
            ch_stats.max_delay_target = 0;
            ch_stats.channel_power = 1;
            ch_stats.freq_power_mean = 1;

        case {'TDL','MULTIPATH'}

            [tau_norm, powers_db] = tdl_38901_profile(tdl_profile);


            DS = delay_spread_ns * 1e-9;


            delays_sec_target = tau_norm(:) * DS;
            powers_lin_target = 10.^(powers_db(:) / 10);
            powers_lin_target = powers_lin_target / sum(powers_lin_target);


            delay_samples_raw = round(delays_sec_target * params.Fs);

            [delay_samples_unique, ~, group_idx] = unique(delay_samples_raw, 'stable');

            powers_lin_merged = zeros(length(delay_samples_unique), 1);

            for k = 1:length(delay_samples_unique)
                powers_lin_merged(k) = sum(powers_lin_target(group_idx == k));
            end

            powers_lin_merged = powers_lin_merged / sum(powers_lin_merged);
            powers_db_merged = 10 * log10(powers_lin_merged);
            delays_sec_merged = delay_samples_unique(:) / params.Fs;

            max_delay = max(delay_samples_unique);


            taps = (randn(length(delay_samples_unique),1) + 1j * randn(length(delay_samples_unique),1)) ...
                .* sqrt(powers_lin_merged / 2);

            h = zeros(max_delay + 1, 1);

            for k = 1:length(delay_samples_unique)
                h(delay_samples_unique(k) + 1) = taps(k);
            end

            channel_output = conv(tx_vector, h);
            channel_output = channel_output(1:length(tx_vector));

            [tau_mean_target, tau_rms_target] = delay_stats(delays_sec_target, powers_db);
            [tau_mean_impl, tau_rms_impl] = delay_stats(delays_sec_merged, powers_db_merged);

            H_tmp = fft(h, params.N);

            ch_stats = struct();
            ch_stats.case_name = 'tdl';
            ch_stats.profile = upper(tdl_profile);
            ch_stats.delay_spread_ns = delay_spread_ns;
            ch_stats.delay_samples = delay_samples_unique(:);
            ch_stats.delay_sec = delays_sec_merged(:);
            ch_stats.powers_db = powers_db_merged(:);
            ch_stats.tau_mean = tau_mean_impl;
            ch_stats.tau_rms = tau_rms_impl;
            ch_stats.max_delay = max(delays_sec_merged);
            ch_stats.tau_mean_target = tau_mean_target;
            ch_stats.tau_rms_target = tau_rms_target;
            ch_stats.max_delay_target = max(delays_sec_target);
            ch_stats.delay_samples_raw = delay_samples_raw(:);
            ch_stats.delay_sec_target = delays_sec_target(:);
            ch_stats.powers_db_target = powers_db(:);
            ch_stats.channel_power = sum(abs(h).^2);
            ch_stats.freq_power_mean = mean(abs(H_tmp).^2);

        otherwise
            error('Wrong channel type: %s. Use AWGN, TDL, or MULTIPATH.', channel_type);
    end


    if isfield(params, 'mod_symbol_power') && ~isempty(params.mod_symbol_power)
        snr_reference_power = params.mod_symbol_power;
    else
        snr_reference_power = tx_power;
    end

    snr_linear = 10^(snr_db / 10);
    noise_power = snr_reference_power / snr_linear;

    noise = sqrt(noise_power / 2) * ...
        (randn(size(channel_output)) + 1j * randn(size(channel_output)));

    rx_vector = channel_output + noise;

    rx_signal = reshape(rx_vector, size(tx_signal, 2), size(tx_signal, 1)).';

    ch_stats.tx_power = tx_power;
    ch_stats.snr_reference_power = snr_reference_power;
    ch_stats.snr_db = snr_db;
    ch_stats.snr_linear = snr_linear;
    ch_stats.noise_power = noise_power;
    min_cp=params.cp_len;
    if isfield(params,'cp_lengths'),min_cp=min(params.cp_lengths);end
    ch_stats.min_cp_samples=min_cp;
    ch_stats.max_delay_samples=length(h)-1;
    ch_stats.cp_sufficient=(length(h)-1)<=min_cp;
    ch_stats.excess_delay_samples=max(0,length(h)-1-min_cp);
    payload_cp=min_cp;
    if isfield(params,'cp_lengths') && isfield(params,'mod_symbol_len') && isfield(params,'num_active')
        occupied=ceil(params.mod_symbol_len/params.num_active);
        payload_cp=min(params.cp_lengths(1:occupied));
    end
    ch_stats.payload_min_cp_samples=payload_cp;
    ch_stats.payload_cp_sufficient=(length(h)-1)<=payload_cp;
    ch_stats.payload_excess_delay_samples=max(0,length(h)-1-payload_cp);
end


function [tau_mean, tau_rms] = delay_stats(delays_sec, powers_db)

    p = 10.^(powers_db(:) / 10);
    p = p / sum(p);

    tau = delays_sec(:);

    tau_mean = sum(tau .* p);
    tau2_mean = sum((tau.^2) .* p);

    tau_rms = sqrt(max(tau2_mean - tau_mean^2, 0));
end
