function plan = simulationPlan(cfg, scenario)
    if nargin<1||isempty(cfg),cfg=config();else,cfg=config(cfg);end
    if nargin<2||isempty(scenario),scenario='snr';end
    rows=struct('label',{},'cfg',{},'snrDb',{});
    switch lower(scenario)
      case {'snr','snrrun'}
        rows=modulationRows(cfg);
      case {'mcs','mcsrun'}
        rows=mcsRows(cfg);
      case {'delayspread','delayspreadrun'}
        rows=delayRows(cfg);
      case {'ber','berrun'}
        a=cfg;a.channel.type='awgn';b=cfg;b.channel.type='tdl';
        rows=[modulationRows(a) modulationRows(b)];
      case {'reportbler','rx_report_bler_graphs'}
        cfg.channel.type='tdl';cfg.channel.delaySpreadNs=cfg.experiment.reportDelaySpreadNs;
        q=cfg;q.modulation=cfg.experiment.mcs(1).modulation;q.coding.codeRate=cfg.experiment.mcs(1).codeRate;
        h=cfg;h.modulation=cfg.experiment.mcs(end).modulation;h.coding.codeRate=cfg.experiment.mcs(end).codeRate;
        rows=[mcsRows(cfg) delayRows(q) delayRows(h)];
      case {'reportmcs','rx_report_mcs_separate'}
        cfg.channel.type='tdl';cfg.experiment.snrDb=cfg.experiment.separateSnrDb;
        cfg.channel.delaySpreadNs=cfg.experiment.reportDelaySpreadNs;
        rows=mcsRows(cfg);
      case {'16qamdelay','plot_16qam_ber_vs_snr_ds'}
        cfg.modulation='16QAM';cfg.experiment.snrDb=cfg.experiment.snrTdlDb;
        cfg.experiment.delaySpreadsNs=cfg.experiment.legacy16qamDelaySpreadsNs;
        rows=delayRows(cfg);
      otherwise
        error('project:Scenario','Unknown scenario: %s',scenario);
    end
    points=sum(arrayfun(@(r)numel(r.snrDb),rows));
    blocks=points*cfg.experiment.packetsPerPoint;
    plan=struct('scenario',scenario,'cfg',cfg,'cases',rows,'points',points, ...
        'packetsPerPoint',cfg.experiment.packetsPerPoint,'transportBlocks',blocks, ...
        'bitsPerTransportBlock',cfg.coding.tbLength,'informationBits',blocks*cfg.coding.tbLength);
end

function rows=modulationRows(cfg)
    rows=struct('label',{},'cfg',{},'snrDb',{});
    if strcmp(cfg.channel.type,'awgn'),snr=cfg.experiment.snrAwgnDb;else,snr=cfg.experiment.snrTdlDb;end
    for k=1:numel(cfg.experiment.modulations)
        c=cfg;c.modulation=cfg.experiment.modulations{k};
        rows(k)=makeRow(c,c.modulation,snr);
    end
end
function rows=mcsRows(cfg)
    rows=struct('label',{},'cfg',{},'snrDb',{});
    for k=1:numel(cfg.experiment.mcs)
        m=cfg.experiment.mcs(k);c=cfg;c.modulation=m.modulation;c.coding.codeRate=m.codeRate;
        rows(k)=makeRow(c,m.label,cfg.experiment.snrDb);
    end
end
function rows=delayRows(cfg)
    rows=struct('label',{},'cfg',{},'snrDb',{});cfg.channel.type='tdl';
    for k=1:numel(cfg.experiment.delaySpreadsNs)
        c=cfg;c.channel.delaySpreadNs=cfg.experiment.delaySpreadsNs(k);
        rows(k)=makeRow(c,sprintf('%s, DS=%g ns',c.modulation,c.channel.delaySpreadNs),cfg.experiment.snrDb);
    end
end
function row=makeRow(cfg,label,snr)
    row=struct('label',[upper(cfg.channel.type) ', ' label],'cfg',cfg,'snrDb',snr(:).');
end
