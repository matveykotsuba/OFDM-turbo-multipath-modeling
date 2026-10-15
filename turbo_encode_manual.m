function [coded, detail] = turbo_encode_manual(bits)
    if ~(isnumeric(bits) || islogical(bits)) || ~isreal(bits) || ...
            ~isvector(bits) || isempty(bits) || any(bits(:)~=0 & bits(:)~=1)
        error('manualLTE:Bits', 'Input must be a nonempty binary vector.');
    end
    u = logical(bits(:));
    K = numel(u);
    p = qpp_indices_manual(K);
    [z1,x1t,z1t,trace1] = constituent_encode(u,nargout>1);
    [z2,x2t,z2t,trace2] = constituent_encode(u(p),nargout>1);

    d0 = [u;  x1t(1); z1t(2); x2t(1); z2t(2)];
    d1 = [z1; z1t(1); x1t(3); z2t(1); x2t(3)];
    d2 = [z2; x1t(2); z1t(3); x2t(2); z2t(3)];
    coded = int8([d0;d1;d2]);
    if nargout > 1
        detail = struct('K',K,'qpp_indices',p,'systematic',u, ...
            'parity1',z1,'parity2',z2,'streams',int8([d0 d1 d2]), ...
            'tail_input1',x1t,'tail_parity1',z1t, ...
            'tail_input2',x2t,'tail_parity2',z2t, ...
            'state_trace1',trace1,'state_trace2',trace2);
    end
end

function [parity, tail_input, tail_parity, trace] = constituent_encode(u,trace_enabled)
    s1=false; s2=false; s3=false;
    parity=false(numel(u),1);
    trace=[];
    if trace_enabled,trace=false(numel(u)+3,9);end
    for k=1:numel(u)
        v=xor(u(k),xor(s2,s3));
        parity(k)=xor(v,xor(s1,s3));
        if trace_enabled,trace(k,:)=[u(k) s1 s2 s3 v parity(k) v s1 s2];end
        s3=s2; s2=s1; s1=v;
    end
    tail_input=false(3,1); tail_parity=false(3,1);
    for k=1:3
        tail_input(k)=xor(s2,s3);
        v=false;
        tail_parity(k)=xor(v,xor(s1,s3));
        if trace_enabled,trace(numel(u)+k,:)=[tail_input(k) s1 s2 s3 v tail_parity(k) v s1 s2];end
        s3=s2; s2=s1; s1=v;
    end
end
