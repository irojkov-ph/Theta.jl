"""
    siegel_transform(τ)

Compute Siegel transformation on input Riemann matrix.

# Arguments
- `τ::Array{<:Number}`: 2-dimensional array of complex numbers

# Examples
```julia
julia> siegel_transform([1+im -1; -1 1+im])
```
"""
function siegel_transform(τ::Array{<:Number})
    M = copy(τ);
    g = size(τ)[1];
    Γ = Matrix(I, 2*g, 2*g); # transformation
    A = [0 zeros(1, g-1); zeros(g-1, 1) Matrix(I, g-1, g-1)];
    B = [-1 zeros(1, g-1); zeros(g-1, 1) zeros(g-1, g-1)];
    C = [1 zeros(1, g-1); zeros(g-1, 1) zeros(g-1, g-1)];
    D = [0 zeros(1, g-1); zeros(g-1, 1) Matrix(I, g-1, g-1)];
    Q = [A B; C D];
    e = 0; # first entry of riemann matrix
    while e < 1
        # transform T such that the shortest vector of T is at the first column
        Y = 0.5*(imag(M) + transpose(imag(M)));
        T = (size(Y)[1] > 1 ? convert(Array{Float64, 2}, cholesky(Symmetric(Y)).U) : sqrt.(Y));
        U = hkz_transform!(T);
        M = transpose(U)*real(M)*U + im*transpose(T)*T;
        Γ = [transpose(U) zeros(g, g); zeros(g, g) inv(U)]*Γ;
        # set the real part of τ to have entries of absolute value at most 1/2
        b = -round.(real(M));
        M += b;
        Γ = [Matrix(I, g, g) b; zeros(g, g) Matrix(I, g, g)]*Γ; 
        e = abs(M[1]);
        if e < 1
            M = (A*M + B)*inv(C*M + D); # Y is no longer symmetric after this operation
            Γ = Q*Γ;
        end
    end
    b = -round.(real(M));
    M += b;
    Γ = [Matrix(I, g, g) b; zeros(g, g) Matrix(I, g, g)]*Γ;
    return [Γ, M];
end

"""
    symplectic_transform(Γ, τ)

Compute symplectic group action of Γ on τ.

# Arguments
- `Γ::Array{<:Number}`: 2-dimensional array of numbers
- `τ::Array{<:Number}`: 2-dimensional array of complex numbers

# Examples
```julia
julia> τ = [1+im -1; -1 1+im];
julia> Γ = siegel_transform(τ)[1];
julia> symplectic_transform(Γ, τ)
```
"""
function symplectic_transform(Γ::Array{<:Number}, τ::Array{<:Number})
    g = size(τ)[1];
    return (Γ[1:g, 1:g]*τ + Γ[1:g, g+1:2*g])*inv(Γ[g+1:2*g, 1:g]*τ + Γ[g+1:2*g, g+1:2*g]);
end

"""
    hkz_transform!(M)

Compute a unimodular matrix Z such that the first column of M*Z is the shortest vector of the lattice generated by M, where M is an upper triangular matrix. Transform the input matrix accordingly.
"""
function hkz_transform!(M::Array{<:Real})
    n = size(M)[1];
    z = svp(M)[3]; # M*z is shortest vector of M
    Z = Matrix{Float64}(I, n, n); # Z is the transform, iteratively computed such that inv(Z)*z = [1; 0; ...; 0], or first column of Z is z
    z2 = z[n];
    for j = n:-1:2 
        # each iteration computes a 2x2 transform U such that inv(U) transforms [z[j-1]; z[j]] into a unit vector
        z1 = z[j-1];
        d, a, b = gcdx(z1, z2); # gcd of z[j-1], z[j]
        if d != 0
            U = [z1/d -b; z2/d a]; #  inv(U)*[z1; z2] = [d; 0]
        else
            U = Matrix(I, 2, 2);
        end
        z2 = d;
        Z[:, j-1:j] = Z[:, j-1:j]*U;
        M[:, j-1:j] = M[:, j-1:j]*U;
        # compute Givens rotation so that M remains upper triangular
        G = givens_rotation(M[j-1,j-1], M[j,j-1]);
        M[j-1:j, j-1:n] = G*M[j-1:j, j-1:n];
    end
    return Z;
end

"""
    givens_rotation(x, y)

Compute a Givens rotation, which is a 2x2 rotation matrix G such that G[x; y] has second entry zero.
"""
function givens_rotation(x::Real, y::Real)
    if abs(y) >= abs(x) # split into cases to reduce numerical error
        t = x/y;
        s = -1/sqrt(1+t^2);
        c = -t*s;
    else
        t = y/x;
        c = 1/sqrt(1+t^2);
        s = -t*c;
    end
    G = [c -s; s c]; 
    return G;
end