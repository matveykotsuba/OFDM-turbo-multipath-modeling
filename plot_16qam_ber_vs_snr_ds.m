function results = plot_16qam_ber_vs_snr_ds(cfg)
    if nargin<1
        cfg=config();
    else
        cfg=config(cfg);
    end
    cfg.modulation='16QAM';
    cfg.experiment.delaySpreadsNs=cfg.experiment.legacy16qamDelaySpreadsNs;
    cfg.experiment.snrDb=cfg.experiment.snrTdlDb;
    results=delaySpreadRun(cfg);
    fig=berPlot(results,struct('title','16QAM: BER vs SNR for different delay spreads', ...
        'zeroDisplay','omit','yLimits',[1e-6 1]));
    [results.result_file,results.figures_dir]=saveResults(results,[],'16qam_delay_spread');
    savePlot(fig,results.figures_dir,'ber_16qam_delay_spread');
end
