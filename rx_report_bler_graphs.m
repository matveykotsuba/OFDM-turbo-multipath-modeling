function results = rx_report_bler_graphs(packets_per_point, coding_options)
    if nargin==1 && isstruct(packets_per_point)
        cfg=config(packets_per_point);
        coding_options=coding_config(struct('enabled',cfg.coding.enabled,'backend',cfg.coding.backend,'turbo_num_iter',cfg.coding.turboNumIter));
        packets_per_point=cfg.experiment.packetsPerPoint;
    else
        if nargin < 2, coding_options = []; end
        [cfg,coding_options] = legacyExperimentConfig(coding_options);
        if nargin < 1 || isempty(packets_per_point), packets_per_point = cfg.experiment.packetsPerPoint; end
        cfg.experiment.packetsPerPoint = packets_per_point;
    end
    cfg.channel.type = 'tdl';
    cfg.channel.delaySpreadNs = cfg.experiment.reportDelaySpreadNs;
    cfg = config(cfg);
    mcs = mcsRun(cfg);
    qcfg = cfg;
    qcfg.modulation = cfg.experiment.mcs(1).modulation;
    qcfg.coding.codeRate = cfg.experiment.mcs(1).codeRate;
    qpsk = delaySpreadRun(qcfg);
    hcfg = cfg;
    hcfg.modulation = cfg.experiment.mcs(end).modulation;
    hcfg.coding.codeRate = cfg.experiment.mcs(end).codeRate;
    qam64 = delaySpreadRun(hcfg);
    results = struct();
    results.cfg = cfg;
    results.coding = coding_options;
    results.tdl_profile = cfg.channel.profile;
    results.rv = cfg.coding.rv;
    results.ofdm_params = mcs.params{1};
    results.snr_db_range = cfg.experiment.snrDb;
    results.packets_per_point = packets_per_point;
    results.bler_ymin = 1e-2;
    results.bler_ymax = 1;
    results.fixed_delay_spread_ns = cfg.channel.delaySpreadNs;
    results.delay_spread_list_ns = cfg.experiment.delaySpreadsNs;
    mcs_list = repmat(struct('mod_type','','code_rate',0,'label',''),1,numel(cfg.experiment.mcs));
    for k = 1:numel(mcs_list)
        item = cfg.experiment.mcs(k);
        mcs_list(k) = struct('mod_type',item.modulation,'code_rate',item.codeRate,'label',item.label);
    end
    results.mcs_list = mcs_list;
    results.bler_mcs = mcs.BLER;
    results.crc_errors_mcs = mcs.crcErrors;
    results.packets_total_mcs = mcs.totalPackets;
    results.qpsk_cfg = mcs_list(1);
    results.bler_qpsk_ds = qpsk.BLER;
    results.crc_errors_qpsk_ds = qpsk.crcErrors;
    results.packets_total_qpsk_ds = qpsk.totalPackets;
    results.qam64_cfg = mcs_list(end);
    results.bler_64qam_ds = qam64.BLER;
    results.crc_errors_64qam_ds = qam64.crcErrors;
    results.packets_total_64qam_ds = qam64.totalPackets;
    results.experiments = struct('mcs',mcs,'qpskDelaySpread',qpsk,'qam64DelaySpread',qam64);
    [results.result_file,results.figures_dir] = saveResults(results,[], 'report_bler');
    opt = struct('yLimits',[results.bler_ymin results.bler_ymax],'hideBelowLimit',true);
    opt.title = sprintf('BLER, %s, DS = %g ns',cfg.channel.profile,cfg.channel.delaySpreadNs);
    f = blerPlot(mcs,opt); savePlot(f,results.figures_dir,'bler_mcs_ds300');
    opt.title = ['BLER, ' strrep(mcs_list(1).label,'R =','Rnom =') ', different delay spread'];
    f = blerPlot(qpsk,opt); savePlot(f,results.figures_dir,'bler_qpsk_r12_different_ds');
    opt.title = ['BLER, ' strrep(mcs_list(end).label,'R =','Rnom =') ', different delay spread'];
    f = blerPlot(qam64,opt); savePlot(f,results.figures_dir,'bler_64qam_r34_different_ds');
    if cfg.experiment.verbose, fprintf('Results: %s\n',results.figures_dir); end
end
