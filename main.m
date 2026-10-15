function packet = main(cfg, seed)
    if nargin<1||isempty(cfg),cfg=config();else,cfg=config(cfg);end
    if nargin<2,seed=cfg.experiment.seed;end
    if ~isempty(seed)
        saved=rng;cleanup=onCleanup(@()rng(saved));
        rng(seed,'twister');
    end
    [txSignal,txInfo]=tx(cfg);
    [rxSignal,channelInfo]=channel(txSignal,cfg,txInfo.params);
    rxInfo=rx(rxSignal,txInfo,channelInfo);
    metrics=blockMetrics(txInfo.bits,rxInfo);
    packet=struct('cfg',cfg,'txSignal',txSignal,'txInfo',txInfo, ...
        'rxSignal',rxSignal,'channelInfo',channelInfo,'rxInfo',rxInfo,'metrics',metrics);
end
