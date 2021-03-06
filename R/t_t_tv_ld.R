t_t_tv_ld = "

data{
int<lower = 1> ntot;        // total number observations
int id[ntot];               // id matrix, takes values like 1, 2, 3, ...
vector[ntot] y;             // response matrix
int<lower = 1> p;           // number of covariates in the fixed effects design matrix
int<lower = 1> q;           // number of covariates in the random effects design matrix
int<lower = 1> ngroup;      // number of subjects/clusters/groups
matrix[ntot, p] x;          // fixed effects design matrix
matrix[ntot, q * ngroup] d; // random effects design matrix, block diagonal
int<lower = 1> ncol_a;           // number of columns of a matrix
matrix[ntot, ncol_a] a;          // spline matrix
vector[5] priors;           // prior hyperparameters, order: theta, omega, sigma_bstar, sigmaZ, beta
}

transformed data{
//QR decomposition
matrix[ntot, p] Q_star;
matrix[p, p] R_star;
matrix[p, p] R_star_inv;
vector[q] zero_Bstar = rep_vector(0, q);

Q_star = qr_Q(x)[, 1:p] * sqrt(ntot - 1.0);
R_star = qr_R(x)[1:p, ] / sqrt(ntot - 1.0);
R_star_inv = inverse(R_star);
}

parameters{
vector[p] theta;              // fixed effects coefficients
matrix[ngroup, q] Bstar;
corr_matrix[q] Omega;
vector<lower = 0>[q] sigma_Bstar;
vector<lower = 0>[ngroup] V;
real<lower = 0.01, upper = 0.5> phi_inv;
real<lower = 0> sigma_Zstar;      // scale parameter of measurement error
vector<lower = 0>[ntot] W;
vector[ncol_a] beta;
real<lower = 0.01, upper = 0.5> delta0_inv;
}

transformed parameters{
cov_matrix[q] Sigma;
vector[ntot] linpred;
matrix[ngroup, q] B;
matrix[ngroup * q, 1] B_mat;
vector<lower = 0>[ntot] delta;
real<lower = 2, upper = 100> phi;
real<lower = 2, upper = 100> delta0;

phi = 1/phi_inv;
delta0 = 1/delta0_inv;

//delta = to_vector(2 + exp(delta0 + a * beta));
delta = to_vector(delta0 * exp(a * beta));

for(i in 1:ngroup){
B[i, ] = Bstar[i, ] * sqrt(V[i]);
}

B_mat = to_matrix(B', ngroup * q, 1);

linpred = Q_star * theta + to_vector(d * B_mat);

Sigma = quad_form_diag(Omega, sigma_Bstar);

}

model{

theta ~ cauchy(0, priors[1]);

for(i in 1:ngroup){
Bstar[i] ~ multi_normal(zero_Bstar, Sigma);
}

Omega ~ lkj_corr(priors[2]);
sigma_Bstar ~ cauchy(0, priors[3]);
sigma_Zstar ~ cauchy(0, priors[4]);

V ~ inv_gamma(phi/2, phi/2);
//phi_inv ~ uniform(0.01, 0.5);//uniform -infty, infty, constrained above

for(i in 1:ntot){
W[i] ~ inv_gamma(delta[i]/2, delta[i]/2);
}

beta ~ cauchy(0, priors[5]);
//delta0_inv ~ uniform(0.01, 0.5); //delta0 ~ cauchy(0, priors[5]);

for(i in 1:ntot)
y[i] ~ normal(linpred[i], sigma_Zstar * sqrt(W[i]));

}

generated quantities{
vector[p] alpha;
real sigmasq;

alpha = R_star_inv * theta;
sigmasq = sigma_Zstar^2;
}

"
