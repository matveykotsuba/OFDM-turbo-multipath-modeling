function results = berRun(delay_spread_ns, packets_per_point, coding_options)
    if nargin==1 && isstruct(delay_spread_ns)
        cfg=config(delay_spread_ns);
        coding_options=coding_config(struct('enabled',cfg.coding.enabled,'backend',cfg.coding.backend,'turbo_num_iter',cfg.coding.turboNumIter));
        packets_per_point=cfg.experiment.packetsPerPoint;
    else
        if nargin < 3, coding_options = []; end
        [cfg,coding_options] = legacyExperimentConfig(coding_options);
        if nargin >= 1 && ~isempty(delay_spread_ns), cfg.channel.delaySpreadNs = delay_spread_ns; end
        if nargin < 2 || isempty(packets_per_point), packets_per_point = cfg.experiment.packetsPerPoint; end
        cfg.experiment.packetsPerPoint = packets_per_point;
    end
    cfg = config(cfg);
    cfg.channel.type = 'awgn'; awgn = snrRun(cfg);
    cfg.channel.type = 'tdl'; tdl = snrRun(cfg);
    sa = legacyResultFields(awgn); sa.type = 'awgn'; sa.title = 'AWGN';
    st = legacyResultFields(tdl); st.type = 'tdl'; st.title = 'multipath';
    results = struct();
    results.cfg = cfg;
    results.coding = coding_options;
    results.sim = [sa st];
    results.mod_list = cfg.experiment.modulations;
    results.code_rate_target = cfg.coding.codeRate;
    results.rv = cfg.coding.rv;
    results.ofdm_params = awgn.params{1};
    results.tdl_profile = cfg.channel.profile;
    results.delay_spread_ns = cfg.channel.delaySpreadNs;
    results.packets_per_point = packets_per_point;
    names = {'snr_db_range','ber','bler','ber_plot','bler_plot','bits','errors', ...
        'crc_errors','packets_total','packets_failed'};
    for k = 1:numel(names)
        name = names{k};
        if strcmp(name,'ber_plot') || strcmp(name,'bler_plot')
            metric = name(1:end-5);
            results.([metric '_awgn_plot']) = sa.(name);
            results.([metric '_tdl_plot']) = st.(name);
        else
            results.([name '_awgn']) = sa.(name);
            results.([name '_tdl']) = st.(name);
        end
    end
    results.experiments = struct('awgn',awgn,'tdl',tdl);
    [results.result_file,results.figures_dir] = saveResults(results,[], 'ber');
    channels = {awgn,tdl};
    for c = 1:2
        r = channels{c};
        titleText = sprintf('%s, Rnom = %.4g',upper(r.cases(1).cfg.channel.type),cfg.coding.codeRate);
        if c == 2, titleText = sprintf('%s %s, DS = %g ns',titleText,cfg.channel.profile,cfg.channel.delaySpreadNs); end
        f = berPlot(r,struct('title',['BER, ' titleText],'yLimits',[1e-6 1],'zeroDisplay','omit'));
        savePlot(f,results.figures_dir,['ber_' r.cases(1).cfg.channel.type]);
        f = blerPlot(r,struct('title',['BLER, ' titleText],'yLimits',[1e-2 1],'zeroDisplay','omit'));
        savePlot(f,results.figures_dir,['bler_' r.cases(1).cfg.channel.type]);
    end
end
