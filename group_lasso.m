randn('state',23432);
rand('state',3454);

%% MAIN PROGRAM %%
d = datasets;
rf = reg_funcs;

lambda = 5;
l1 = 0;
l2 = 0.1;

% Get Data
[ I, R, totalassets, T ] = d.ftse100();
% [ I, R, totalassets, T ] = d.naive(200,1000);


%% MAIN CVX PROGRAM %%


% Calculating n groups with knn + kmeans
n = 5;
[index, groups] = knn(R, n);
combs = [];
size_combs = [];

logical_index = logical(zeros(n,totalassets));
for i=1:5
    logical_index(i,:) = logical(index==i)';
end

comb_idx = [];
group_idx = [];

% Creating indexes for combinations
for i = 1:n
    comb = combnk(1:n, i);    
    
    comb_rn = size(comb,1);
    comb_cn = size(comb,2);
    
    combs = [combs; [comb , zeros(comb_rn,n-comb_cn) ]];
    size_combs = [size_combs; ones(comb_rn,1)*i];
    
    for j=1:comb_rn
        tmp_comb_idx = logical(zeros(1,n));
        tmp_comb_idx(comb(j,:)) = true;
        
        tmp_group_idx = sum(logical_index(comb(j,:),:),1);
        
        comb_idx = [ comb_idx; tmp_comb_idx ];
        group_idx = [ group_idx; tmp_group_idx ];
    end
end


group_idx = logical(group_idx);
group_idx = group_idx(1:n,:);
n=2;
group_idx = group_idx(1:2,:);
group_idx(2,:) = ~group_idx(1,:);

not_group_idx = ~group_idx;
group_sizes = sum(group_idx,2);
sqr_group_sizes = sqrt(group_sizes);


% CVX to find optimal value for Lasso
cvx_begin %quiet
    variable pimat_gl(totalassets,n)
    
%     minimize(square_pos(norm(I - sum(R'*pimat_gl,2))) + lambda*sum(sqr_group_sizes'*diag(norms(pimat_gl,2,1))) )
    minimize(square_pos(norm(I - sum(R'*pimat_gl,2))) + lambda*norm(pimat_gl) )
    
    subject to
%         sum(pimat_gl(:)) == 1
        pimat_gl >= 0
        pimat_gl(not_group_idx') == 0
cvx_end

pimat_norm_gl=pimat_gl/sum(pimat_gl(:));
% sum(pimat_gl,2)
% sum(pimat_gl,1)
% sum(abs(I-sum(R'*pimat_gl,2)))
% sum(sum(pimat_gl,2)<0.0001)



%% Sparse Group Lasso

% alpha = .3;

% CVX to find optimal value for Lasso
cvx_begin %quiet
    variable pimat_sgl(totalassets,n)
    
    minimize(square_pos(norm(I - sum(R'*pimat_sgl,2))) + l1*sum(sqr_group_sizes'*diag(norms(pimat_sgl,2,1))) + l2*norm(pimat_sgl,1) )
%     minimize(square_pos(norm(I - sum(R'*pimat_sgl,2))) + l1*norm(pimat_sgl) + l2*norm(pimat_sgl,1) )
    
    subject to
%         sum(pimat_sgl(:)) == 1
        pimat_sgl >= 0
        pimat_sgl(not_group_idx') == 0
cvx_end


% % CVX to find optimal value for Lasso
% cvx_begin %quiet
%     variable pimat_sgl(totalassets,n)
%     
%     minimize(square_pos(norm(I - sum(R'*pimat_sgl,2))) + l1*sum(sqr_group_sizes'*diag(norms(pimat_sgl,2,1))) + l2*norm(pimat_sgl,1) )
%     
%     subject to
% %         sum(pimat_sgl(:)) == 1
%         pimat_sgl >= 0
%         pimat_sgl(not_group_idx') == 0
% cvx_end


pimat_norm_sgl=pimat_sgl/sum(pimat_sgl(:));
% sum(pimat_sgl,2)
% sum(pimat_sgl,1)
% sum(abs(I-sum(R'*pimat_sgl,2)))
% sum(sum(pimat_sgl,2)<0.0001)


pimat_norm_gl = full(pimat_norm_gl);
pimat_norm_sgl = full(pimat_norm_sgl);

p = [ full(sum(pimat_norm_gl,2)) full(sum(pimat_norm_sgl,2)) ]
t = [ sum(pimat_norm_gl,1) sum(pimat_norm_sgl,1) ]
e = [ sum(abs(I-sum(R'*pimat_norm_gl,2))) sum(abs(I-sum(R'*pimat_norm_sgl,2))) ]
z = [ sum(sum(pimat_norm_gl,2)<0.0001) sum(sum(pimat_norm_sgl,2)<0.0001) ]



