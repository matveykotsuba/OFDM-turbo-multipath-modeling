function [best_prbset, best_info, rate_cb, rate_tb] = resourceAllocation(enb, chs, tb_len, tb_crc_len, target_outlen, minimum_outlen)
    if nargin<6,minimum_outlen=0;end
    persistent lastKey lastValue;
    key = {enb,chs,tb_len,tb_crc_len,target_outlen,minimum_outlen};
    if isequal(key,lastKey)
        best_prbset=lastValue{1}; best_info=lastValue{2};
        rate_cb=lastValue{3}; rate_tb=lastValue{4}; return;
    end
    best_err = inf;
    best_prbset = [];
    best_info = [];

    for nPRB = 1:enb.NDLRB
        prbset = (0:nPRB-1).';
        [~, info] = ltePDSCHIndices(enb, chs, prbset);
        G = double(info.G(1));
        if G<minimum_outlen,continue;end
        err = abs(G - target_outlen);

        if err < best_err
            best_err = err;
            best_prbset = prbset;
            best_info = info;
        end
    end

    if isempty(best_prbset)
        error('Could not choose a valid PRB allocation.');
    end

    Gbest = double(best_info.G(1));
    rate_cb = tb_crc_len / Gbest;
    rate_tb = tb_len / Gbest;
    lastKey=key; lastValue={best_prbset,best_info,rate_cb,rate_tb};
end
