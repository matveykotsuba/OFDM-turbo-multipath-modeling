function results = delaySpreadRun(cfg)
    if nargin < 1, cfg = []; end
    cfg = config(cfg);
    cfg.channel.type = 'tdl';
    delays = cfg.experiment.delaySpreadsNs;
    cases = repmat(struct('label','','cfg',cfg),1,numel(delays));
    for k = 1:numel(delays)
        cases(k).label = sprintf('DS = %g ns',delays(k));
        cases(k).cfg.channel.delaySpreadNs = delays(k);
    end
    results = experimentRun(cfg,cases,cfg.experiment.snrDb);
    results.kind = 'delaySpread';
end
