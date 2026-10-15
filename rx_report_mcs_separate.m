function results = rx_report_mcs_separate(delay_spread_ns, packets_per_point, coding_options)
    if nargin==1 && isstruct(delay_spread_ns)
        cfg=config(delay_spread_ns);
        coding_options=coding_config(struct('enabled',cfg.coding.enabled,'backend',cfg.coding.backend,'turbo_num_iter',cfg.coding.turboNumIter));
        packets_per_point=cfg.experiment.packetsPerPoint;
        delay_spread_ns=cfg.experiment.reportDelaySpreadNs;
    else
        if nargin < 3, coding_options = []; end
        [cfg,coding_options] = legacyExperimentConfig(coding_options);
        if nargin < 1 || isempty(delay_spread_ns), delay_spread_ns = cfg.experiment.reportDelaySpreadNs; end
        if nargin < 2 || isempty(packets_per_point), packets_per_point = cfg.experiment.packetsPerPoint; end
    end
    cfg.channel.type = 'tdl';
    cfg.channel.delaySpreadNs = delay_spread_ns;
    cfg.experiment.packetsPerPoint = packets_per_point;
    cfg.experiment.snrDb = cfg.experiment.separateSnrDb;
    cfg = config(cfg);
    modern = mcsRun(cfg);
    old = legacyResultFields(modern);
    cfg_list = repmat(struct('mod_type','','code_rate',0,'title','','file_tag',''),1,numel(cfg.experiment.mcs));
    for k = 1:numel(cfg_list)
        item = cfg.experiment.mcs(k);
        cfg_list(k) = struct('mod_type',item.modulation,'code_rate',item.codeRate, ...
            'title',item.label,'file_tag',item.fileTag);
    end
    results = struct();
    results.cfg = cfg;
    results.coding = coding_options;
    results.cfg_list = cfg_list;
    results.snr_db_range = modern.snrDb;
    results.rv = cfg.coding.rv;
    results.ofdm_params = modern.params{1};
    results.tdl_profile = cfg.channel.profile;
    results.delay_spread_ns = delay_spread_ns;
    results.packets_per_point = packets_per_point;
    fields = {'ber','bler','errors','bits','crc_errors','packets_total','packets_failed'};
    for k = 1:numel(fields), results.([fields{k} '_tdl']) = old.(fields{k}); end
    results.ber_ymin = 1e-5;
    results.bler_ymin = 1e-2;
    results.experiment = modern;
    [results.result_file,results.figures_dir] = saveResults(results,[], 'report_mcs');
    for k = 1:numel(cfg_list)
        titleText = sprintf('%s, DS = %g ns, %s',cfg.channel.profile,delay_spread_ns,strrep(cfg_list(k).title,'R =','Rnom ='));
        opt = struct('rows',k,'title',['BER, ' titleText], ...
            'yLimits',[results.ber_ymin 1],'hideBelowLimit',true);
        f = berPlot(modern,opt); savePlot(f,results.figures_dir,['ber_' cfg_list(k).file_tag]);
        opt.title = ['BLER, ' titleText]; opt.yLimits = [results.bler_ymin 1];
        f = blerPlot(modern,opt); savePlot(f,results.figures_dir,['bler_' cfg_list(k).file_tag]);
    end
    if cfg.experiment.verbose, fprintf('Results: %s\n',results.figures_dir); end
end
